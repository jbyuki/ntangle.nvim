##../ntangle_main
@add_comment_if_enabled+=
if comment then
  local l = {
    linetype = LineType.TANGLED,
    str = prefix .. line.prefix .. generate_comment(root_name,  line.str),
    untangled = nil,
  }
  tangled_it = linkedlist.insert_after(tangled_ll, tangled_it, l)
end

@declare_functions+=
local generate_comment

@functions+=
function generate_comment(root_name, line)
  -- Taken from http://lua-users.org/wiki/StringRecipes
  title_case = line:gsub("_", " ")
  title_case = title_case:gsub("^(%a)", string.upper)
  if string.match(root_name, "%.py$") then
    return ("# %s"):format(title_case)
  end
end

@declare_functions+=
local tangle_buf_with_comments

@functions+=
function tangle_buf_with_comments()
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  tangle_write(filename, lines, true)
end

@export_symbols+=
tangle_buf_with_comments = tangle_buf_with_comments, 
