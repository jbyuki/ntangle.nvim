##../ntangle_main
@functions+=
local function get_code_at_cursor()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  @augment_tangled_with_lnum_for_current_buffer
  @get_current_section
  @get_code_for_section
  return code
end

@export_symbols+=
get_code_at_cursor = get_code_at_cursor,

@get_current_section+=
local row, col = unpack(vim.api.nvim_win_get_cursor(0))

local it = start_part
local section_name 
while it and it ~= end_part do
  local line = it.data
  if line.linetype == LineType.SECTION then
    section_name = line.str
  end

  if line.lnum and line.lnum >= row then
    break
  end
  it = it.next
end

@get_code_for_section+=
local code = {}

for line in linkedlist.iter(tangled.untangled_ll) do
  if line.linetype == LineType.REFERENCE and line.str == section_name then
    assert(line.tangled)
    for i=1,#line.tangled do
      @add_code_for_current_tangled_section
    end
    break
  end
end

@add_code_for_current_tangled_section+=
local it = line.tangled[i][1]
local it_end = line.tangled[i][2]
while it ~= it_end do
  local tangle_line = it.data
  if tangle_line.linetype == LineType.TANGLED then
    local text = tangle_line.str
    @remove_prefix
    table.insert(code, text)
  end
  it = it.next
end

@remove_prefix+=
local prefix_len = #line.prefix
text = text:sub(1+prefix_len)
