-- Generated using ntangle.nvim
vim.loop.fs_mkdir("testtangle", 448)

local f = io.open("testtangle/test.lua.t", "w")
f:write("##test" .. "\n")
f:write("@generated.lua=" .. "\n")
f:write("print('hello')")
f:close()

require"ntangle".tangle_all("testtangle/")

local lines = {}
for line in io.lines("testtangle/tangle/generated.lua") do
  table.insert(lines, line)
end

local fail = false
print("Checking generated.lua")

if #lines ~= 3 then
  fail = true
end

if fail then
  print("FAIL")
else
  print("OK")
end
vim.loop.fs_rmdir("testtangle")


