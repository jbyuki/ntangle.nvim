##../ntangle_test
@../test/test.lua=
@create_test_directory
@create_test_tangle_file
@tangle_all
@read_generated_file
local fail = false
@check_generated_content
@print_test_result
@remove_test_directory

@create_test_directory+=
vim.loop.fs_mkdir("testtangle", 448)

@remove_test_directory+=
vim.loop.fs_rmdir("testtangle")

@create_test_tangle_file+=
local f = io.open("testtangle/test.lua.t", "w")
f:write("##test" .. "\n")
f:write("@generated.lua=" .. "\n")
f:write("print('hello')")
f:close()

@tangle_all+=
require"ntangle".tangle_all("testtangle/")

@read_generated_file+=
local lines = {}
for line in io.lines("testtangle/tangle/generated.lua") do
  table.insert(lines, line)
end

@check_generated_content+=
print("Checking generated.lua 2")

if #lines ~= 3 then
  fail = true
end

@print_test_result+=
local f = io.open("result.txt")
if fail then
  f:write("FAIL")
  print("FAIL")
else
  f:write("OK")
  print("OK")
end
f:close()
