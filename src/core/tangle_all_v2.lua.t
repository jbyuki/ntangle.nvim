##../ntangle_main
@declare_functions+=
local tangle_all_v2

@functions+=
function tangle_all_v2(path)
  @glob_all_tangle_files_v2
  -- kind of ugly but works
  -- first pass to write link files
  for i=1,2 do
    for _, file in ipairs(files) do
      @read_lines_from_file
      -- skip link files
      if #lines > 1 then 
        tangle_write_v2(vim.fn.fnamemodify(file, ":p"), lines)
      end
    end
  end
end

@glob_all_tangle_files_v2+=
local files = vim.split(vim.fn.glob((path or "") .. "**/*.t2"), "\n")

@read_lines_from_file+=
local lines = {}
for line in io.lines(file) do
  table.insert(lines, line)
end

@export_symbols+=
tangle_all_v2 = tangle_all_v2,
