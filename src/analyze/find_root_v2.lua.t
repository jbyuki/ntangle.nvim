##../ntangle_main
@functions+=
local function getRootFilename_v2()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines_v2(buf, lines)

  local roots = {}
  for name, root in pairs(tangled.roots) do
    table.insert(roots, get_origin_v2(buf, tangled.asm, name))
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
getRootFilename_v2 = getRootFilename_v2,
