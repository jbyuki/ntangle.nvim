@*=
@requires
@parse_variables
@declare_functions
@functions
return {
@export_symbols
}

@functions+=
local function tangle(filename)
	@clear_sections
	if filename then
		@read_file_line_by_line
	else
		@read_file_line_by_line_from_buffer
	end
	@output_sections
end

@export_symbols+=
tangle = tangle,

@read_file_line_by_line+=
lnum = 1
for line in io.lines(filename) do
	@check_if_line_escape_double_at
	@check_if_line_is_section
	@check_if_line_is_reference
	@otherwise_add_to_section
	lnum = lnum+1;
end

@read_file_line_by_line_from_buffer+=
lnum = 1
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
for _,line in ipairs(lines) do
	@check_if_line_escape_double_at
	@check_if_line_is_section
	@check_if_line_is_reference
	@otherwise_add_to_section
	lnum = lnum+1;
end

@check_if_line_is_section+=
elseif string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	@create_new_section
	@link_to_previous_section_if_needed
	@otherwise_just_save_section
	@set_section_as_current_section

@parse_section_name+=
local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")

@line_types+=
SECTION = 3,

@create_new_section+=
local section = { linetype = LineType.SECTION, str = name, lines = {}}

@requires+=
require("linkedlist")

@parse_variables+=
local sections = {}
local curSection = nil

@clear_sections+=
sections = {}
curSection = nil

@link_to_previous_section_if_needed+=
if op == '+=' or op == '-=' then
	if sections[name] then
		if op == '+=' then
			@add_back_to_section
		elseif op == '-=' then
			@add_front_to_section
		end
	else
		@create_section_linked_list_non_root
		@add_back_to_section
	end

@add_back_to_section+=
linkedlist.push_back(sections[name].list, section)

@add_front_to_section+=
linkedlist.push_front(sections[name].list, section)

@create_section_linked_list_non_root+=
sections[name] = { root = false, list = {} }

@otherwise_just_save_section+=
else 
	@create_section_linked_list_root
	@add_back_to_section
	@add_to_root_sections
end

@create_section_linked_list_root+=
sections[name] = { root = true, list = {} }

@set_section_as_current_section+=
curSection = section

@check_if_line_is_reference+=
elseif string.match(line, "^%s*@[^@]%S*%s*$") then
	@get_reference_name
	-- @check_that_sections_is_not_empty
	@create_line_reference
	@add_line_to_section

@get_reference_name+=
local _, _, prefix, name = string.find(line, "^(%s*)@(%S+)%s*$")
if name == nil then
	print(line)
end

@check_that_sections_is_not_empty+=
if sections[name] then
	hasSection = true
end

@parse_variables+=
local LineType = {
	@line_types
}

@line_types+=
REFERENCE = 1,

@create_line_reference+=
local l = { 
	linetype = LineType.REFERENCE, 
	str = name,
	prefix = prefix
}

@otherwise_add_to_section+=
else
	@check_that_sections_is_not_empty
	@create_text_line
	@add_line_to_section
end

@line_types+=
TEXT = 2,

@create_text_line+=
local l = { 
	linetype = LineType.TEXT, 
	str = line 
}

@check_if_line_escape_double_at+=
if string.match(line, "^%s*@@") then
	local hasSection = false
	@check_that_sections_is_not_empty
	if hasSection then
		@create_text_line_without_at
		@add_line_to_section
	end

@create_text_line_without_at+=
local _,_,pre,post = string.find(line, '^(.*)@@(.*)$')
local text = pre .. "@" .. post
local l = { 
	linetype = LineType.TEXT, 
	str = text 
}

@add_line_to_section+=
linkedlist.push_back(curSection.lines, l)

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
	@if_dot_slash_put_in_current_directory
	@otherwise_put_in_tangle_directory
end

@if_dot_slash_put_in_current_directory+=
if string.match(name, "%./") then
	fn = parendir .. string.sub(name, 2)

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
local function goto(filename, linenum, root_pattern)
	@clear_sections
	@read_file_line_by_line
	@select_based_on_pattern
	@fake_output_until_linenum_readched
	@go_to_line
end

@export_symbols+=
goto = goto,

@create_text_line+=
l.lnum = lnum

@create_text_line_without_at+=
l.lnum = lnum

@declare_functions+=
local getlinenum

@fake_output_until_linenum_readched+=
local _,lnum = getlinenum(root, 1, linenum)
assert(lnum, "Could not go to line " .. linenum .. " in " .. root)

@functions+=
function getlinenum(name, cur, goal)
	@check_if_section_exists_otherwise_return_with_cur
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			@if_line_is_text_increment_and_verify_goal
			@if_reference_recursively_call_getlinenum
		end
	end
	return cur, nil
end

@check_if_section_exists_otherwise_return_with_cur+=
if not sections[name] then
	return cur, nil
end

@if_line_is_text_increment_and_verify_goal+=
if line.linetype == LineType.TEXT then
	if cur == goal then 
		return cur, line.lnum 
	end
	cur = cur + 1
end

@if_reference_recursively_call_getlinenum+=
if line.linetype == LineType.REFERENCE then
	local found
	cur, found = getlinenum(line.str, cur, goal)
	if found then 
		return cur, found 
	end
end

@go_to_line+=
vim.api.nvim_command("normal " .. lnum .. "gg")

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

@declare_functions+=
local toluapat

@functions+=
function toluapat(pat)
	local luapat = ""
	for i=1,#pat do
		local c = string.sub(pat, i, i)

		if c == '*' then luapat = luapat .. "."
		elseif c == '.' then luapat = luapat .. "%."
		else luapat = luapat .. c end
	end
	return luapat
end

@select_based_on_pattern+=
local root
for name,section in pairs(sections) do
	if section.root and string.find(name, toluapat(root_pattern)) then
		root = name
		break
	end
end

if not root then
	print("Could not root section " .. root_pattern .. " " .. toluapat(root_pattern))
end
