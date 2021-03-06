##../ntangle_main
@declare_functions+=
local contextmenu_open

@functions+=
function contextmenu_open(candidates, callback)
	@compute_max_width_for_context_menu
	@create_float_context_menu
	@put_text_in_context_menu
	@attach_keymap_to_context_menu
	@setup_context_menu_window
	@save_contextmenu_callback
end

@compute_max_width_for_context_menu+=
local max_width = 0
for _, el in ipairs(candidates) do
	max_width = math.max(max_width, vim.api.nvim_strwidth(el))
end

@create_float_context_menu+=
local buf = vim.api.nvim_create_buf(false, true)
local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

local opts = {
	relative = "cursor",
	width = max_width,
	height = #candidates,
	col = 2,
	row =  2,
	style = 'minimal',
  border = 'single',
}

contextmenu_win = vim.api.nvim_open_win(buf, false, opts)

@put_text_in_context_menu+=
vim.api.nvim_buf_set_lines(buf, 0, -1, true, candidates)

@attach_keymap_to_context_menu+=
vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<cmd>lua require"ntangle".select_contextmenu()<CR>', {noremap = true})

@parse_variables+=
local contextmenu_contextmenu

@save_contextmenu_callback+=
contextmenu_contextmenu = callback

@functions+=
local function select_contextmenu()
	local row = vim.fn.line(".")
	if contextmenu_contextmenu then
		@close_contextmenu_window
		contextmenu_contextmenu(row)
		contextmenu_contextmenu = nil
	end
end

@export_symbols+=
select_contextmenu = select_contextmenu,

@parse_variables+=
local contextmenu_win

@close_contextmenu_window+=
vim.api.nvim_win_close(contextmenu_win, true)

@setup_context_menu_window+=
vim.api.nvim_win_set_option(contextmenu_win, "winblend", 30)
vim.api.nvim_win_set_option(contextmenu_win, "cursorline", true)
vim.api.nvim_set_current_win(contextmenu_win)
