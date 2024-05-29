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
  @augment_tangled_with_lnum_v2
  @fill_jumplines

	local selected = function(row) 
		local jumpline = jumplines[row]

    create_transpose_buf()

		@put_lines_in_buffer_v2
		@keymap_transpose_buffer

    @save_lines_for_navigation
		@jump_to_lines_in_transpose_buffer
	end

	@open_context_menu_if_multiple_or_jump_directly
end

@export_symbols+=
transpose_v2 = transpose_v2,

@augment_tangled_with_lnum_v2+=
for name, root in pairs(tangled.roots) do
  local lnum = 1
  local lines = {}
  local fn = get_origin_v2(buf, tangled.asm, name)
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

@put_lines_in_buffer_v2+=
local transpose_lines = {}

local lines = {}
local fn = get_origin_v2(buf, tangled.asm, jumpline.data.root)
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
