##ntangle_main
@functions+=
local function collectSection()
	local curassembly
	local lines = {}
	@read_lines_from_buffer

	@save_cursor_position
	@read_assembly_name_if_any
	
	local tangled = {}
	local filename
	local jumpline

	if curassembly then
		@construct_path_for_link_file
		
		local assembled = {}
		@glob_all_links_and_assemble_except_current

		@append_current_buffer_to_the_assembled

		local rootlines = lines
		local lines = assembled
		@clear_sections
		@read_file_line_by_line_from_variable

		@get_containg_section_name
		@tangle_for_containing_section
		@search_in_tangled_the_line_where_the_cursor_was_assembly
		@save_lines_for_navigation_assembly
	else
		@clear_sections
		@read_file_line_by_line_from_variable

		local rootlines = lines
		@get_containg_section_name
		@tangle_for_containing_section
		@search_in_tangled_the_line_where_the_cursor_was
		@save_lines_for_navigation
	end

	@create_buffer_if_not_existent
	@get_current_window_dimensions
	@create_window_for_transpose
	@create_border_around_transpose_window

	@put_lines_in_buffer
	@jump_to_lines_in_transpose_buffer

	@keymap_transpose_buffer
end

@export_symbols+=
collectSection = collectSection,

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

@create_buffer_if_not_existent+=
transpose_buf = vim.api.nvim_create_buf(false, true)

@parse_variables+=
local transpose_win, transpose_buf

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

borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
vim.api.nvim_set_current_win(transpose_win)
vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")

@parse_variables+=
local borderwin 

@keymap_transpose_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua navigateTo()<CR>', {noremap = true})

@save_cursor_position+=
local _, row, _, _ = unpack(vim.fn.getpos("."))

@get_containg_section_name+=
local containing = get_section(rootlines, row)

@tangle_for_containing_section+=
outputSectionsFull(tangled, containing)

@search_in_tangled_the_line_where_the_cursor_was+=
for lnum, line in ipairs(tangled) do
	local _, l = unpack(line)
	if l.lnum == row then
		jumpline = lnum
		break
	end
end

assert(jumpline, "Could not find line to jump")

@put_lines_in_buffer+=
local transpose_lines = {}
for _, l in ipairs(tangled) do
	local prefix, line = unpack(l)
	table.insert(transpose_lines, prefix .. line.str)
end

vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)

@jump_to_lines_in_transpose_buffer+=
vim.fn.setpos(".", {0, jumpline, 0, 0})

@parse_variables+=
local nagivationLines = {}

@save_lines_for_navigation+=
navigationLines = {}
local curorigin = vim.api.nvim_buf_get_name(0)
for _,line in ipairs(tangled) do 
	local _, l = unpack(line)
	local nav = { origin = curorigin, lnum = l.lnum }
	table.insert(navigationLines, nav)
end

@functions+=
function navigateTo()
	@save_cursor_position
	@close_transpose_window
	@jump_to_linenumber
end

@close_transpose_window+=
vim.api.nvim_win_close(transpose_win, true)

@jump_to_linenumber+=
local n = navigationLines[row]
if vim.api.nvim_buf_get_name(0) ~= n.origin then
	vim.fn.nvim_command("e " .. n.origin)
end
vim.fn.setpos(".", {0, n.lnum, 0, 0})

@search_in_tangled_the_line_where_the_cursor_was_assembly+=
for lnum, line in ipairs(tangled) do
	local _, l = unpack(line)
	local relpos = l.lnum - offset[fn]
	if relpos == row-1 then
		jumpline = lnum
		break
	end
end

assert(jumpline, "Could not jump to line")

@save_lines_for_navigation_assembly+=
navigationLines = {}
for lnum,line in ipairs(tangled) do 
	local _, l = unpack(line)
	local origin = origin[l.lnum]
	local relpos = l.lnum - offset[origin]
	local nav = { origin = origin, lnum = relpos+1 }
	table.insert(navigationLines, nav)
end
