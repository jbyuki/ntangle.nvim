-- Generated from assemble.lua.tl, border_window.lua.tl, debug.lua.tl, find_root.lua.tl, go_definition.lua.tl, goto.lua.tl, ntangle.lua.tl, parse.lua.tl, show_helper.lua.tl, transpose.lua.tl using ntangle.nvim
require("linkedlist")

local sections = {}
local curSection = nil

local LineType = {
	SECTION = 3,
	
	REFERENCE = 1,
	
	TEXT = 2,
	
}

local refs = {}

local transpose_win, transpose_buf

local borderwin 

local nagivationLines = {}

local assemble_nav = {}

local debug_array

local get_section

local resolve_root_section

local outputSectionsFull

local outputSections

local parse

local visitSections

local searchOrphans

local close_preview_autocmd

function debug_array(l)
	if #l == 0 then
		print("{}")
	end
	for i, li in ipairs(l) do
		print(i .. ": " .. vim.inspect(li))
	end
end

function get_section(lines, row)
	local containing
	local lnum = row
	while lnum >= 1 do
		local line = lines[lnum]
		if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
			local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
			
			containing = name
			break
		end
		
		lnum = lnum - 1
	end

	if not containing then
		local lnum = row
		while lnum <= #lines do
			local line = lines[lnum]
			if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
				local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
				
				containing = name
				break
			end
			
			lnum = lnum + 1
		end
	end

	assert(containing, "no containing section!")
	return containing
end

