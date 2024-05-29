##../ntangle_main
@declare_functions+=
local get_origin_v2

@functions+=
function get_origin_v2(filename, asm, name)
  local curassembly = asm
  @construct_path_for_link_file_v2

  local parendir = vim.fn.fnamemodify(filename, ":p:h" ) .. "/" .. assembly_parendir

  local fn
  @if_star_replace_with_current_filename_v2
  @otherwise_put_node_name_v2
  return fn
end

@export_symbols+=
get_origin_v2 = get_origin_v2,

@if_star_replace_with_current_filename_v2+=
if name == "*" then
	local tail = vim.fn.fnamemodify(filename, ":t:r" )
	fn = parendir .. "/.ntangle/" .. tail

@otherwise_put_node_name_v2+=
else
	if string.find(name, "/") then
		fn = parendir .. "/" .. name
	else
		fn = parendir .. "/.ntangle/" .. name
	end
end
