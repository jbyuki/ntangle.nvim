##../ntangle_main
@functions+=
local function show_assemble()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)
	local assembled = {}

  @collect_all_untangled
  @augment_untangled_with_lnum

  @save_cursor_position
  @save_current_filetype
  create_transpose_buf("Assembly", ft)

  @put_lines_in_assemble_buffer
  @find_current_assemble_line
  @jump_to_lines_in_assemble_buffer

  @build_navigation_lines
  @keymap_assemble_buffer
end

@export_symbols+=
show_assemble = show_assemble,

@put_lines_in_assemble_buffer+=
vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, assembled)

@augment_untangled_with_lnum+=
local lnum = 1
for line in linkedlist.iter(tangled.untangled_ll) do
  if line.linetype ~= LineType.SENTINEL then
    line.lnum = lnum
    lnum = lnum + 1
  end
end

@find_current_assemble_line+=
local start_part, end_part
for part in linkedlist.iter(tangled.parts_ll) do
  if part.origin == buf then
    start_part = part.start_part
    end_part = part.end_part
    break
  end
end

local untangled_it

local it = start_part
local lnum = 1
while it and it ~= end_part do
  local line = it.data
  if line.linetype ~= LineType.SENTINEL then
    if lnum == row then
      untangled_it = it
      break
    end
    lnum = lnum + 1
  end
  it = it.next
end

@jump_to_lines_in_assemble_buffer+=
if untangled_it then
  vim.api.nvim_win_set_cursor(0, {untangled_it.data.lnum, 0})
end

@parse_variables+=
local assemble_nav

@build_navigation_lines+=
assemble_nav = {
  tangled = tangled,
  buf = buf
}


@keymap_assemble_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>u', '<cmd>lua require"ntangle".assembleNavigate()<CR>', {noremap = true})

@functions+=
local function assembleNavigate()
	@save_cursor_position
	@close_transpose_window
	@jump_to_linenumber_assemble
end

@export_symbols+=
assembleNavigate = assembleNavigate,

@jump_to_linenumber_assemble+=
local tangled = assemble_nav.tangled
local buf = assemble_nav.buf

local origin, lnum
for part in linkedlist.iter(tangled.parts_ll) do
  local start_part = part.start_part
  local end_part = part.end_part
  @find_if_cursor_in_part
  if origin then break end
end

if origin ~= buf then
	vim.api.nvim_command("e " .. origin)
end
vim.api.nvim_win_set_cursor(0, {lnum, 0})

@find_if_cursor_in_part+=
local it = start_part.next
local part_lnum = 1
while it and it ~= end_part do
  if it.data.linetype ~= LineType.SENTINEL then
    if it.data.lnum == row then
      origin = part.origin
      lnum = part_lnum
      break
    end
    part_lnum = part_lnum + 1
  end
  it = it.next
end

@collect_all_untangled+=
for line in linkedlist.iter(tangled.untangled_ll) do
  if line.linetype ~= LineType.SENTINEL then
    table.insert(assembled, line.line)
  end
end
