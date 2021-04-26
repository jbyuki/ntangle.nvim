##../ntangle_main
@declare_functions+=
local tangle_buf
local tangle_lines
local tangle_write

@functions+=
function tangle_buf()
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  tangle_write(filename, lines)
end

function tangle_write(filename, lines)
  local tangled = tangle_lines(filename, lines)

  for name, root in pairs(tangled.roots) do
    local fn = get_origin(filename, tangled.asm, name)

    local lines = {}
    @output_ntangle_header
    @collect_tangled_lines

    @check_file_is_modified
    @if_modified_write_file
  end
end

function tangle_lines(filename, lines)
  @tangle_variables

  @if_first_line_is_assembly_add_parts
  @otherwise_only_add_current_part

  @define_parse
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

@if_star_replace_with_current_filename+=
if name == "*" then
	local tail = vim.fn.fnamemodify(filename, ":t:r" )
	fn = parendir .. "/tangle/" .. tail

@otherwise_put_node_name+=
else
	if string.find(name, "/") then
		fn = parendir .. "/" .. name
	else
		fn = parendir .. "/tangle/" .. name
	end
end

@tangle_variables+=
local asm

@if_first_line_is_assembly_add_parts+=
if string.match(lines[1], "^##%S*%s*$") then
  local line = lines[1]
	@extract_assembly_name
  asm = name
  local curassembly = asm
  @construct_path_for_link_file
  @get_assembly_folder
  @write_link_file
  @glob_all_part_links
  @foreach_part_append_info

@otherwise_only_add_current_part+=
else
  @add_current_part_info
end

@construct_path_for_link_file+=
local fn = filename or vim.api.nvim_buf_get_name(0)
fn = vim.fn.fnamemodify(fn, ":p")
local parendir = vim.fn.fnamemodify(fn, ":p:h")
local assembly_parendir = vim.fn.fnamemodify(curassembly, ":h")
local assembly_tail = vim.fn.fnamemodify(curassembly, ":t")
@build_part_tail
local link_name = parendir .. "/" .. assembly_parendir .. "/tangle/" .. assembly_tail .. "." .. part_tail
local path = vim.fn.fnamemodify(link_name, ":h")
@create_directory_if_non_existent

@build_part_tail+=
local part_tails = {}
local copy_fn = fn
local copy_curassembly = curassembly
while true do
  local part_tail = vim.fn.fnamemodify(copy_fn, ":t")
  table.insert(part_tails, 1, part_tail)
  copy_fn = vim.fn.fnamemodify(copy_fn, ":h")

  copy_curassembly = vim.fn.fnamemodify(copy_curassembly, ":h")
  if copy_curassembly == "." then
    break
  end
  if copy_curassembly ~= ".." and vim.fn.fnamemodify(copy_curassembly, ":h") ~= ".." then
    error("Assembly can't be in a subdirectory (it must be either in parent or same directory")
  end
end
local part_tail = table.concat(part_tails, ".")

@create_directory_if_non_existent+=
if vim.fn.isdirectory(path) == 0 then
	-- "p" means create also subdirectories
	vim.fn.mkdir(path, "p") 
end

@write_link_file+=
local link_file = io.open(link_name, "w")
link_file:write(fn)
link_file:close()


@extract_assembly_name+=
local name = string.match(line, "^##(%S*)%s*$")

@get_assembly_folder+=
local asm_folder = vim.fn.fnamemodify(filename, ":p:h") .. "/" .. assembly_parendir .. "/tangle/"

@glob_all_part_links+=
local asm_tail = vim.fn.fnamemodify(asm, ":t")
local parts = vim.split(vim.fn.glob(asm_folder .. asm_tail .. ".*.t"), "\n")

@foreach_part_append_info+=
for _, part in ipairs(parts) do
  @read_origin_path
  @place_sentinels_in_untangled
  @append_part_to_parts_ll
end

@read_origin_path+=
local origin
local f = io.open(part, "r")
if f then
  origin = f:read("*line")
  f:close()
end

@line_types+=
SENTINEL = 4,

@tangle_variables+=
local untangled_ll = {}

@place_sentinels_in_untangled+=
local start_part, end_part
if origin then
  start_part = linkedlist.push_back(untangled_ll, {
    linetype = LineType.SENTINEL,
    str = origin
  })

  end_part = linkedlist.push_back(untangled_ll, {
    linetype = LineType.SENTINEL,
    str = origin
  })
end

@tangle_variables+=
local parts_ll = {}

@append_part_to_parts_ll+=
if origin then
  linkedlist.push_back(parts_ll, {
    start_part = start_part,
    end_part = end_part,
    origin = origin,
  })
end

@add_current_part_info+=
local origin = filename
@place_sentinels_in_untangled
@append_part_to_parts_ll

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

@export_symbols+=
tangle_buf = tangle_buf,
tangle_lines = tangle_lines,

