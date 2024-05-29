##../ntangle_main
@functions+=
local function show_helper_v2()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines_v2(buf, lines)

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
  @highlight_all_undefined_reference_in_current_buffer_v2
  @attach_autocommand_to_clear_highlight_on_movement
end

@export_symbols+=
show_helper_v2 = show_helper_v2,

@highlight_all_undefined_reference_in_current_buffer_v2+=
for lnum, line in ipairs(lines) do
  for name, _ in pairs(undefined_section) do
    local s1, s2 = line:find("^%s*;%s*" .. name .. "%s*$")
    if s1 then
      @put_higlight_on_undefined_reference
    end
  end
end
