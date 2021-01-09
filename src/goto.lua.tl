##ntangle_main
@functions+=
local function goto(lnum)
	@get_current_cursor_position
	@search_top_for_assembly_name
	if assembly_name then
	else
		@clear_sections
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		@read_file_line_by_line_from_variable
		@trace_back_to_section_name
		@resolve_root_section
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

@resolve_root_section+=
local open = { containing }
local explored = {}
local roots = {}
while #open > 0 do
	local name = open[#open]
	table.remove(open)
	explored[name] = true

	@if_root_add_to_roots

	if refs[name] then
		local parents = refs[name]
		@remove_any_parent_which_was_already_explored
		@add_remaining_to_open
	end
end

assert(vim.tbl_count(roots) == 1, "multiple roots or none")

local name = vim.tbl_keys(roots)[1]

@remove_any_parent_which_was_already_explored+=
local i = 1
while i <= #parents do
	if explored[parent] then
		table.remove(parents, i)
	else
		i = i + 1
	end
end

@add_remaining_to_open+=
for _, parent in ipairs(parents) do
	table.insert(open, parent)
end

@if_root_add_to_roots+=
if sections[name].root then
	roots[name] = true
end

@trace_back_to_section_name+=
local _, row, _, _ = unpack(vim.fn.getpos("."))
local containing
while row >= 1 do
	local line = lines[row]
	@if_line_is_section_save_it_and_quit
	row = row - 1
end

assert(containing, "no containing section!")

@if_line_is_section_save_it_and_quit+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	containing = name
end