function resolve_root_section(containing)
	local open = { containing }
	local explored = {}
	local roots = {}
	while #open > 0 do
		local name = open[#open]
		table.remove(open)
		explored[name] = true

		if sections[name].root then
			roots[name] = true
		end
		

		if refs[name] then
			local parents = refs[name]
			local i = 1
			while i <= #parents do
				if explored[parent] then
					table.remove(parents, i)
				else
					i = i + 1
				end
			end
			
			for _, parent in ipairs(parents) do
				table.insert(open, parent)
			end
			
		end
	end

	assert(vim.tbl_count(roots) == 1, "multiple roots or none")
	local name = vim.tbl_keys(roots)[1]
	return name
end

local function go_definition()
	local tosearch
	local line = vim.api.nvim_get_current_line()
	
	if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
		local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
		
		tosearch = name
	
	elseif string.match(line, "^%s*@[^@]%S*%s*$") then
		local _, _, prefix, name = string.find(line, "^(%s*)@(%S+)%s*$")
		if name == nil then
			print(line)
		end
		
		tosearch = name
	end
	
	assert(tosearch, "no reference or section under cursor!")

	local lines = {}
	local curassembly
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	local filename = nil
	local definitions = {}
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
		

		for lnum, line in ipairs(assembled) do
			if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
				local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
				
				if name == tosearch then
					local origin = origin[lnum]
					local relpos = lnum - offset[origin]
					local def = {
						origin = origin,
						lnum = relpos+1,
					}
					
					table.insert(definitions, def)
					
				end
			end
			
		end
		
	else
		for lnum, line in ipairs(lines) do
			if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
				local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
				
				if name == tosearch then
					local origin = vim.api.nvim_buf_get_name(0)
					local def = {
						origin = origin,
						lnum = lnum,
					}
					
					table.insert(definitions, def)
					
				end
			end
			
		end
		
	end

	assert(#definitions >= 1, "Definition not found")
	local def = definitions[1]
	local curbuf = vim.api.nvim_buf_get_name(0)
	if def.origin ~= curbuf then
		vim.api.nvim_command("e " .. def.origin)
	end
	
	vim.fn.setpos(".", {0, def.lnum, 0, 0})
	
end

local function goto(lnum)
	local lines = {}
	local curassembly
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	local filename = nil
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
		

		local rootlines = lines
		local lines = assembled
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local _, row, _, _ = unpack(vim.fn.getpos("."))
		local containing = get_section(rootlines, row)
		local name = resolve_root_section(containing)
		
		local tangled = {}
		local main_file = filename or vim.api.nvim_buf_get_name(0)
		outputSectionsFull(main_file, tangled, name)
		
		assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")
		
		local _, l = unpack(tangled[lnum])
		local lorigin = origin[l.lnum]
		assert(lorigin, "nil origin")
		
		local relpos = l.lnum - offset[lorigin]
		
		if lorigin == fn then
			vim.fn.setpos(".", {0, relpos+1, 0, 0})
			
		else
			vim.api.nvim_command("e " .. lorigin)
			vim.fn.setpos(".", {0, relpos+1, 0, 0})
			
		end
		
	else
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local rootlines = lines
		local _, row, _, _ = unpack(vim.fn.getpos("."))
		local containing = get_section(rootlines, row)
		local name = resolve_root_section(containing)
		
		local tangled = {}
		local main_file = filename or vim.api.nvim_buf_get_name(0)
		outputSectionsFull(main_file, tangled, name)
		
		assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")
		
		local _, l = unpack(tangled[lnum])
		vim.fn.setpos(".", {0, l.lnum, 0, 0})
		
	end
end

function outputSectionsFull(filename, lines, name, prefix)
	prefix = prefix or ""
	if not sections[name] then
		return
	end
	
	if sections[name].root then
		local parendir = vim.fn.fnamemodify(filename, ":p:h" )
		if name == "*" then
			local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
			fn = parendir .. "/tangle/" .. tail
		
		else
			fn = parendir .. "/" .. name
		end
		
		if string.match(fn, "lua.tl$") then
			table.insert(lines, {"", { str = "-- Generated from {relname} using ntangle.nvim" }})
		elseif string.match(fn, "vim.tl$") then
			table.insert(lines, {"", { str = "\" Generated from {relname} using ntangle.nvim" }})
		end
		
	end
	
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.TEXT then
				table.insert(lines, { prefix, line })
			end
			
			if line.linetype == LineType.REFERENCE then
				outputSectionsFull(filename, lines, line.str, line.prefix .. prefix)
			end
			
		end
	end
	return cur, nil
end

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
		

		sections = {}
		curSection = nil
		
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
		sections = {}
		curSection = nil
		
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
	
	local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
	

	local fn
	if name == "*" then
		local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
		fn = parendir .. "/tangle/" .. tail
	
	else
		fn = parendir .. "/" .. name
	end
	
	return fn
end

function parse(lines)
	lnum = 1
	for _,line in ipairs(lines) do
		if string.match(line, "^%s*@@") then
			local hasSection = false
			if sections[name] then
				hasSection = true
			end
			
			if hasSection then
				local _,_,pre,post = string.find(line, '^(.*)@@(.*)$')
				local text = pre .. "@" .. post
				local l = { 
					linetype = LineType.TEXT, 
					str = text 
				}
				
				l.lnum = lnum
				
				linkedlist.push_back(curSection.lines, l)
				
			end
		
		elseif string.match(line, "^@[^@]%S*[+-]?=%s*$") then
			local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
			
			local section = { linetype = LineType.SECTION, str = name, lines = {}}
			
			if op == '+=' or op == '-=' then
				if sections[name] then
					if op == '+=' then
						linkedlist.push_back(sections[name].list, section)
						
					elseif op == '-=' then
						linkedlist.push_front(sections[name].list, section)
						
					end
				else
					sections[name] = { root = false, list = {} }
					
					linkedlist.push_back(sections[name].list, section)
					
				end
			
			else 
				sections[name] = { root = true, list = {} }
				
				linkedlist.push_back(sections[name].list, section)
				
			end
			
			curSection = section
			
		
		elseif string.match(line, "^%s*@[^@]%S*%s*$") then
			local _, _, prefix, name = string.find(line, "^(%s*)@(%S+)%s*$")
			if name == nil then
				print(line)
			end
			
			-- @check_that_sections_is_not_empty
			local l = { 
				linetype = LineType.REFERENCE, 
				str = name,
				prefix = prefix
			}
			
			l.lnum = lnum
			
			refs[name] = refs[name] or {}
			table.insert(refs[name], curSection.str)
			
			linkedlist.push_back(curSection.lines, l)
			
		
		else
			if sections[name] then
				hasSection = true
			end
			
			local l = { 
				linetype = LineType.TEXT, 
				str = line 
			}
			
			l.lnum = lnum
			
			linkedlist.push_back(curSection.lines, l)
			
		end
		
		lnum = lnum+1;
	end
end

local function show_helper()
	local curassembly
	local lines = {}
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	

	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	

	local filename
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
		

		lines = assembled
		sections = {}
		curSection = nil
		
		parse(lines)
		
	end

	sections = {}
	curSection = nil
	
	parse(lines)
	

	local visited, notdefined = {}, {}
	for name, section in pairs(sections) do
		if section.root then
			visitSections(visited, notdefined, name, 0)
		end
	end
	
	local qflist = {}
	for name, lnum in pairs(notdefined) do
		table.insert(qflist, name .. " is empty" )
	end
	
	local orphans = {}
	for name, section in pairs(sections) do
		if not section.root then
			searchOrphans(name, visited, orphans, 0)
		end
	end
	
	for name, lnum in pairs(orphans) do
		table.insert(qflist, name .. " is an orphan section")
	end
	

	local max_width = 0
	for _, line in ipairs(qflist) do
		max_width = math.max(max_width, vim.api.nvim_strwidth(line))
	end
	
	local buf = vim.api.nvim_create_buf(false, true)
	local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
	
	local MAX_WIDTH = 60
	local MAX_HEIGHT = 15
	
	local popup = {
		width = math.min(max_width, MAX_WIDTH),
		height = math.min(#qflist, MAX_HEIGHT),
		margin_up = 3,
		margin_right = 6,
	}
	
	local opts = {
		relative = "win",
		win = vim.api.nvim_get_current_win(),
		width = popup.width,
		height = popup.height,
		col = w - popup.width - popup.margin_right,
		row =  popup.margin_up,
		style = 'minimal'
	}
	
	local win = vim.api.nvim_open_win(buf, false, opts)
	
	vim.api.nvim_win_set_option(win, "winblend", 30)
	
	local borderbuf = vim.api.nvim_create_buf(false, true)
	
	local border_opts = {
		relative = "win",
		win = vim.api.nvim_get_current_win(),
		width = popup.width+2,
		height = popup.height+2,
		col = w - popup.width - popup.margin_right - 1,
		row =  popup.margin_up - 1,
		style = 'minimal'
	}
	
	local border_title = " ntangle helper "
	local center_title = true
	local border_text = {}
	
	local border_chars = {
		topleft  = '╭',
		topright = '╮',
		top      = '─',
		left     = '│',
		right    = '│',
		botleft  = '╰',
		botright = '╯',
		bot      = '─',
	}
	
	-- local border_chars = {
		-- topleft  = '╔',
		-- topright = '╗',
		-- top      = '═',
		-- left     = '║',
		-- right    = '║',
		-- botleft  = '╚',
		-- botright = '╝',
		-- bot      = '═',
	-- }
	
	for y=1,border_opts.height do
		local line = ""
		if y == 1 then
			if not center_title then
				line = border_chars.topleft .. border_chars.top
				local title_len = 0
				if border_title then
					line = line .. border_title
					title_len = vim.api.nvim_strwidth(border_title)
				end
				
				for x=2+title_len+1,border_opts.width-1 do
					line = line .. border_chars.top
				end
				line = line .. border_chars.topright
				
			else
				line = border_chars.topleft
				
				local title_len = 0
				if border_title then
					title_len = vim.api.nvim_strwidth(border_title)
				end
				
				local pad_left = math.floor((border_opts.width-title_len)/2)
				
				for x=2,pad_left do
					line = line .. border_chars.top
				end
				
				if border_title then
					line = line .. border_title
				end
				
				for x=pad_left+title_len+1,border_opts.width-1 do
					line = line .. border_chars.top
				end
				
				line = line .. border_chars.topright
				
			end
		elseif y == border_opts.height then
			line = border_chars.botleft
			for x=2,border_opts.width-1 do
				line = line .. border_chars.bot
			end
			line = line .. border_chars.botright
			
		else
			line = border_chars.left
			for x=2,border_opts.width-1 do
				line = line .. " "
			end
			line = line .. border_chars.right
			
		end
		table.insert(border_text, line)
	end
	
	vim.api.nvim_buf_set_lines(borderbuf, 0, -1, true, border_text)
	
	
	local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
	
	vim.api.nvim_win_set_option(borderwin, "winblend", 30)
	
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, qflist)
	
	close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)
	close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, borderwin)
	
