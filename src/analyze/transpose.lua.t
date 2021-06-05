##../ntangle_main
@functions+=
local function transpose()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)
	local assembled = {}

	@save_cursor_position
	@save_current_filetype

  local jumplines = {}
  @augment_tangled_with_lnum
  @fill_jumplines

	local selected = function(row) 
		local jumpline = jumplines[row]

    create_transpose_buf(ft)

		@put_lines_in_buffer
		@keymap_transpose_buffer

    @save_lines_for_navigation
		@jump_to_lines_in_transpose_buffer
	end

	@open_context_menu_if_multiple_or_jump_directly
end

@export_symbols+=
transpose = transpose,

@augment_tangled_with_lnum+=
for name, root in pairs(tangled.roots) do
  local lnum = 1
  local lines = {}
  local fn = get_origin(buf, tangled.asm, name)
  @output_ntangle_header
  lnum = lnum + #lines

  local it = root.tangled[1]
  while it and it ~= root.tangled[2] do
    if it.data.linetype ~= LineType.SENTINEL then
      it.data.lnum = lnum
      it.data.root = name
      lnum = lnum + 1
    end
    it = it.next
  end
end

@fill_jumplines+=
for part in linkedlist.iter(tangled.parts_ll) do
  if part.origin == buf then
    local part_lnum = 1
    local it = part.start_part
    while it and it ~= part.end_part do
      if it.data.linetype ~= LineType.SENTINEL then
        if part_lnum == row then
          jumplines = it.data.tangled
          break
        end
        part_lnum = part_lnum + 1
      end
      it = it.next
    end

    if jumplines then break end
  end
end

@declare_functions+=
local create_transpose_buf

@functions+=
function create_transpose_buf(ft)
  @create_buffer_if_not_existent
  @get_current_window_dimensions
  @create_window_for_transpose
  @setup_transpose_buffer
end

@get_current_window_dimensions+=
local perc = 0.9
local win_width  = vim.o.columns
local win_height = vim.o.lines
local width = math.floor(perc*win_width)
local height = math.floor(perc*win_height)

@create_window_for_transpose+=
local opts = {
	width = width,
	height = height,
	row = math.floor((win_height-height)/2),
	col = math.floor((win_width-width)/2),
	relative = "editor",
  border = "single",
}

transpose_win = vim.api.nvim_open_win(transpose_buf, true, opts)

@create_buffer_if_not_existent+=
transpose_buf = vim.api.nvim_create_buf(false, true)

@parse_variables+=
local transpose_win, transpose_buf

@keymap_transpose_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua require"ntangle".navigateTo()<CR>', {noremap = true})

@save_cursor_position+=
local _, row, _, _ = unpack(vim.fn.getpos("."))

@put_lines_in_buffer+=
local transpose_lines = {}

local lines = {}
local fn = get_origin(buf, tangled.asm, jumpline.data.root)
@output_ntangle_header

for _, line in ipairs(lines) do
  table.insert(transpose_lines, line)
end

local root = tangled.roots[jumpline.data.root]
local it = root.tangled[1]
while it and it ~= root.tangled[2] do
  if it.data.linetype ~= LineType.SENTINEL then
    table.insert(transpose_lines, it.data.str)
  end
  it = it.next
end

vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)

@jump_to_lines_in_transpose_buffer+=
vim.schedule(function()
  vim.api.nvim_win_set_cursor(transpose_win, {jumpline.data.lnum, 0})
end)

@parse_variables+=
local navigationLines = {}

@save_lines_for_navigation+=
navigationLines = {
  tangled = tangled,
  buf = buf,
  root = jumpline.data.root,
}

@functions+=
local function navigateTo()
	@save_cursor_position
	@close_transpose_window
  local tangled = navigationLines.tangled
  local root = navigationLines.root
  @find_tangle_at_row
  if tangled_it then
    local untangled = tangled_it.data.untangled
    @find_untangle_origin_and_lnum
    @jump_to_linenumber
  end
end

@export_symbols+=
navigateTo = navigateTo,

@close_transpose_window+=
vim.api.nvim_win_close(transpose_win, true)

@find_tangle_at_row+=
local start_root = tangled.roots[root].tangled[1]
local end_root = tangled.roots[root].tangled[2]
local tangled_it = start_root
while tangled_it and tangled_it ~= end_root do
  if tangled_it.data.linetype ~= LineType.SENTINEL then
    if tangled_it.data.lnum == row then
      break
    end
  end
  tangled_it = tangled_it.next
end

@find_untangle_origin_and_lnum+=
local origin, lnum
for part in linkedlist.iter(tangled.parts_ll) do
  local part_lnum = 1
  local it = part.start_part
  while it and it ~= part.end_part do
    if it.data.linetype ~= LineType.SENTINEL then
      if it == untangled then
        origin = part.origin
        lnum = part_lnum
        break
      end
      part_lnum = part_lnum + 1
    end
    it = it.next
  end

  if origin then break end
end

@jump_to_linenumber+=
if vim.fn.expand("%:p") ~= origin then
  vim.api.nvim_command("e " .. origin)
end
vim.api.nvim_win_set_cursor(0, {lnum, 0})

@save_current_filetype+=
local ft = vim.api.nvim_buf_get_option(0, "ft")

@setup_transpose_buffer+=
vim.api.nvim_buf_set_option(0, "ft", ft)

@open_context_menu_if_multiple_or_jump_directly+=
assert(jumplines and #jumplines > 0, "Could not find line to jump")
if #jumplines == 1 then
	selected(1)
else
	local options = {}
	for _, jumpline in ipairs(jumplines) do
		table.insert(options, "L" .. jumpline.data.lnum .. " " .. jumpline.data.root)
	end
	contextmenu_open(options, selected)
end
