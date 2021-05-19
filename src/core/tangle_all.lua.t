##../ntangle_main
@declare_functions+=
local tangle_all

@functions+=
function tangle_all(path)
  @glob_all_tangle_files
  -- kind of ugly but works
  -- first pass to write link files
  for i=1,2 do
    for _, file in ipairs(files) do
      @read_lines_from_file
      -- skip link files
      if #lines > 1 then 
        tangle_write(vim.fn.fnamemodify(file, ":p"), lines)
      end
    end
  end
end

@glob_all_tangle_files+=
local files = vim.split(vim.fn.glob((path or "") .. "**/*.t"), "\n")

@read_lines_from_file+=
local lines = {}
for line in io.lines(file) do
  table.insert(lines, line)
end

@export_symbols+=
tangle_all = tangle_all,