end

function visitSections(visited, notdefined, name, lnum) 
	if visited[name] then
		return
	end
	
	if not sections[name] then
		notdefined[name] = lnum
		return
	end
	
	visited[name] = true
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.REFERENCE then
				visitSections(visited, notdefined, line.str, line.lnum)
			end
			
		end
	end
end

function searchOrphans(name, visited, orphans, lnum) 
	if not sections[name] then
		return
	end
	
	if not visited[name] and linkedlist.get_size(sections[name].list) > 0 then
		orphans[name] = lnum
		local dummy = {}
		visitSections(visited, dummy, name, 0)
		return
	end
	
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.REFERENCE then
				searchOrphans(line.str, visited, orphans, line.lnum)
			end
			
		end
	end
end

function close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

local function collectSection()
	local curassembly
	local lines = {}
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	

	local _, row, _, _ = unpack(vim.fn.getpos("."))
	
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	
	local tangled = {}
	local filename
	local jumpline

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
		

		local rootlines = lines
		local lines = assembled
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local containing = get_section(rootlines, row)
		
		outputSectionsFull(fn, tangled, containing)
		
		for lnum, line in ipairs(tangled) do
			local _, l = unpack(line)
			local relpos = (l.lnum or -1) - offset[fn]
			if relpos == row-1 then
				jumpline = lnum
				break
			end
		end
		
		assert(jumpline, "Could not jump to line")
		
		navigationLines = {}
		for lnum,line in ipairs(tangled) do 
			local _, l = unpack(line)
			local origin = origin[l.lnum]
			local relpos = (l.lnum or -1) - (offset[origin] or 0)
			local nav = { origin = origin, lnum = relpos+1 }
			table.insert(navigationLines, nav)
		end
		
	else
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local rootlines = lines
		local containing = get_section(rootlines, row)
		
		outputSectionsFull(fn, tangled, containing)
		
		for lnum, line in ipairs(tangled) do
			local _, l = unpack(line)
			if l.lnum == row then
				jumpline = lnum
				break
			end
		end
		
		assert(jumpline, "Could not find line to jump")
		
		navigationLines = {}
		local curorigin = vim.api.nvim_buf_get_name(0)
		for _,line in ipairs(tangled) do 
			local _, l = unpack(line)
			local nav = { origin = curorigin, lnum = l.lnum }
			table.insert(navigationLines, nav)
		end
		
	end

	local ft = vim.api.nvim_buf_get_option(0, "ft")
	
	transpose_buf = vim.api.nvim_create_buf(false, true)
	
	local perc = 0.8
	local win_width  = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)
	local width = math.floor(perc*win_width)
	local height = math.floor(perc*win_height)
	
	local opts = {
		width = width,
		height = height,
		row = math.floor((win_height-height)/2),
		col = math.floor((win_width-width)/2),
		relative = "win",
		win = vim.api.nvim_get_current_win(),
	}
	
	transpose_win = vim.api.nvim_open_win(transpose_buf, false, opts)
	
	local border_title = "Transpose"
	local borderbuf = vim.api.nvim_create_buf(false, true)
	
	local border_opts = {
		relative = "win",
		win = vim.api.nvim_get_current_win(),
		width = opts.width+2,
		height = opts.height+2,
		col = opts.col-1,
		row =  opts.row-1,
		style = 'minimal'
	}
	
	local center_title = true
	local border_text = {}
	
	local border_chars = {
		topleft  = '╭',
		topright = '╮',
		top      = '─',
		left     = '│',
		right    = '│',
		botleft  = '╰',
		botright = '╯',
		bot      = '─',
	}
	
	-- local border_chars = {
		-- topleft  = '╔',
		-- topright = '╗',
		-- top      = '═',
		-- left     = '║',
		-- right    = '║',
		-- botleft  = '╚',
		-- botright = '╝',
		-- bot      = '═',
	-- }
	
	for y=1,border_opts.height do
		local line = ""
		if y == 1 then
			if not center_title then
				line = border_chars.topleft .. border_chars.top
				local title_len = 0
				if border_title then
					line = line .. border_title
					title_len = vim.api.nvim_strwidth(border_title)
				end
				
				for x=2+title_len+1,border_opts.width-1 do
					line = line .. border_chars.top
				end
				line = line .. border_chars.topright
				
			else
				line = border_chars.topleft
				
				local title_len = 0
				if border_title then
					title_len = vim.api.nvim_strwidth(border_title)
				end
				
				local pad_left = math.floor((border_opts.width-title_len)/2)
				
				for x=2,pad_left do
					line = line .. border_chars.top
				end
				
				if border_title then
					line = line .. border_title
				end
				
				for x=pad_left+title_len+1,border_opts.width-1 do
					line = line .. border_chars.top
				end
				
				line = line .. border_chars.topright
				
			end
		elseif y == border_opts.height then
			line = border_chars.botleft
			for x=2,border_opts.width-1 do
				line = line .. border_chars.bot
			end
			line = line .. border_chars.botright
			
		else
			line = border_chars.left
			for x=2,border_opts.width-1 do
				line = line .. " "
			end
			line = line .. border_chars.right
			
		end
		table.insert(border_text, line)
	end
	
	vim.api.nvim_buf_set_lines(borderbuf, 0, -1, true, border_text)
	
	
	borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
	vim.api.nvim_set_current_win(transpose_win)
	vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
	
	vim.api.nvim_buf_set_option(0, "ft", ft)
	

	local transpose_lines = {}
	for _, l in ipairs(tangled) do
		local prefix, line = unpack(l)
		table.insert(transpose_lines, prefix .. line.str)
	end
	
	vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)
	
	vim.fn.setpos(".", {0, jumpline, 0, 0})
	

	vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua require"ntangle".navigateTo()<CR>', {noremap = true})
	
