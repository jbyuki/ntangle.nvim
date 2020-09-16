@*=
@copy_files

@copy_files+=
local plugvim = io.open("../plugin/ntangle.vim", "w")
for line in io.lines("tangle/ntangle.vim") do
	plugvim:write(line .. '\n')
end
plugvim:close()

local pluglua = io.open("../lua/ntangle.lua", "w")
for line in io.lines("tangle/ntangle.lua") do
	pluglua:write(line .. '\n')
end
pluglua:close()

local plugsyntax = io.open("../syntax/ntangle.vim", "w")
for line in io.lines("tangle/syntax.vim") do
	plugsyntax:write(line .. '\n')
end
plugsyntax:close()

local linkedlist = io.open("../lua/linkedlist.lua", "w")
for line in io.lines("tangle/linkedlist.lua") do
	linkedlist:write(line .. '\n')
end
linkedlist:close()

local buildcache = io.open("../lua/buildcache.lua", "w")
for line in io.lines("tangle/buildcache.lua") do
	buildcache:write(line .. '\n')
end
buildcache:close()
