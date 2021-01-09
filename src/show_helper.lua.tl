##ntangle_main
@functions+=
local function show_helper()
	@clear_sections
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	@read_file_line_by_line_from_variable
	@from_every_root_node_mark_visited_sections
	local qflist = {}
	@output_undefined_section_references
	@search_ophan_sections
	@output_orphan_sections

	@compute_max_width_for_helper_window
	@create_float_window_for_helper
	@create_float_window_border_window
	@put_text_in_helper_window
	@attach_autocommand_to_close_helper_on_movement
end

@export_symbols+=
show_helper = show_helper,

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
	table.insert(qflist, name .. " is empty" )
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
	table.insert(qflist, name .. " is an orphan section")
end

@compute_max_width_for_helper_window+=
local max_width = 0
for _, line in ipairs(qflist) do
	max_width = math.max(max_width, vim.api.nvim_strwidth(line))
end

@create_float_window_for_helper+=
local buf = vim.api.nvim_create_buf(false, true)
local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

local MAX_WIDTH = 60
local MAX_HEIGHT = 15

local popup = {
	width = math.min(max_width, MAX_WIDTH),
	height = math.min(#qflist, MAX_HEIGHT),
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

local win = vim.api.nvim_open_win(buf, false, opts)

@create_float_window_border_window+=
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

local border_title = " ntangle helper "
local center_title = true
@fill_buffer_with_border_characters

local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)

@create_float_window_for_helper+=
vim.api.nvim_win_set_option(win, "winblend", 30)

@create_float_window_border_window+=
vim.api.nvim_win_set_option(borderwin, "winblend", 30)

@put_text_in_helper_window+=
vim.api.nvim_buf_set_lines(buf, 0, -1, true, qflist)

@declare_functions+=
local close_preview_autocmd

@functions+=
function close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

@attach_autocommand_to_close_helper_on_movement+=
close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, borderwin)
