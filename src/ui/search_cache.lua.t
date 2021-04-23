##../ntangle_main
@functions+=
local function search_cache()
  @create_buffer_if_not_existent
  @get_current_window_dimensions
  @create_window_for_transpose
  local border_title = " ntangle cache "
  @create_border_around_transpose_window

  @get_ntangle_cache_location
  @read_ntangle_cache
  @put_ntangle_cache_content_in_buffer

  @attach_enter_keymap_to_jump_to_file
end

@export_symbols+=
search_cache = search_cache,

@get_ntangle_cache_location+=
local filename = vim.g.tangle_cache_file

@parse_variables+=
local cache_jump

@read_ntangle_cache+=
if not cache_jump then
  cache_jump = {}
  for line in io.lines(filename) do
    table.insert(cache_jump, line)
  end
end

@put_ntangle_cache_content_in_buffer+=
vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, true, cache_jump)

@attach_enter_keymap_to_jump_to_file+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<cr>', [[<cmd>lua require"ntangle".jump_cache()<cr>]], { noremap = true })

@functions+=
local function jump_cache()
  @get_current_cursor_line
  @get_selected_cache_entry
  @parse_entry_for_filename_and_section_name
  @close_search_window

  @open_file_and_jump_to_location
end

@export_symbols+=
jump_cache = jump_cache,

@get_current_cursor_line+=
local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

@get_selected_cache_entry+=
local entry = cache_jump[row]

@parse_entry_for_filename_and_section_name+=
local words = vim.split(entry, " ")
local filename = words[#words]
table.remove(words)
local section_name = table.concat(words, "_")

@close_search_window+=
vim.api.nvim_win_close(0, true)

@open_file_and_jump_to_location+=
vim.api.nvim_command("edit " .. filename)
vim.api.nvim_command("call search(\"" .. section_name .. "\")")
