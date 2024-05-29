##../ntangle_main
@functions+=
local function transpose_v2()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines_v2(buf, lines)
	local assembled = {}

	@save_cursor_position
	@save_current_filetype

  local jumplines = {}
  @augment_tangled_with_lnum
  @fill_jumplines

	local selected = function(row) 
		local jumpline = jumplines[row]

    create_transpose_buf()

		@put_lines_in_buffer
		@keymap_transpose_buffer

    @save_lines_for_navigation
		@jump_to_lines_in_transpose_buffer
	end

	@open_context_menu_if_multiple_or_jump_directly
end

@export_symbols+=
transpose_v2 = transpose_v2,
