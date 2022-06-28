##../ntangle_main
@functions+=
local function highlight_span()
  @get_word_under_cursor

  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  @augment_tangled_with_lnum_for_current_buffer

  @clear_highlight_namespace_for_span

  local sections_ll = tangled.sections_ll 

  local highlight_all
  highlight_all = function(name, stack)
    if not sections_ll[name] then
      return
    end

    for it in linkedlist.iter(sections_ll[name]) do
      @highlight_every_line_in_section_part
    end
  end

  if searched then
    local stack = {}
    table.insert(stack, searched)
    highlight_all(searched, stack)
  end

  @highlight_current_line

  @attach_enter_keymap_once_to_clear_highlight
end

@export_symbols+=
highlight_span = highlight_span,

@augment_tangled_with_lnum_for_current_buffer+=
local start_part, end_part
for part in linkedlist.iter(tangled.parts_ll) do
  if part.origin == buf then
    start_part = part.start_part
    end_part = part.end_part
    break
  end
end

local it = start_part
local lnum = 1
while it and it ~= end_part do
  local line = it.data
  if line.linetype ~= LineType.SENTINEL then
    line.lnum = lnum
    lnum = lnum + 1
  end
  it = it.next
end


@highlight_every_line_in_section_part+=
local next_section = false
while it do
  local line = it.data
  if line.linetype ~= LineType.SENTINEL then
    if line.linetype == LineType.SECTION then
      if next_section then
        break
      else
        next_section = true
      end
    end

    if line.lnum then
      @highlight_current_line_span
    end

    if line.linetype == LineType.REFERENCE then
      @highlight_recurse_on_reference
    end
  end
  it = it.next
end

@highlight_current_line_span+=
local len = string.len(line.line)
vim.api.nvim_buf_set_extmark(0, span_ns, line.lnum-1, 0, { hl_group = "IncSearch",
end_col = len
})

@highlight_recurse_on_reference+=
if not vim.tbl_contains(stack, line.str) then
  table.insert(stack, line.str)
  highlight_all(line.str, stack)
  table.remove(stack)
end

@parse_variables+=
local span_ns = vim.api.nvim_create_namespace("")

@clear_highlight_namespace_for_span+=
vim.api.nvim_buf_clear_namespace(0, span_ns, 0, -1)

@get_word_under_cursor+=
local searched = vim.fn.expand("<cword>")

@parse_variables+=
local clear_highlight_span
local highlighted = {}

@attach_enter_keymap_once_to_clear_highlight+=
highlighted[buf] = true
vim.api.nvim_buf_set_keymap(0, "n", "<CR>", [[:lua require"ntangle".clear_highlight_span()<CR>]], { noremap = true, silent = true })

@functions+=
function clear_highlight_span()
  local buf = vim.fn.expand("%:p")
  if highlighted[buf] then
    @clear_highlight_namespace_for_span
    vim.api.nvim_buf_del_keymap(0, "n", "<CR>")
    highlighted[buf] = nil
  end
end

@export_symbols+=
clear_highlight_span = clear_highlight_span,

@highlight_current_line+=
local line = vim.api.nvim_get_current_line()
local len = string.len(line)
local row, col = unpack(vim.api.nvim_win_get_cursor(0))
vim.api.nvim_buf_set_extmark(0, span_ns, row-1, 0, { 
  hl_group = "IncSearch",
  end_col = len
})
