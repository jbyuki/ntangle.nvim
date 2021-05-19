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
print("Checking generated.lua 2")

assert(#lines == 3, "generated.lua is invalid")

local f = io.open("result.txt", "w")
f:write("OK")
f:close()
vim.loop.fs_rmdir("testtangle")


