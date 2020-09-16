local function build(filename)
	local tangle_code_dir = "~/fakeroot/code"
	local filelist = vim.api.nvim_call_function("glob", { tangle_code_dir .. "/**/*.tl" })
	
	local globalcache = {}
	
	for file in vim.gsplit(filelist, "\n") do
		local filerefs = {}
		
		for line in io.lines(file) do
			if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
				local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
				
				filerefs[name] = true
				
			end
			
		end
		
		globalcache[file] = filerefs
		
	end
	
	local cache = io.open(filename, "w")
	for file, filerefs in pairs(globalcache) do
		for name,_ in pairs(filerefs) do
			local name_words = string.gsub(name, "_+", " ")
			cache:write(name_words .. " " .. file .. "\n")
		end
	end
	cache:close()
	print("Cache written to " .. filename .. " !")
end

return {
build = build,

}

