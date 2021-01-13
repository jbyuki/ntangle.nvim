-- Generated from  using ntangle.nvim
local outputSections

local function tangle(filename)
	local curassembly
	local lines = {}
	if filename then
		for line in io.open(lines) do
			table.insert(lines, line)
		end
		
	else
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		
	end

	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		local parendir = vim.fn.fnamemodify(fn, ":p:h")
		local assembly_parendir = vim.fn.fnamemodify(curassembly, ":h")
		local assembly_tail = vim.fn.fnamemodify(curassembly, ":t")
		local part_tail = vim.fn.fnamemodify(fn, ":t")
		local link_name = parendir .. "/" .. assembly_parendir .. "/tangle/" .. assembly_tail .. "." .. part_tail
		local path = vim.fn.fnamemodify(link_name, ":h")
		if vim.fn.isdirectory(path) == 0 then
			-- "p" means create also subdirectories
			vim.fn.mkdir(path, "p") 
		end
		
		
		local link_file = io.open(link_name, "w")
		link_file:write(fn)
		link_file:close()
		
		
		
		local assembled = {}
		local valid_parts = {}
		
		local offset = {}
		
		local origin = {}
		
		path = vim.fn.fnamemodify(path, ":p")
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					local buffer = f:read("*all")
					f:close()
					
					buffer = vim.split(buffer, "\n")
					table.remove(buffer, 1)
					offset[origin_path] = #assembled
					
					for lnum, line in ipairs(buffer) do
						table.insert(assembled, line)
						table.insert(origin, origin_path)
						
					end
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
			end
		end
		
		offset[fn] = #assembled
		
		for lnum, line in ipairs(lines) do
			if lnum > 1 then
				table.insert(assembled, line)
				table.insert(origin, fn)
				
			end
		end
		
		local lines = assembled 
		local ext = vim.fn.fnamemodify(fn, ":e:e")
		local filename = parendir .. "/" .. assembly_parendir .. "/" .. assembly_tail .. "." .. ext
		

		parse(lines)
		
		local parendir = vim.fn.fnamemodify(filename, ":p:h" )
		for name, section in pairs(sections) do
			if section.root then
				local fn
				if name == "*" then
					local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
					fn = parendir .. "/tangle/" .. tail
				
				else
					fn = parendir .. "/" .. name
				end
				
				lines = {}
				if string.match(fn, "lua$") then
					table.insert(lines, "-- Generated from " .. table.concat(valid_parts, ", ") .. " using ntangle.nvim")
				elseif string.match(fn, "vim$") then
					table.insert(lines, "\" Generated from " .. table.concat(valid_parts, ", ") .. " using ntangle.nvim")
				end
				
				outputSections(lines, file, name, "")
				local modified = false
				do
					local f = io.open(fn, "r")
					if f then 
						modified = false
						local lnum = 1
						for line in f:lines() do
							if lnum > #lines then
								modified = true
								break
							end
							if line ~= lines[lnum] then
								modified = true
								break
							end
							lnum = lnum + 1
						end
						
						if lnum-1 ~= #lines then
							modified = true
						end
						
						f:close()
					else
						modified = true
					end
				end
				
				if modified then
					local f, err = io.open(fn, "w")
					if f then
						for _,line in ipairs(lines) do
							f:write(line .. "\n")
						end
						f:close()
					else
						print(err)
					end
				end
				
			end
		end
		
	else
		parse(lines)
		
		filename = filename or vim.api.nvim_buf_get_name(0)
		local parendir = vim.fn.fnamemodify(filename, ":p:h" )
		for name, section in pairs(sections) do
			if section.root then
				local fn
				if name == "*" then
					local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
					fn = parendir .. "/tangle/" .. tail
				
				else
					fn = parendir .. "/" .. name
				end
				
				lines = {}
				if string.match(fn, "lua$") then
					local relname
					if filename then
						relname = filename
					else
						relname = vim.api.nvim_buf_get_name(0)
					end
					relname = vim.api.nvim_call_function("fnamemodify", { relname, ":t" })
					table.insert(lines, "-- Generated from " .. relname .. " using ntangle.nvim")
				elseif string.match(fn, "vim$") then
					local relname
					if filename then
						relname = filename
					else
						relname = vim.api.nvim_buf_get_name(0)
					end
					relname = vim.api.nvim_call_function("fnamemodify", { relname, ":t" })
					table.insert(lines, "\" Generated from " .. relname .. " using ntangle.nvim")
				end
				
				outputSections(lines, file, name, "")
				local modified = false
				do
					local f = io.open(fn, "r")
					if f then 
						modified = false
						local lnum = 1
						for line in f:lines() do
							if lnum > #lines then
								modified = true
								break
							end
							if line ~= lines[lnum] then
								modified = true
								break
							end
							lnum = lnum + 1
						end
						
						if lnum-1 ~= #lines then
							modified = true
						end
						
						f:close()
					else
						modified = true
					end
				end
				
				if modified then
					local f, err = io.open(fn, "w")
					if f then
						for _,line in ipairs(lines) do
							f:write(line .. "\n")
						end
						f:close()
					else
						print(err)
					end
				end
				
			end
		end
		
	end
end

function outputSections(lines, file, name, prefix)
	if not sections[name] then
		return
	end
	
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.TEXT then
				lines[#lines+1] = prefix .. line.str
			end
			
			if line.linetype == LineType.REFERENCE then
				outputSections(lines, file, line.str, prefix .. line.prefix)
			end
			
		end
	end
end

local function tangleAll()
	local filelist = vim.api.nvim_call_function("glob", { "**/*.tl" })
	
	for file in vim.gsplit(filelist, "\n") do
		tangle(file)
	end
end

local function getRootFilename()
	local filename = vim.api.nvim_call_function("expand", { "%:p"})
	local parendir = vim.api.nvim_call_function("fnamemodify", { filename, ":p:h" })

	local line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
	

	local fn
	if name == "*" then
		local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
		fn = parendir .. "/tangle/" .. tail
	
	else
		fn = parendir .. "/" .. name
	end
	
	return fn
end

return {
tangle = tangle,

tangleAll = tangleAll,

getRootFilename = getRootFilename,

}