end

local function navigateTo()
	local _, row, _, _ = unpack(vim.fn.getpos("."))
	
	vim.api.nvim_win_close(transpose_win, true)
	
	local n = navigationLines[row]
	if vim.api.nvim_buf_get_name(0) ~= n.origin then
		vim.fn.nvim_command("e " .. n.origin)
	end
	vim.fn.setpos(".", {0, n.lnum, 0, 0})
	
end

local function show_assemble()
	local lines = {}
	local curassembly

	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	

	local filename = nil
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
		

		local _, row, _, _ = unpack(vim.fn.getpos("."))
		
		local ft = vim.api.nvim_buf_get_option(0, "ft")
		
		transpose_buf = vim.api.nvim_create_buf(false, true)
		
		local perc = 0.8
		local win_width  = vim.api.nvim_win_get_width(0)
		local win_height = vim.api.nvim_win_get_height(0)
		local width = math.floor(perc*win_width)
		local height = math.floor(perc*win_height)
		
		local opts = {
			width = width,
			height = height,
			row = math.floor((win_height-height)/2),
			col = math.floor((win_width-width)/2),
			relative = "win",
			win = vim.api.nvim_get_current_win(),
		}
		
		transpose_win = vim.api.nvim_open_win(transpose_buf, false, opts)
		
		local border_title = "Assembly"
		local borderbuf = vim.api.nvim_create_buf(false, true)
		
		local border_opts = {
			relative = "win",
			win = vim.api.nvim_get_current_win(),
			width = opts.width+2,
			height = opts.height+2,
			col = opts.col-1,
			row =  opts.row-1,
			style = 'minimal'
		}
		
		local center_title = true
		local border_text = {}
		
		local border_chars = {
			topleft  = '╭',
			topright = '╮',
			top      = '─',
			left     = '│',
			right    = '│',
			botleft  = '╰',
			botright = '╯',
			bot      = '─',
		}
		
		-- local border_chars = {
			-- topleft  = '╔',
			-- topright = '╗',
			-- top      = '═',
			-- left     = '║',
			-- right    = '║',
			-- botleft  = '╚',
			-- botright = '╝',
			-- bot      = '═',
		-- }
		
		for y=1,border_opts.height do
			local line = ""
			if y == 1 then
				if not center_title then
					line = border_chars.topleft .. border_chars.top
					local title_len = 0
					if border_title then
						line = line .. border_title
						title_len = vim.api.nvim_strwidth(border_title)
					end
					
					for x=2+title_len+1,border_opts.width-1 do
						line = line .. border_chars.top
					end
					line = line .. border_chars.topright
					
				else
					line = border_chars.topleft
					
					local title_len = 0
					if border_title then
						title_len = vim.api.nvim_strwidth(border_title)
					end
					
					local pad_left = math.floor((border_opts.width-title_len)/2)
					
					for x=2,pad_left do
						line = line .. border_chars.top
					end
					
					if border_title then
						line = line .. border_title
					end
					
					for x=pad_left+title_len+1,border_opts.width-1 do
						line = line .. border_chars.top
					end
					
					line = line .. border_chars.topright
					
				end
			elseif y == border_opts.height then
				line = border_chars.botleft
				for x=2,border_opts.width-1 do
					line = line .. border_chars.bot
				end
				line = line .. border_chars.botright
				
			else
				line = border_chars.left
				for x=2,border_opts.width-1 do
					line = line .. " "
				end
				line = line .. border_chars.right
				
			end
			table.insert(border_text, line)
		end
		
		vim.api.nvim_buf_set_lines(borderbuf, 0, -1, true, border_text)
		
		
		borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
		vim.api.nvim_set_current_win(transpose_win)
		vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
		
		vim.api.nvim_buf_set_option(0, "ft", ft)
		

		vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, assembled)
		
		vim.fn.setpos(".", {0, row+offset[fn]-1, 0, 0})
		

		assemble_nav = {}
		for i=1,#assembled do
			local org = origin[i]
			local nav = {
				lnum = i - offset[org] + 1,
				origin = org,
			}
			table.insert(assemble_nav, nav)
		end
		
		vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>u', '<cmd>lua require"ntangle".assembleNavigate()<CR>', {noremap = true})
		
	end
end

local function assembleNavigate()
	local _, row, _, _ = unpack(vim.fn.getpos("."))
	
	vim.api.nvim_win_close(transpose_win, true)
	
	local nav = assemble_nav[row]
	if nav.origin ~= vim.api.nvim_buf_get_name(0) then
		vim.fn.nvim_command("e " .. nav.origin)
	end
	vim.fn.setpos(".", {0, nav.lnum, 0, 0})
end

return {
go_definition = go_definition,

goto = goto,

tangle = tangle,

tangleAll = tangleAll,

getRootFilename = getRootFilename,

show_helper = show_helper,

collectSection = collectSection,

navigateTo = navigateTo,

show_assemble = show_assemble,

assembleNavigate = assembleNavigate,

}

