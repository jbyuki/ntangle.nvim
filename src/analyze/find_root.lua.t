##../ntangle_main
@functions+=
local function getRootFilename()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  local roots = {}
  for name, root in pairs(tangled.roots) do
    table.insert(roots, get_origin(buf, tangled.asm, name))
  end

  if #roots == 0 then
    print("No root found!")
  end

  if #roots > 1 then
    print("multiple roots !")
  end

	return roots[1]
end

@export_symbols+=
getRootFilename = getRootFilename,
