##../ntangle_main
@../lua/ntangle.lua=
@requires
@parse_variables
@declare_functions
@functions
return {
@export_symbols
}

@functions+=
local function tangle(filename)
	local curassembly
	local lines = {}
	if filename then
		@read_lines_from_filename
	else
		@read_lines_from_buffer
	end

	@read_assembly_name_if_any
	if curassembly then
		@if_any_assembly_write_link_file
		local assembled = {}
		@glob_all_links_and_assemble
		local lines = assembled 
		@set_filename_of_assembled

		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_assembly
	else
		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections
	end
end

@export_symbols+=
tangle = tangle,

@read_file_line_by_line_from_variable+=
parse(lines)

@output_sections+=
filename = filename or vim.api.nvim_buf_get_name(0)
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header
		outputSections(lines, file, name, "")
		@check_file_is_modified
		@if_modified_write_file
	end
end

@if_star_replace_with_current_filename+=
if name == "*" then
	local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
	fn = parendir .. "/tangle/" .. tail

@otherwise_put_node_name+=
else
	if string.find(name, "/") then
		fn = parendir .. "/" .. name
	else
		fn = parendir .. "/tangle/" .. name
	end
end

@declare_functions+=
local outputSections

@functions+=
function outputSections(lines, file, name, prefix)
	@check_if_section_exists_otherwise_return_nil
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			@if_line_is_text_output_it
			@if_reference_recursively_call_output
		end
	end
end

@check_if_section_exists_otherwise_return_nil+=
if not sections[name] then
	return
end

