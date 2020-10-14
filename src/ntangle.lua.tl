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
	@save_line_reference
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

@create_line_reference+=
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
if root_pattern ~= "*" then
	for name,section in pairs(sections) do
		if section.root and string.find(name, toluapat(root_pattern)) then
			root = name
			break
		end
	end

	if not root then
		print("Could not root section " .. root_pattern .. " " .. toluapat(root_pattern))
	end
else
	root = root_pattern
end

@functions+=
local function collectSection()
	@clear_sections
	@read_file_line_by_line_from_buffer
	@get_section_name_of_current_line
	@check_if_section_is_present
	@collect_every_line_in_section
	@save_current_buffer

	@create_buffer_if_not_existent
	@switch_to_buffer
	@clear_buffer
	@put_lines_in_buffer
	@remove_last_line_in_buffer
	@save_lines_for_navigation
	@jump_to_lines_in_transpose_buffer
end

@export_symbols+=
collectSection = collectSection,

@check_if_section_is_present+=
local s
for n, section in pairs(sections) do
	if n == name then
		s = section
		break
	end
end
if not s then
	print("Could not find section " .. name)
	return
end

@collect_every_line_in_section+=
local lines = {}
for section in linkedlist.iter(s.list) do
	for line in linkedlist.iter(section.lines) do
		lines[#lines+1] = line
	end
end

@parse_variables+=
local lineRefs = {}

@save_line_reference+=
lineRefs[lnum] = curSection.str

@clear_sections+=
lineRefs = {}

@get_section_name_of_current_line+=
local curnum = vim.api.nvim_call_function("line", {"."})
local name = lineRefs[curnum]

@create_buffer_if_not_existent+=
if vim.api.nvim_call_function("bufexists", {"transpose"}) == 0 then
	vim.api.nvim_command("edit transpose")
	@setup_buffer
end

@setup_buffer+=
vim.api.nvim_command("setlocal buftype=nofile")
vim.api.nvim_command("setlocal bufhidden=hide")
vim.api.nvim_command("setlocal noswapfile")

@switch_to_buffer+=
local desiredbufnr = vim.api.nvim_call_function("bufnr", {"transpose"})
vim.api.nvim_command("buffer " .. desiredbufnr)

@clear_buffer+=
vim.api.nvim_command("normal ggdG")

@put_lines_in_buffer+=
local lnumtr = 0
local jumpline = 1
for _,line in ipairs(lines) do
	local text
	@get_line_text_from_line_text
	@get_line_text_from_line_reference
	@check_for_line_to_jump_to
	vim.api.nvim_buf_set_lines(desiredbufnr, lnumtr, lnumtr, false, { text })
	lnumtr = lnumtr + 1
end

@get_line_text_from_line_text+=
if line.linetype == LineType.TEXT then text = line.str end

@get_line_text_from_line_reference+=
if line.linetype == LineType.REFERENCE then text = line.prefix .. "@" .. line.str end

@setup_buffer+=
vim.api.nvim_buf_set_keymap(0, 'n', '<leader>i', '<cmd>lua navigateTo()<CR>', {noremap = true})

@parse_variables+=
local nagivationLines = {}

@save_current_buffer+=
local originbuf = vim.api.nvim_call_function("bufnr", {})
local curcol = vim.api.nvim_call_function("col", {"."})

@save_lines_for_navigation+=
navigationLines = {}
for _,line in ipairs(lines) do 
	navigationLines[#navigationLines+1] = { buf = originbuf, lnum = line.lnum }
end

@functions+=
function navigateTo()
	@get_current_line_number
	@switch_to_back_to_buffer
	@jump_to_linenumber
end

@get_current_line_number+=
local curline = vim.api.nvim_call_function("line", {'.'})
local curcol = vim.api.nvim_call_function("col", {'.'})
local nav = navigationLines[curline]

@switch_to_back_to_buffer+=
vim.api.nvim_command("buffer " .. nav.buf)

@jump_to_linenumber+=
vim.api.nvim_call_function("cursor", { nav.lnum, curcol })


@check_for_line_to_jump_to+=
if line.lnum == curnum then
	jumpline = lnumtr+1
end

@jump_to_lines_in_transpose_buffer+=
vim.api.nvim_call_function("cursor", { jumpline, curcol-1 })

@remove_last_line_in_buffer+=
vim.api.nvim_command("normal Gddgg")