@parse_foreach_part+=
for part in linkedlist.iter(parts_ll) do
  local part_lines
  if part.origin == filename then
    part_lines = lines
  else
    @read_part_lines
  end
  parse(part.origin, part_lines, part.start_part)
end

@read_part_lines+=
part_lines = {}
local f = io.open(part.origin, "r")
if f then
  while true do
    local line = f:read("*line")
    if not line then break end
    table.insert(part_lines, line)
  end
  f:close()
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
if name == nil then
	print(line)
end

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

@tangle_variables+=
local roots = {}

@if_root_section_add_ref+=
if op == "=" then 
  roots[name] = {
    untangled = it,
    origin = origin,
  }
end

@tangle_variables+=
local tangled_ll = {}

@tangle_current_root_section+=
local start_root, end_root = tangle_rec(name, tangled_it, "")
roots[name].tangled = { start_root, end_root }
tangled_it = end_root

@if_untangled_is_section_break+=
if line.linetype == LineType.SECTION then
  break

@if_untangled_is_reference+=
elseif line.linetype == LineType.REFERENCE then
  @recursively_tangle_reference

@define_tangle+=
local function tangle_rec(name, tangled_it, prefix)
  @if_no_section_return
  @add_section_sentinel_tangled
  for ref in linkedlist.iter(sections_ll[name]) do
    local it = ref.next
    @set_tangled_it_depending_on_section_op
    @add_tangled_to_section
    while it do
      local line = it.data
      @if_untangled_is_section_break
      @if_untangled_is_reference
      @if_untangled_is_assembly_break
      @otherwise_untangled_is_text

      it = it.next
    end
  end
  return start_section, end_section
end

@if_no_section_return+=
if not sections_ll[name] then
  return nil, tangled_it
end

@recursively_tangle_reference+=
local start_ref
start_ref, tangled_it = tangle_rec(line.str, tangled_it, prefix .. line.prefix)
line.tangled = line.tangled or {}
table.insert(line.tangled, start_ref)

@add_section_sentinel_tangled+=
local start_section = linkedlist.insert_after(tangled_ll, tangled_it, {
  linetype = LineType.SENTINEL,
  str = "START " .. name,
})

local end_section = linkedlist.insert_after(tangled_ll,  start_section, {
  linetype = LineType.SENTINEL,
  str = "END " .. name,
})

@set_tangled_it_depending_on_section_op+=
local tangled_it
if ref.data.op == "+=" then
  tangled_it = end_section.prev
elseif ref.data.op == "-=" then
  tangled_it = start_section
elseif ref.data.op == "=" then
  tangled_it = start_section
end

@add_tangled_to_section+=
ref.data.tangled = ref.data.tangled or {}
table.insert(ref.data.tangled, tangled_it)

@if_untangled_is_assembly_break+=
elseif line.linetype == LineType.ASSEMBLY then
  break

@line_types+=
TANGLED = 6,

@otherwise_untangled_is_text+=
elseif line.linetype == LineType.TEXT then
  local l = {
    linetype = LineType.TANGLED,
    str = prefix .. line.str,
    untangled = it
  }
  tangled_it = linkedlist.insert_after(tangled_ll, tangled_it, l)
  line.tangled = line.tangled or {}
  table.insert(line.tangled, tangled_it)
end

@return_tangle+=
asm = asm,
roots = roots,
tangled_ll = tangled_ll,
untangled_ll = untangled_ll,

@output_ntangle_header+=
if string.match(fn, "%.lua$") then
	table.insert(lines, "-- Generated using ntangle.nvim")
end

if string.match(fn, "%.vim$") then
	table.insert(lines, "\" Generated using ntangle.nvim")
end

if string.match(fn, "%.cpp$") or string.match(fn, "%.h$") then
	table.insert(lines, "// Generated using ntangle.nvim")
end

@collect_tangled_lines+=
local it = root.tangled[1]
while it and it ~= root.tangled[2] do
  if it.data.linetype == LineType.TANGLED then
    table.insert(lines, it.data.str)
  end
  it = it.next
end

@check_file_is_modified+=
local modified = false
do
	local f = io.open(fn, "r")
	if f then 
		modified = false
		@check_if_every_line_match
		f:close()
	else
		modified = true
	end
end

@check_if_every_line_match+=
local lnum = 1
for line in f:lines() do
	if lnum > #lines then
		modified = true
		break
	end
	if line ~= lines[lnum] then
		modified = true
		break
	end
	lnum = lnum + 1
end

if lnum-1 ~= #lines then
	modified = true
end

@if_modified_write_file+=
if modified then
	local f, err = io.open(fn, "w")
	if f then
		for _,line in ipairs(lines) do
			f:write(line .. "\n")
		end
		f:close()
	else
		print(err)
	end
end

@return_tangle+=
parts_ll = parts_ll,
