##ntangle_main
@functions+=
local function go_definition()
	local tosearch
	@get_current_line
	@if_line_is_section_put_as_search
	@if_line_is_reference_put_as_search
	assert(tosearch, "no reference or section under cursor!")

	local lines = {}
	local curassembly
	@read_lines_from_buffer
	@read_assembly_name_if_any
	local filename = nil
	local definitions = {}
	if curassembly then
		@construct_path_for_link_file
		local assembled = {}
		@glob_all_links_and_assemble_except_current
		@append_current_buffer_to_the_assembled

		@collect_all_reference_definition_assembly
	else
		@collect_all_reference_definition
	end

	@jump_to_first_reference_definition
end

@export_symbols+=
go_definition = go_definition,

@get_current_line+=
local line = vim.api.nvim_get_current_line()

@collect_all_reference_definition_assembly+=
for lnum, line in ipairs(assembled) do
	@if_line_is_section_check_if_correct_name_assembly
end

@if_line_is_reference_put_as_search+=
elseif string.match(line, "^%s*@[^@]%S*%s*$") then
	@get_reference_name
	tosearch = name
end

@if_line_is_section_put_as_search+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	tosearch = name

@if_line_is_section_check_if_correct_name_assembly+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	if name == tosearch then
		@add_as_definition_assembly
	end
end

@add_as_definition_assembly+=
local origin = origin[lnum]
local relpos = lnum - offset[origin]
local def = {
	origin = origin,
	lnum = relpos+1,
}

table.insert(definitions, def)

@collect_all_reference_definition+=
for lnum, line in ipairs(lines) do
	@if_line_is_section_check_if_correct_name
end

@if_line_is_section_check_if_correct_name+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	if name == tosearch then
		@add_as_definition
	end
end

@add_as_definition+=
local origin = vim.api.nvim_buf_get_name(0)
local def = {
	origin = origin,
	lnum = lnum,
}

table.insert(definitions, def)

@jump_to_first_reference_definition+=
assert(#definitions >= 1, "Definition not found")
local def = definitions[1]
local curbuf = vim.api.nvim_buf_get_name(0)
if def.origin ~= curbuf then
	vim.api.nvim_command("e " .. def.origin)
end

vim.fn.setpos(".", {0, def.lnum, 0, 0})

-- debug_array(definitions)
