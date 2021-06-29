##../ntangle_main
@functions+=
local function show_helper()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

	local qflist = {}
	@search_undefined_sections
	@search_ophan_sections

  @output_undefined_section_references
  @output_orphan_sections

	@if_no_text_to_display_add_some_info_text
	@compute_max_width_for_helper_window
	@create_float_window_for_helper
	@put_text_in_helper_window
  @attach_virtual_text_helper_window
	@attach_autocommand_to_close_helper_on_movement

  @create_undefined_section_highlight_namespace
  @highlight_all_undefined_reference_in_current_buffer
  @attach_autocommand_to_clear_highlight_on_movement
end

@export_symbols+=
show_helper = show_helper,

@search_undefined_sections+=
local undefined_section = {}
for line in linkedlist.iter(tangled.untangled_ll) do
  if line.linetype == LineType.REFERENCE then
    if not line.tangled or #line.tangled == 0 then
      undefined_section[line.str] = true
    end
  end
end

@search_ophan_sections+=
local orphan_section = {}
for line in linkedlist.iter(tangled.untangled_ll) do
  if line.linetype == LineType.SECTION then
    if not line.tangled or #line.tangled == 0 then
      orphan_section[line.str] = true
    end
  end
end

@output_undefined_section_references+=
for name, _ in pairs(undefined_section) do
	table.insert(qflist, { name:gsub("_", " "), " is empty" } )
end

@output_orphan_sections+=
for name, _ in pairs(orphan_section) do
	table.insert(qflist, { name:gsub("_", " ") , " orphan section" })
end

@compute_max_width_for_helper_window+=
local max_width = 0
for _, line in ipairs(qflist) do
	max_width = math.max(max_width, vim.api.nvim_strwidth(line[1] .. " " .. line[2]) + 2)
end

@create_float_window_for_helper+=
local buf = vim.api.nvim_create_buf(false, true)
local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

local MAX_WIDTH = 60
local MAX_HEIGHT = 15

local popup = {
	width = math.min(max_width, MAX_WIDTH),
	height = math.min(#qflist, MAX_HEIGHT),
	margin_up = 3,
	margin_right = 6,
}

local opts = {
	relative = "win",
	win = vim.api.nvim_get_current_win(),
	width = popup.width,
	height = popup.height,
	col = w - popup.width - popup.margin_right,
	row =  popup.margin_up,
	style = 'minimal',
  border = 'single',
}

local win = vim.api.nvim_open_win(buf, false, opts)

@create_float_window_for_helper+=
vim.api.nvim_win_set_option(win, "winblend", 30)

@put_text_in_helper_window+=
local newlines = {}
for _, p in ipairs(qflist) do
  table.insert(newlines, p[1])
end

vim.api.nvim_buf_set_lines(buf, 0, -1, true, newlines)

@declare_functions+=
local close_preview_autocmd

@functions+=
function close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

@attach_autocommand_to_close_helper_on_movement+=
close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)

@if_no_text_to_display_add_some_info_text+=
if #qflist == 0 then
	table.insert(qflist, { "  No warnings :)  ", "" })
end

@attach_virtual_text_helper_window+=
local ns_id = vim.api.nvim_create_namespace("")
for lnum, p in ipairs(qflist) do
  vim.api.nvim_buf_set_extmark(buf, ns_id, lnum-1, 0, {
    virt_text = {{ p[2], "NonText"}}
  })
  table.insert(newlines, p[1])
end

@parse_variables+=
local undefined_ns

@create_undefined_section_highlight_namespace+=
undefined_ns = vim.api.nvim_create_namespace("")

@highlight_all_undefined_reference_in_current_buffer+=
for lnum, line in ipairs(lines) do
  for name, _ in pairs(undefined_section) do
    local s1, s2 = line:find("@" .. name .. "$")
    if s1 then
      @put_higlight_on_undefined_reference
    end
  end
end

@put_higlight_on_undefined_reference+=
vim.api.nvim_buf_set_extmark(0, undefined_ns, lnum-1, s1-1, {
  hl_group = "IncSearch",
  end_col = s2
})

@declare_functions+=
local clear_highlight_autocmd

@functions+=
function clear_highlight_autocmd(events, ns)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_buf_clear_namespace, 0, "..ns..", 0, -1)")
end

@attach_autocommand_to_clear_highlight_on_movement+=
clear_highlight_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, undefined_ns)
