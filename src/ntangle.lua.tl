##ntangle_main
@../lua/ntangle.lua=
@requires
@parse_variables
@declare_functions
@functions
return {
@export_symbols
}

@read_file_line_by_line+=
local lines = {}
for line in io.lines(filename) do
	table.insert(lines, line)
end
parse(lines)

@read_file_line_by_line_from_variable+=
parse(lines)

@output_sections+=
if not filename then
	filename = vim.api.nvim_call_function("expand", { "%:p"})
end
local parendir = vim.api.nvim_call_function("fnamemodify", { filename, ":p:h" })
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
	@if_has_slash_put_in_indicated_directory
	@otherwise_put_in_tangle_directory
end

@if_has_slash_put_in_indicated_directory+=
if string.find(name, "/") then
	fn = parendir .. "/" .. name

@otherwise_put_in_tangle_directory+=
else 
	fn = parendir .. "/tangle/" .. name
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
	local f = io.open(fn, "w")
	if f then
		for _,line in ipairs(lines) do
			f:write(line .. "\n")
		end
		f:close()
	else
		print("Could not write to " .. fn)
	end
end

@functions+=
local function getRootFilename()
	local filename = vim.api.nvim_call_function("expand", { "%:p"})
	local parendir = vim.api.nvim_call_function("fnamemodify", { filename, ":p:h" })

	@get_first_line_section_name
	@parse_section_name

	local fn
	@if_star_replace_with_current_filename
	@otherwise_put_node_name
	return fn
end

@get_first_line_section_name+=
local line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]

@export_symbols+=
getRootFilename = getRootFilename,

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

@skip_some_lines_if_generated_header+=
if string.match(fn, "lua$") then
	startline = startline + 1
end

if string.match(fn, "vim$") then
	startline = startline + 1
end

@output_generated_header_fake+=
if string.match(fn, "lua$") then
	table.insert(lines, {1, "-- Generated from {relname} using ntangle.nvim"})
elseif string.match(fn, "vim$") then
	table.insert(lines, {1, "\" Generated from {relname} using ntangle.nvim"})
end

@get_expanded_name_from_current_buffer+=
local fn = name
if name == "*" then
	local filename = vim.api.nvim_buf_get_name(0)
	fn = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
end

@if_star_replace_and_star_not_present_replace+=
if root == "*" and not sections["*"] then
	for name,section in pairs(sections) do
		if section.root then
			root = name
			break
		end
	end
end

@put_storage_text_on_top+=
local parent_win = vim.api.nvim_get_current_win()
vim.api.nvim_set_current_win(storagewin)
vim.api.nvim_set_current_win(parent_win)

@create_storage_float_window+=
vim.api.nvim_win_set_option(storagewin, "winblend", 30)

@create_storage_float_window_border_window+=
vim.api.nvim_win_set_option(borderwin, "winblend", 30)

@get_current_window_dimensions+=
local perc = 0.8
local win_width  = vim.api.nvim_win_get_width(0)
local win_height = vim.api.nvim_win_get_height(0)
local width = math.floor(perc*win_width)
local height = math.floor(perc*win_height)

@create_window_for_transpose+=
local opts = {
	width = width,
	height = height,
	row = math.floor((win_height-height)/2),
	col = math.floor((win_width-width)/2),
	relative = "win",
	win = vim.api.nvim_get_current_win(),
}

transpose_win = vim.api.nvim_open_win(transpose_buf, false, opts)

@parse_variables+=
local transpose_win

@create_border_around_transpose_window+=
local borderbuf = vim.api.nvim_create_buf(false, true)

local border_opts = {
	relative = "win",
	win = vim.api.nvim_get_current_win(),
	width = opts.width+2,
	height = opts.height+2,
	col = opts.col-1,
	row =  opts.row-1,
	style = 'minimal'
}

local border_title = "Transpose"
local center_title = true
@fill_buffer_with_border_characters

local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
vim.api.nvim_set_current_win(transpose_win)
vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")

@switch_to_back_to_buffer+=
vim.api.nvim_win_close(transpose_win, true)

@functions+=
local function tangle(filename)
	local assemblies = {}
	if filename then
		@read_file_line_by_line_and_separate_assemblies
	else
		@read_buffer_line_by_line_and_separate_assemblies
	end

	@foreach_assembly_write_out_assembly
	@foreach_assembly_glob_and_asssemble_and_tangle
	@if_there_is_an_unamed_assemble_just_tangle
end

@export_symbols+=
tangle = tangle,

@read_file_line_by_line_and_separate_assemblies+=
local curassembly = "*"
assemblies[curassembly] = {}

for line in io.lines(filename) do
	if string.match(line, "^@@%S*+=%s*$") then
		@extract_assembly_name
		@set_as_current_assembly
	else
		@add_line_to_current_assembly
	end
