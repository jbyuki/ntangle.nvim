##../ntangle_main
@declare_functions+=
local jump_cache

@functions+=
function jump_cache(cache_file)
  create_transpose_buf()

  @read_cache_file
  @put_read_lines_in_buffer
  @highlight_non_text_filename

  @keymap_jump_refs_buffer
end

@export_symbols+=
jump_cache = jump_cache,

@read_cache_file+=
cache_file = vim.fn.expand(cache_file)
local f = io.open(cache_file)
assert(f, "Could not open " .. cache_file)
f:close()

local lines = {}
for line in io.lines(cache_file) do
  table.insert(lines, line)
end

@put_read_lines_in_buffer+=
vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, true, lines)

@keymap_jump_refs_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<CR>', '<cmd>lua require"ntangle".jump_this_ref()<CR>', {noremap = true})

@declare_functions+=
local jump_this_ref

@export_symbols+=
jump_this_ref = jump_this_ref,

@functions+=
function jump_this_ref()
  @get_current_line
  @parse_filename_and_ref

  @open_filename_in_buffer
  @jump_to_reference
end

@get_current_line+=
local line = vim.api.nvim_get_current_line()

@parse_filename_and_ref+=
local words = vim.split(line, " ")
local fname = words[#words]
table.remove(words)
local ref = table.concat(words, "_")

@open_filename_in_buffer+=
vim.cmd(string.format("e %s", fname))
print(fname)

@jump_to_reference+=
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
local row
for lnum, line in ipairs(lines) do
  if line:match("^%@" .. ref .. "%+%=") then
    row = lnum
    break
  end
end

if row then
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end

@highlight_non_text_filename+=
local ns = vim.api.nvim_create_namespace("")
for lnum, line in ipairs(lines) do
  local words = vim.split(line, " ")
  local fname = words[#words]
  local len = string.len(fname)
  local total_len = string.len(line)

  vim.api.nvim_buf_set_extmark(transpose_buf, ns, lnum-1, total_len-len-1, {
    end_col = total_len,
    hl_group = "NonText",
  })
end
