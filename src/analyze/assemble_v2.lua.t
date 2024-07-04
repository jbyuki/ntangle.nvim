##../ntangle_main
@functions+=
local function show_assemble_v2()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines_v2(buf, lines)
	local assembled = {}

  @collect_all_untangled
  @augment_untangled_with_lnum

  @save_cursor_position
  @save_current_filetype
  create_transpose_buf()

  @put_lines_in_assemble_buffer
  @find_current_assemble_line
  @jump_to_lines_in_assemble_buffer

  @build_navigation_lines
  @keymap_assemble_buffer
  @move_cursor_to_show_window
end

@export_symbols+=
show_assemble_v2 = show_assemble_v2,
