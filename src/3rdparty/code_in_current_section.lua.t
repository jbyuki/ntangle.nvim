##../ntangle_main
@functions+=
local function get_code_at_cursor()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  @augment_untangled_with_lnum_for_current_buffer
  @get_current_section
  @get_tangled_code_for_range
  return code
end

@export_symbols+=
get_code_at_cursor = get_code_at_cursor,

@get_current_section+=
local row, col = unpack(vim.api.nvim_win_get_cursor(0))
local start_code, end_code

local it = start_part
while it and it ~= end_part do
  local line = it.data
  if line.linetype == LineType.SECTION and line.tangled[1] then
    it = it.next
    @find_end_part
    tangled_line = it.prev.data
    if tangled_line.lnum > row and tangled_line.tangled[1] then
      start_code = line.tangled[1]
      end_code = tangled_line.tangled[1]
      break
    end
  else
    it = it.next
  end
end

if not start_code or not end_code then
  start_code = tangled.tangled_ll.head
  end_code = nil
end

@find_end_part+=
local tangled_line = it.data
while it and it ~= end_part do
  tangled_line = it.data
  if tangled_line.linetype == LineType.SECTION then
    break
  end
  it = it.next
end

@get_tangled_code_for_range+=
local code = {}
local it = start_code
local prefix
while it and it.prev and it.prev ~= end_code do 
  local line = it.data
  if line.linetype == LineType.TANGLED and line.str then
    @compute_prefix_if_first_line
    @remove_prefix_for_line
    table.insert(code, txt)
  end
  it = it.next
end

@compute_prefix_if_first_line+=
if #code == 0 then
  prefix = string.match(line.str, "^%s*"):len()
end

@remove_prefix_for_line+=
local txt = line.str:sub(prefix+1)

@functions+=
local function get_code_at_vrange()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  @augment_untangled_with_lnum_for_current_buffer
  @get_visual_range
  @get_visual_range_in_untangled
  @get_tangled_code_for_range
  return code
end

@export_symbols+=
get_code_at_vrange = get_code_at_vrange,

@get_visual_range+=
local _,slnum,sbyte,vscol = unpack(vim.fn.getpos("'<"))
local _,elnum,ebyte,vecol = unpack(vim.fn.getpos("'>"))

@get_visual_range_in_untangled+=
local it = start_part
local start_code, end_code

while it and it ~= end_part do
  local line = it.data
  if line.lnum and line.tangled[1] then
    if line.lnum == slnum then
      start_code = line.tangled[1]
    end

    if line.lnum == elnum+1 then
      end_code = line.tangled[1]
    end
  end
  it = it.next
end