@if_line_is_text_output_it+=
if line.linetype == LineType.TEXT then
	lines[#lines+1] = prefix .. line.str
end

@if_reference_recursively_call_output+=
if line.linetype == LineType.REFERENCE then
	outputSections(lines, file, line.str, prefix .. line.prefix)
end

@functions+=
local function tangleAll()
	@get_filelist
	for file in vim.gsplit(filelist, "\n") do
		tangle(file)
	end
end

@export_symbols+=
tangleAll = tangleAll,

@get_filelist+=
local filelist = vim.api.nvim_call_function("glob", { "**/*.tl" })

@check_file_is_modified+=
local modified = false
do
	local f = io.open(fn, "r")
	if f then 
		modified = false
		@check_if_every_line_match
		f:close()
	else
		modified = true
	end
end

@check_if_every_line_match+=
local lnum = 1
for line in f:lines() do
	if lnum > #lines then
		modified = true
		break
	end
	if line ~= lines[lnum] then
		modified = true
		break
	end
	lnum = lnum + 1
end

if lnum-1 ~= #lines then
	modified = true
end

@if_modified_write_file+=
if modified then
	local f, err = io.open(fn, "w")
	if f then
		for _,line in ipairs(lines) do
			f:write(line .. "\n")
		end
		f:close()
	else
		print(err)
	end
end

@functions+=
local function getRootFilename()
	local filename = vim.api.nvim_call_function("expand", { "%:p"})
	local parendir = vim.api.nvim_call_function("fnamemodify", { filename, ":p:h" })
  local roots = {}

  @read_lines_from_buffer
	@read_assembly_name_if_any
	if curassembly then
		@if_any_assembly_write_link_file
		local assembled = {}
		@glob_all_links_and_assemble
		local lines = assembled 
		@set_filename_of_assembled

		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_roots
	else
		@clear_sections
		@read_file_line_by_line_from_variable
		@output_roots
	end

  if #roots == 0 then
    print("No root found!")
  end

  if #roots > 1 then
    print("multiple roots " .. vim.inspect(roots))
  end

	return roots[1]
end

@if_first_line_is_assembly_skip+=
local line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
local lnum = 0
if string.match(line, "^##") then
  lnum = 1
end

@get_first_line_section_name+=
line = vim.api.nvim_buf_get_lines(0, lnum, lnum+1, true)[1]

@export_symbols+=
getRootFilename = getRootFilename,

@output_sections_roots+=
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
    table.insert(roots, fn)
	end
end

@output_roots+=
filename = filename or vim.api.nvim_buf_get_name(0)
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
    table.insert(roots, fn)
	end
end

@output_generated_header+=
if string.match(fn, "lua$") then
	local relname
	if filename then
		relname = filename
	else
		relname = vim.api.nvim_buf_get_name(0)
	end
	relname = vim.api.nvim_call_function("fnamemodify", { relname, ":t" })
	table.insert(lines, "-- Generated from " .. relname .. " using ntangle.nvim")
elseif string.match(fn, "vim$") then
	local relname
	if filename then
		relname = filename
	else
		relname = vim.api.nvim_buf_get_name(0)
	end
	relname = vim.api.nvim_call_function("fnamemodify", { relname, ":t" })
	table.insert(lines, "\" Generated from " .. relname .. " using ntangle.nvim")
end

@output_generated_header_fake+=
if string.match(filename, "lua.tl$") then
	table.insert(lines, {"", { str = "-- Generated from {relname} using ntangle.nvim" }})
elseif string.match(filename, "vim.tl$") then
	table.insert(lines, {"", { str = "\" Generated from {relname} using ntangle.nvim" }})
end

@read_lines_from_filename+=
for line in io.lines(filename) do
	table.insert(lines, line)
end

@read_lines_from_buffer+=
lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

@read_assembly_name_if_any+=
local line = lines[1] or ""
if string.match(lines[1], "^##%S*%s*$") then
	@extract_assembly_name
	@set_as_current_assembly
end

@extract_assembly_name+=
local name = string.match(line, "^##(%S*)%s*$")

@set_as_current_assembly+=
curassembly = name

@if_any_assembly_write_link_file+=
@construct_path_for_link_file
@write_link_file

@construct_path_for_link_file+=
local fn = filename or vim.api.nvim_buf_get_name(0)
local parendir = vim.fn.fnamemodify(fn, ":p:h")
local assembly_parendir = vim.fn.fnamemodify(curassembly, ":h")
local assembly_tail = vim.fn.fnamemodify(curassembly, ":t")
local part_tail = vim.fn.fnamemodify(fn, ":t")
local link_name = parendir .. "/" .. assembly_parendir .. "/tangle/" .. assembly_tail .. "." .. part_tail
local path = vim.fn.fnamemodify(link_name, ":h")
@create_directory_if_non_existent

@create_directory_if_non_existent+=
if vim.fn.isdirectory(path) == 0 then
	-- "p" means create also subdirectories
	vim.fn.mkdir(path, "p") 
end

@write_link_file+=
local link_file = io.open(link_name, "w")
link_file:write(fn)
link_file:close()


@glob_all_links_and_assemble+=
path = vim.fn.fnamemodify(path, ":p")
local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
link_name = vim.fn.fnamemodify(link_name, ":p")
for _, part in ipairs(parts) do
	if link_name ~= part then
		@read_link_from_link_file
		@append_lines_from_part_file
	else
		@add_to_parts_for_generated
		@append_current_buffer_to_the_assembled
	end
end

@read_link_from_link_file+=
local f = io.open(part, "r")
local origin_path = f:read("*line")
f:close()

@append_lines_from_part_file+=
local f = io.open(origin_path, "r")
if f then
	@add_to_parts_for_generated
	@put_offset_in_assembled_for_part
	local lnum = 1
	while true do
		local line = f:read("*line")
		if not line then break end
		if lnum > 1 then
			table.insert(assembled, line)
			@append_origin_to_assembled_array
		end
		lnum = lnum + 1
	end
	f:close()
else
	@remove_link_file
end

@remove_link_file+=
os.remove(part)

@glob_all_links_and_assemble-=
local origin = {}

@append_origin_to_assembled_array+=
table.insert(origin, origin_path)

@append_current_origin_to_assembled_array+=
table.insert(origin, fn)

@glob_all_links_and_assemble-=
local offset = {}

@put_offset_in_assembled_for_part+=
offset[origin_path] = #assembled

@put_offset_in_assembled_for_current+=
offset[fn] = #assembled

@append_current_buffer_to_the_assembled+=
@put_offset_in_assembled_for_current
for lnum, line in ipairs(lines) do
	if lnum > 1 then
		table.insert(assembled, line)
		@append_current_origin_to_assembled_array
	end
end

@set_filename_of_assembled+=
local ext = vim.fn.fnamemodify(fn, ":e:e")
local filename = parendir .. "/" .. assembly_parendir .. "/" .. assembly_tail .. "." .. ext

@output_sections_assembly+=
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header_assembly
		outputSections(lines, file, name, "")
		@check_file_is_modified
		@if_modified_write_file
	end
end

@output_generated_header_assembly+=
if string.match(fn, "lua$") then
	table.insert(lines, "-- Generated from " .. table.concat(valid_parts, ", ") .. " using ntangle.nvim")
elseif string.match(fn, "vim$") then
	table.insert(lines, "\" Generated from " .. table.concat(valid_parts, ", ") .. " using ntangle.nvim")
end

@glob_all_links_and_assemble-=
local valid_parts = {}

@add_to_parts_for_generated+=
table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
