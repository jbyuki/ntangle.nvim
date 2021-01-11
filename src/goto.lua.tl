##ntangle_main
@functions+=
local function goto(lnum)
	@read_lines_from_buffer
	@search_top_for_assembly_name
	if assembly_name then
		local assemblies = {}
		@read_line_by_line_and_separate_assemblies
		local name = assembly_name
		filename = nil
		@get_current_buffer_name_for_assembly_part
		@glob_all_parts
		local bufferlines = lines
		@assemble_lines_into_single_table_except_current_from_memory
		@add_lines_in_buffer_into_assembly
		@clear_sections
		@read_file_line_by_line_from_variable

		local rootlines = bufferlines
		@resolve_root_section_at_cursor
		@output_for_root_section
		@go_to_line_assembly
	else
		@clear_sections
		@read_file_line_by_line_from_variable
		local rootlines = lines
		@resolve_root_section_at_cursor
		@output_for_root_section
		@go_to_line
	end
end

@export_symbols+=
goto = goto,

@output_for_root_section+=
local tangled = {}
outputSectionsFull(tangled, name)

@declare_functions+=
local outputSectionsFull

@functions+=
function outputSectionsFull(lines, name)
	@check_if_section_exists_otherwise_return_with_cur
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			@if_line_is_text_store_line
			@if_reference_recursively_call_output_sections_full
		end
	end
	return cur, nil
end

@check_if_section_exists_otherwise_return_with_cur+=
if not sections[name] then
	return
end

@if_line_is_text_store_line+=
if line.linetype == LineType.TEXT then
	table.insert(lines, line)
end

@if_reference_recursively_call_output_sections_full+=
if line.linetype == LineType.REFERENCE then
	outputSectionsFull(lines, line.str)
end

@go_to_line+=
assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")

local l = tangled[lnum]
vim.fn.setpos(".", {0, l.lnum, 0, 0})

@resolve_root_section_at_cursor+=
local _, row, _, _ = unpack(vim.fn.getpos("."))
local containing = get_section(rootlines, row)
local name = resolve_root_section(containing)

@search_top_for_assembly_name+=
local _, row, _, _ = unpack(vim.fn.getpos("."))
local assembly_name
while row >= 1 do
	local line = lines[row]
	@if_line_is_assembly_name_save_and_quit
	row = row - 1
end

if not assembly_name then
	local lnum = row
	while lnum <= #lines do
		local line = lines[lnum]
		@if_line_is_assembly_name_save_and_quit
		lnum = lnum + 1
	end
end

@if_line_is_assembly_name_save_and_quit+=
if string.match(line, "^##%S*%s*$") then
	@extract_assembly_name
	assembly_name = name
	break
end

@assemble_lines_into_single_table_except_current_from_memory+=
local lines = {}
local origin = {}
for _, part in ipairs(parts) do
	@read_single_assembly_part_and_skip_current_in_buffer
end

@read_single_assembly_part_and_skip_current_in_buffer+=
local first = true
local part_origin
for line in io.lines(part) do
	if first then
		if line == filename then
			break
		end
		@if_origin_file_does_not_exist_quit_early
		@add_offset_to_lines
		@set_as_current_part_origin
		first = false
	else
		table.insert(lines, line)
		table.insert(origin, part_origin)
	end
end

@if_origin_file_does_not_exist_quit_early+=
local f = io.open(line, "r")
if not f then
	break
end
f:close()

@set_as_current_part_origin+=
part_origin = line

@assemble_lines_into_single_table_except_current_from_memory-=
local offset = {}

@add_offset_to_lines+=
offset[line] = #lines


@add_lines_in_buffer_into_assembly+=
offset[filename] = #lines
for _, line in ipairs(assemblies[name]) do
	table.insert(lines, line)
	table.insert(origin, filename)
end

@go_to_line_assembly+=
assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")

local l = tangled[lnum]
local lorigin = origin[l.lnum]
assert(lorigin, "nil origin")

local l = tangled[lnum]
local relpos = l.lnum - offset[lorigin]

if lorigin == filename then
	@search_for_line_with_assembled
	@go_to_line_assembly_in_current_buffer
else
	@search_for_line_with_assembled_by_opening_file
	@go_to_line_assembly_outside_buffer
end

@search_for_line_with_assembled+=
local jumpline
local curassembly
local curassemblyindex = 0
for lnum, line in ipairs(rootlines) do
	if string.match(line, "^##%S*%s*$") then
		@extract_assembly_name
		@set_as_current_assembly
	else
		@advance_assembly_offset_if_in_correct_assembly
		@if_offset_has_reached_relative_pos_quit_and_save_lnum
	end
end

@advance_assembly_offset_if_in_correct_assembly+=
if curassembly == assembly_name then
	curassemblyindex = curassemblyindex + 1
end

@if_offset_has_reached_relative_pos_quit_and_save_lnum+=
if curassemblyindex == relpos then
	jumpline = lnum
	break
end

@search_for_line_with_assembled_by_opening_file+=
local jumpline
local curassembly
local curassemblyindex = 0
local lnum = 1
for line in io.lines(lorigin) do
	if string.match(line, "^##%S*%s*$") then
		@extract_assembly_name
		@set_as_current_assembly
	else
		@advance_assembly_offset_if_in_correct_assembly
		@if_offset_has_reached_relative_pos_quit_and_save_lnum
	end
	lnum = lnum + 1
end

@go_to_line_assembly_in_current_buffer+=
vim.fn.setpos(".", {0, jumpline, 0, 0})

@go_to_line_assembly_outside_buffer+=
vim.api.nvim_command("e " .. lorigin)
vim.fn.setpos(".", {0, jumpline, 0, 0})
