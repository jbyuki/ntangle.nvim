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
local function goto(filename, linenum, root_pattern)
	@clear_sections
	@read_file_line_by_line
	@select_based_on_pattern
	@if_star_replace_and_star_not_present_replace
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
local startline = 1
@get_expanded_root_name
@skip_some_lines_if_generated_header
local _,lnum = getlinenum(root, startline, linenum)
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
	@collect_recursively_lines
	@save_current_buffer

	@create_buffer_if_not_existent
	@keymap_transpose_buffer
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
if not s then return end

@declare_functions+=
local collectLines

@functions+=
function collectLines(name, lines, prefix, curnum)
	local jumpline
	@check_if_section_is_present
	@collect_every_line_in_section
	return jumpline
end

@collect_every_line_in_section+=
for section in linkedlist.iter(s.list) do
	for line in linkedlist.iter(section.lines) do
		if line.lnum == curnum then jumpline = #lines+1 end

		if line.linetype == LineType.TEXT then table.insert(lines, { line.lnum, prefix .. line.str })
		elseif line.linetype == LineType.REFERENCE then 
			jumpline = collectLines(line.str, lines, prefix .. line.prefix, curnum) or jumpline
		end
	end
end

@collect_recursively_lines+=
local lines = {}
@get_expanded_name_from_current_buffer
@output_generated_header_fake
local jumpline = collectLines(name, lines, "", curnum)

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
local transpose_buf = vim.api.nvim_create_buf(false, true)
local old_ft = vim.api.nvim_buf_get_option(0, "ft")
if old_ft then
	vim.api.nvim_buf_set_option(transpose_buf, "ft", old_ft)
end
-- vim.api.nvim_buf_set_name(transpose_buf, "transpose")

@switch_to_buffer+=
vim.api.nvim_set_current_buf(transpose_buf)

@clear_buffer+=
vim.api.nvim_command("normal ggdG")

@put_lines_in_buffer+=
local lnumtr = 0
for _,line in ipairs(lines) do
	local lnum, text = unpack(line)
	vim.api.nvim_buf_set_lines(transpose_buf, lnumtr, lnumtr, false, { text })
	lnumtr = lnumtr + 1
end

@keymap_transpose_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua navigateTo()<CR>', {noremap = true})

@parse_variables+=
local nagivationLines = {}

@save_current_buffer+=
local originbuf = vim.api.nvim_call_function("bufnr", {})
local curcol = vim.api.nvim_call_function("col", {"."})