end


@read_buffer_line_by_line_and_separate_assemblies+=
local curassembly = "*"
assemblies[curassembly] = {}

local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
for _, line in ipairs(lines) do
	if string.match(line, "^##%S*%s*$") then
		@extract_assembly_name
		@set_as_current_assembly
	else
		@add_line_to_current_assembly
	end
end

@extract_assembly_name+=
local name = string.match(line, "^##(%S*)%s*$")

@set_as_current_assembly+=
curassembly = name
assemblies[curassembly] = assemblies[curassembly] or {}

@add_line_to_current_assembly+=
table.insert(assemblies[curassembly], line)

@foreach_assembly_write_out_assembly+=
for name, lines in pairs(assemblies) do
	if name ~= "*" and #lines > 0 then
		@get_current_buffer_name_for_assembly_part
		@create_assembly_tangle_directory_if_not_existent
		@create_directory_if_non_existent
		@open_file_for_assembly_part
		@write_out_assembly_part_origin
		@write_to_assembly_part
		f:close()
	end
end

@get_current_buffer_name_for_assembly_part+=
if not filename then
	filename = vim.fn.expand("%:p")
end

local parendir = vim.fn.fnamemodify( filename, ":p:h" )
local fn
@add_assembly_part_suffix

@add_assembly_part_suffix+=
local fname = vim.fn.fnamemodify( filename, ":t:r" )
local ns = vim.fn.fnamemodify( name, ":t" )
local reldir = vim.fn.fnamemodify( name, ":h" )
fn = parendir .. "/" .. reldir .. "/tangle/" .. ns .. "." .. fname .. ".tlpart"

@create_assembly_tangle_directory_if_not_existent+=
local parendir =  vim.fn.fnamemodify(fn, ":h") 
local isdir = vim.fn.isdirectory(parendir)
if isdir == 0 then
	vim.fn.mkdir(parendir, "p" )
end

@open_file_for_assembly_part+=
local f = io.open(fn, "w")

@write_to_assembly_part+=
for _, line in ipairs(lines) do
	f:write(line .. "\n")
end

@foreach_assembly_glob_and_asssemble_and_tangle+=
for name, lines in pairs(assemblies) do
	if name ~= "*" and #lines > 0 then
		@get_current_buffer_name_for_assembly_part
		@glob_all_parts
		@assemble_lines_into_single_table
		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_assembly
	end
end

@glob_all_parts+=
local assembly = {
	name = vim.split(vim.fn.fnamemodify(fn, ":t"), "%.")[1],
	ext = vim.fn.fnamemodify(filename, ":e:e:r"),
	tangle_dir = vim.fn.fnamemodify(fn, ":h"),
	dir = vim.fn.fnamemodify(fn, ":h:h"),
}
local parts = vim.fn.glob(assembly.tangle_dir .. "/" .. assembly.name .. ".*.tlpart")
parts = vim.split(parts, "\n")

@assemble_lines_into_single_table+=
local lines = {}
for _, part in ipairs(parts) do
	@read_single_assembly_part_and_skip_first_which_is_origin
end

@read_single_assembly_part_and_skip_first_which_is_origin+=
local first = true
for line in io.lines(part) do
	if first then
		first = false
	else
		table.insert(lines, line)
	end
end

@output_sections_assembly+=
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_assembled_filename
		@otherwise_put_node_name_assembled
		lines = {}
		@output_generated_header_assembly
		outputSections(lines, file, name, "")
		@check_file_is_modified
		@if_modified_write_file
	end
end

@if_star_replace_assembled_filename+=
if name == "*" then
	fn = assembly.tangle_dir .. "/" .. assembly.name .. "." .. assembly.ext

@otherwise_put_node_name_assembled+=
else
	fn = assembly.dir .. "/" .. name
end

@if_there_is_an_unamed_assemble_just_tangle+=
if #assemblies["*"] > 0 then
	local lines = assemblies["*"]
	@clear_sections
	@read_file_line_by_line_from_variable
	local filename
	@output_sections
end

@output_generated_header_assembly+=
local parts_tails = {}
for _, part in ipairs(parts) do
	local fn = vim.fn.fnamemodify(part, ":t:r")
	fn = vim.split(fn, "%.")
	table.remove(fn, 1)
	table.insert(parts_tails, table.concat(fn, ".") .. ".tl")
end

if string.match(fn, "lua$") then
	table.insert(lines, "-- Generated from " .. table.concat(parts_tails, ", ") .. " using ntangle.nvim")
elseif string.match(fn, "vim$") then
	table.insert(lines, "\" Generated from " .. table.concat(parts_tails, ", ") .. " using ntangle.nvim")
end

@write_out_assembly_part_origin+=
if not filename then
	filename = vim.api.nvim_buf_get_name()
end
f:write(filename .. "\n")
