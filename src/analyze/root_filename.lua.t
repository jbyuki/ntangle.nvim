##../ntangle_main
@declare_functions+=
local get_origin

@functions+=
function get_origin(filename, asm, name)
  local curassembly = asm
  @construct_path_for_link_file

  local parendir = vim.fn.fnamemodify(filename, ":p:h" ) .. "/" .. assembly_parendir

  local fn
  @if_star_replace_with_current_filename
  @otherwise_put_node_name
  return fn
end