@save_lines_for_navigation+=
navigationLines = {}
for _,line in ipairs(lines) do 
	local lnum, _ = unpack(line)
	navigationLines[#navigationLines+1] = { buf = originbuf, lnum = lnum }
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

@jump_to_lines_in_transpose_buffer+=
if jumpline then
	vim.api.nvim_call_function("cursor", { jumpline, curcol-1 })
end

@remove_last_line_in_buffer+=
vim.api.nvim_command("normal Gddgg")

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
end

if string.match(fn, "vim$") then
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
end

if string.match(fn, "vim$") then
	table.insert(lines, {1, "\" Generated from {relname} using ntangle.nvim"})
end

@get_expanded_root_name+=
local fn = root
if root == "*" then
	fn = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
end

@get_expanded_name_from_current_buffer+=
local fn = name
if name == "*" then
	local filename = vim.api.nvim_buf_get_name(0)
	fn = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
end

@functions+=
local function show_errors(filename)
	@clear_sections
	@read_file_line_by_line
	@from_every_root_node_mark_visited_sections
	local qflist = {}
	@output_undefined_section_references
	@search_ophan_sections
	@output_orphan_sections
	@set_qflist_window
end

@export_symbols+=
show_errors = show_errors,

@from_every_root_node_mark_visited_sections+=
local visited, notdefined = {}, {}
for name, section in pairs(sections) do
	if section.root then
		visitSections(visited, notdefined, name, 0)
	end
end

@declare_functions+=
local visitSections

@functions+=
function visitSections(visited, notdefined, name, lnum) 
	@if_already_visited_skip
	@if_not_defined_add_and_skip
	visited[name] = true
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			@if_reference_recursively_visit
		end
	end
end

@if_already_visited_skip+=
if visited[name] then
	return
end

@if_not_defined_add_and_skip+=
if not sections[name] then
	notdefined[name] = lnum
	return
end

@if_reference_recursively_visit+=
if line.linetype == LineType.REFERENCE then
	visitSections(visited, notdefined, line.str, line.lnum)
end

@output_undefined_section_references+=
for name, lnum in pairs(notdefined) do
	table.insert(qflist, {
		filename = filename,
		lnum = lnum,
		text = name .. " is empty",
		type = "W",
	})
end

@declare_functions+=
local searchOrphans

@functions+=
function searchOrphans(name, visited, orphans, lnum) 
	@if_not_section_skip
	@if_not_visited_set_as_orphan_visited_child_and_quit
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			@if_reference_go_further_for_orphans
		end
	end
end

@if_not_visited_set_as_orphan_visited_child_and_quit+=
if not visited[name] and linkedlist.get_size(sections[name].list) > 0 then
	orphans[name] = lnum
	local dummy = {}
	visitSections(visited, dummy, name, 0)
	return
end

@if_not_section_skip+=
if not sections[name] then
	return
end

@if_reference_go_further_for_orphans+=
if line.linetype == LineType.REFERENCE then
	searchOrphans(line.str, visited, orphans, line.lnum)
end

@search_ophan_sections+=
local orphans = {}
for name, section in pairs(sections) do
	if not section.root then
		searchOrphans(name, visited, orphans, 0)
	end
end

@output_orphan_sections+=
for name, lnum in pairs(orphans) do
	table.insert(qflist, {
		filename = filename,
		lnum = lnum,
		text = name .. " is an orphan section",
		type = "W",
	})
end

@set_qflist_window+=
vim.fn.setqflist(qflist, "r")

@functions+=
local function show_storage(buf)
	@create_storage_float_window
	@create_storage_float_window_border_window
	@put_storage_text_on_top
	@setup_storage_float_window_syntax_highlighting
	vim.api.nvim_buf_attach(buf, false, { on_lines = function(...)
		vim.schedule(function()
			@clear_sections
			@clear_highlighting
			@read_file_line_by_line_from_buffer
			@from_every_root_node_mark_visited_sections
			local undefined = {}
			@collect_undefined_section_references
			@update_storage_window
		end)
	end})

	storages[buf] = {}
	@save_storages_info_for_buf
end

@export_symbols+=
show_storage = show_storage,

@functions+=
local function close_storage()
	@close_storage_float_window
end

@export_symbols+=
close_storage = close_storage,

@parse_variables+=
local storages = {}

@create_storage_float_window+=
local storagebuf = vim.api.nvim_create_buf(false, true)
local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

local popup = {
	width = 40,
	height = 15,
	margin_up = 3,
	margin_right = 6,
}

local opts = {
	relative = "win",
	win = vim.api.nvim_get_current_win(),
	width = popup.width,
	height = popup.height,
	col = w - popup.width - popup.margin_right,
	row =  popup.margin_up,
	style = 'minimal'
}

if storages[buf] then
	vim.api.nvim_win_close(storages[buf].win, true)
end
local storagewin = vim.api.nvim_open_win(storagebuf, false, opts)

@save_storages_info_for_buf+=
storages[buf].win = storagewin

@close_storage_float_window+=
local buf = vim.api.nvim_get_current_buf()
if storages[buf] then
	vim.api.nvim_win_close(storages[buf].win, true)
	@close_border_window
	storages[buf] = nil
end


@collect_undefined_section_references+=
for name, lnum in pairs(notdefined) do
	table.insert(undefined, name)
end
table.sort(undefined, function(a, b) return notdefined[a] < notdefined[b] end)

@update_storage_window+=
@format_tasks
vim.api.nvim_buf_set_lines(storagebuf, 0, -1, true, tasks)
@highlight_all_tasks
@show_remaining_in_storage

@parse_variables+=
local task_prefix = "→ "

@format_tasks+=
local tasks = {}
for _, el in ipairs(undefined) do
	table.insert(tasks, task_prefix .. el)
end

@show_remaining_in_storage+=
local remaining = {
	"Storage",
	"",
}

vim.api.nvim_buf_set_lines(storagebuf, 0, 0, true, remaining)
-- vim.api.nvim_buf_add_highlight(storagebuf, hi_ns, "Special", 0, 0, string.len(tostring(#undefined)))

@highlight_all_tasks+=
for i=0,#undefined-1 do
	vim.api.nvim_buf_add_highlight(storagebuf, hi_ns, "Special", i, string.len(task_prefix), -1)
end

@setup_storage_float_window_syntax_highlighting+=
local hi_ns = vim.api.nvim_create_namespace("")

@clear_highlighting+=
vim.api.nvim_buf_clear_namespace(storagebuf, hi_ns, 0, -1)

@if_star_replace_and_star_not_present_replace+=
if root == "*" and not sections["*"] then
	for name,section in pairs(sections) do
		if section.root then
			root = name
			break
		end
	end
end

@create_storage_float_window_border_window+=
local borderbuf = vim.api.nvim_create_buf(false, true)

local border_opts = {
	relative = "win",
	win = vim.api.nvim_get_current_win(),
	width = popup.width+2,
	height = popup.height+2,
	col = w - popup.width - popup.margin_right - 1,
	row =  popup.margin_up - 1,
	style = 'minimal'
}

@fill_buffer_with_border_characters

if storages[buf] then
	vim.api.nvim_win_close(storages[buf].borderwin, true)
end

local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)

@save_storages_info_for_buf+=
storages[buf].borderwin = borderwin

@close_border_window+=
vim.api.nvim_win_close(storages[buf].borderwin, true)

@fill_buffer_with_border_characters+=
local border_text = {}

local border_chars = {
	topleft  = '╭',
	topright = '╮',
	top      = '─',
	left     = '│',
	right    = '│',
	botleft  = '╰',
	botright = '╯',
	bot      = '─',
}

for y=1,border_opts.height do
	local line = ""
	if y == 1 then
		@create_border_top
	elseif y == border_opts.height then
		@create_border_bottom
	else
		@create_border_middle
	end
	table.insert(border_text, line)
end

vim.api.nvim_buf_set_lines(borderbuf, 0, -1, true, border_text)

@create_border_top+=
line = border_chars.topleft
for x=2,border_opts.width-1 do
	line = line .. border_chars.top
end
line = line .. border_chars.topright

@create_border_bottom+=
line = border_chars.botleft
for x=2,border_opts.width-1 do
	line = line .. border_chars.bot
end
line = line .. border_chars.botright

@create_border_middle+=
line = border_chars.left
for x=2,border_opts.width-1 do
	line = line .. " "
end
line = line .. border_chars.right

@put_storage_text_on_top+=
local parent_win = vim.api.nvim_get_current_win()
vim.api.nvim_set_current_win(storagewin)
vim.api.nvim_set_current_win(parent_win)

@create_storage_float_window+=
vim.api.nvim_win_set_option(storagewin, "winblend", 30)

@create_storage_float_window_border_window+=
vim.api.nvim_win_set_option(borderwin, "winblend", 30)
