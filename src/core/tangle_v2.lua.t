##../ntangle_main
@declare_functions+=
local tangle_buf_v2
local tangle_write_v2
local tangle_lines_v2

@functions+=
function tangle_buf_v2()
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  tangle_write_v2(filename, lines, false)
end

function tangle_write_v2(filename, lines, comment)
  local tangled = tangle_lines_v2(filename, lines, comment)

  for name, root in pairs(tangled.roots) do
    local fn = get_origin(filename, tangled.asm, name)

    local lines = {}
    @output_ntangle_header
    @collect_tangled_lines

    @check_file_is_modified
    @if_modified_write_file
  end
end

function tangle_lines_v2(filename, lines, comment)
  @tangle_variables

  @if_first_line_is_assembly_add_parts_v2
  @otherwise_only_add_current_part

  @define_parse_v2
  @parse_foreach_part

  @define_tangle
  local tangled_it = nil
  for name, ref in pairs(roots) do
    local it = ref.untangled.next
    @tangle_current_root_section
  end

  return {
    @return_tangle
  }
end

@export_symbols+=
tangle_buf_v2 = tangle_buf_v2,
tangle_lines_v2 = tangle_lines_v2,

@if_first_line_is_assembly_add_parts_v2+=
if string.match(lines[1], "^;;;.") then
  local line = lines[1]
	@extract_assembly_name_v2
  asm = name
  local curassembly = asm
  @construct_path_for_link_file
  @get_assembly_folder
  @write_link_file
  @glob_all_part_links_v2
  @foreach_part_append_info

@extract_assembly_name_v2+=
local name = string.match(line, "^;;;(.+)$")
name = vim.trim(name)

@glob_all_part_links_v2+=
local asm_tail = vim.fn.fnamemodify(asm, ":t")
local parts = vim.split(vim.fn.glob(asm_folder .. asm_tail .. ".*.t2"), "\n")

@define_parse_v2+=
local function parse(origin, lines, it)
  for lnum, line in ipairs(lines) do
    @if_line_is_section_v2
		@if_line_is_root_section_v2
    @if_line_is_reference_v2
    @if_line_is_assembly_v2
    @otherwise_line_is_text
  end
end

@if_line_is_section_v2+=
if string.match(line, "^;;[^;]") then
	@parse_section_name_v2
	@create_new_section_line
  @add_line_to_untangled
  @add_ref_to_sections

@parse_section_name_v2+=
local _, _, name = string.find(line, "^;;(.+)$")
name = vim.trim(name)
local op = "+="

@if_line_is_root_section_v2+=
elseif string.match(line, "^::[^:]") then
	@parse_root_section_name_v2
	@create_new_section_line
  @add_line_to_untangled
  @add_ref_to_sections
  @if_root_section_add_ref

@parse_root_section_name_v2+=
local _, _, name = string.find(line, "^::(.+)$")
name = vim.trim(name)
local op = "="

@if_line_is_reference_v2+=
elseif string.match(line, "^%s*;[^;]") then
  @get_reference_name_v2
	@create_line_reference
  @add_line_to_untangled

@get_reference_name_v2+=
local _, _, prefix, name = string.find(line, "^(%s*);(.+)$")
name = vim.trim(name)

@if_line_is_assembly_v2+=
elseif string.match(line, "^;;;") then
  @create_assembly_line
  @add_line_to_untangled
