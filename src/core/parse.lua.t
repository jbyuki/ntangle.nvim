##../ntangle_main
@define_parse+=
local function parse(origin, lines, it)
  for lnum, line in ipairs(lines) do
    @if_line_is_double_at
    @if_line_is_section
    @if_line_is_reference
    @if_line_is_assembly
    @otherwise_line_is_text
  end
end

@if_line_is_double_at+=
if string.match(line, "^%s*@@") then
  @create_text_line_without_at
  @add_line_to_untangled

@if_line_is_section+=
elseif string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	@create_new_section_line
  @add_line_to_untangled
  @add_ref_to_sections
  @if_root_section_add_ref

@if_line_is_reference+=
elseif string.match(line, "^%s*@[^@]%S*%s*$") then
  @get_reference_name
	@create_line_reference
  @add_line_to_untangled

@if_line_is_assembly+=
elseif string.match(line, "^##%S*%s*$") then
  @create_assembly_line
  @add_line_to_untangled

@otherwise_line_is_text+=
else
	@create_text_line
  @add_line_to_untangled
end

@create_text_line_without_at+=
local _,_,pre,post = string.find(line, '^(.*)@@(.*)$')
local text = pre .. "@" .. post
local l = { 
	linetype = LineType.TEXT, 
  line = line,
	str = text 
}

@parse_variables+=
local LineType = {
	@line_types
}

@export_symbols+=
LineType = LineType,

@line_types+=
ASSEMBLY = 5,

@create_assembly_line+=
local l = {
  linetype = LineType.ASSEMBLY,
  line = line,
  str = asm,
}

@get_reference_name+=
local _, _, prefix, name = string.find(line, "^(%s*)@(%S+)%s*$")

@line_types+=
REFERENCE = 1,

@create_line_reference+=
local l = { 
	linetype = LineType.REFERENCE, 
	str = name,
  line = line,
	prefix = prefix
}

@line_types+=
TEXT = 2,

@create_text_line+=
local l = { 
	linetype = LineType.TEXT, 
  line = line,
	str = line 
}

@add_line_to_untangled+=
it = linkedlist.insert_after(untangled_ll, it, l)

@line_types+=
SECTION = 3,

@parse_section_name+=
local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")

@create_new_section_line+=
local l = {
  linetype = LineType.SECTION,
  str = name,
  line = line,
  op = op,
}

@tangle_variables+=
local sections_ll = {}

@add_ref_to_sections+=
sections_ll[name] = sections_ll[name] or {}
linkedlist.push_back(sections_ll[name], it)

@return_tangle+=
sections_ll = sections_ll,

@tangle_variables+=
local roots = {}

@if_root_section_add_ref+=
if op == "=" then 
  roots[name] = {
    untangled = it,
    origin = origin,
  }
end
