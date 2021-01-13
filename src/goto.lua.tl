##ntangle_main
@functions+=
local function goto(lnum)
	local lines = {}
	local curassembly
	@read_lines_from_buffer
	@read_assembly_name_if_any
	local filename = nil
	if curassembly then
		@construct_path_for_link_file
		local assembled = {}
		@glob_all_links_and_assemble_except_current
		@append_current_buffer_to_the_assembled

		local rootlines = lines
		local lines = assembled
		@clear_sections
		@read_file_line_by_line_from_variable

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
outputSectionsFull(fn, tangled, name)

@declare_functions+=
local outputSectionsFull

@functions+=
function outputSectionsFull(fn, lines, name, prefix)
	prefix = prefix or ""
	@check_if_section_exists_otherwise_return_with_cur
	@if_section_is_root_generate_fake_header
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

@if_section_is_root_generate_fake_header+=
if sections[name].root then
	@output_generated_header_fake
end

@if_line_is_text_store_line+=
if line.linetype == LineType.TEXT then
	table.insert(lines, { prefix, line })
end

@if_reference_recursively_call_output_sections_full+=
if line.linetype == LineType.REFERENCE then
	outputSectionsFull(fn, lines, line.str, line.prefix .. prefix)
end

@go_to_line+=
assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")

local _, l = unpack(tangled[lnum])
vim.fn.setpos(".", {0, l.lnum, 0, 0})

@resolve_root_section_at_cursor+=
local _, row, _, _ = unpack(vim.fn.getpos("."))
local containing = get_section(rootlines, row)
local name = resolve_root_section(containing)

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

local _, l = unpack(tangled[lnum])
local lorigin = origin[l.lnum]
assert(lorigin, "nil origin")

local relpos = l.lnum - offset[lorigin]

if lorigin == fn then
	@go_to_line_assembly_in_current_buffer
else
	@go_to_line_assembly_outside_buffer
end

@go_to_line_assembly_in_current_buffer+=
vim.fn.setpos(".", {0, relpos+1, 0, 0})

@go_to_line_assembly_outside_buffer+=
vim.api.nvim_command("e " .. lorigin)
vim.fn.setpos(".", {0, relpos+1, 0, 0})
