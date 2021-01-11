-- Generated from border_window.lua.tl, find_root.lua.tl, goto.lua.tl, ntangle.lua.tl, parse.lua.tl, show_helper.lua.tl, transpose.lua.tl using ntangle.nvim
require("linkedlist")

local transpose_win

local sections = {}
local curSection = nil

local LineType = {
	SECTION = 3,
	
	REFERENCE = 1,
	
	TEXT = 2,
	
}

local refs = {}

local lineRefs = {}

local nagivationLines = {}

local get_section

local resolve_root_section

local outputSectionsFull

local outputSections

local parse

local visitSections

local searchOrphans

local close_preview_autocmd

local collectLines

function get_section(lines, row)
	local containing
	local lnum = row
	while lnum >= 1 do
		local line = lines[lnum]
		if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
			local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
			
			containing = name
		end
		
		lnum = lnum - 1
	end

	while lnum <= #lines do
		local line = lines[lnum]
		if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
			local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")
			
			containing = name
		end
		
		lnum = lnum + 1
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

local function goto(lnum)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	
	local _, row, _, _ = unpack(vim.fn.getpos("."))
	local assembly_name
	while row >= 1 do
		local line = lines[row]
		if string.match(line, "^##%S*%s*$") then
			local name = string.match(line, "^##(%S*)%s*$")
			
			assembly_name = name
			break
		end
		
		row = row - 1
	end
	
	if assembly_name then
		local assemblies = {}
		local curassembly = "*"
		assemblies[curassembly] = {}
		
		for lnum, line in ipairs(lines) do
			if string.match(line, "^##%S*%s*$") then
				local name = string.match(line, "^##(%S*)%s*$")
				
				curassembly = name
				
				assemblies[curassembly] = assemblies[curassembly] or {}
				
			else
				table.insert(assemblies[curassembly], line)
				
			end
		end
		
		local name = assembly_name
		filename = nil
		if not filename then
			filename = vim.fn.expand("%:p")
		end
		
		local parendir = vim.fn.fnamemodify( filename, ":p:h" )
		local fn
		local fname = vim.fn.fnamemodify( filename, ":t:r" )
		local ns = vim.fn.fnamemodify( name, ":t" )
		local reldir = vim.fn.fnamemodify( name, ":h" )
		fn = parendir .. "/" .. reldir .. "/tangle/" .. ns .. "." .. fname .. ".tlpart"
		
		
		local assembly = {
			name = vim.split(vim.fn.fnamemodify(fn, ":t"), "%.")[1],
			ext = vim.fn.fnamemodify(filename, ":e:e:r"),
			tangle_dir = vim.fn.fnamemodify(fn, ":h"),
			dir = vim.fn.fnamemodify(fn, ":h:h"),
		}
		local parts = vim.fn.glob(assembly.tangle_dir .. "/" .. assembly.name .. ".*.tlpart")
		parts = vim.split(parts, "\n")
		
		local bufferlines = lines
		local offset = {}
		
		local lines = {}
		local origin = {}
		for _, part in ipairs(parts) do
			local first = true
			local part_origin
			for line in io.lines(part) do
				if first then
					if line == filename then
						break
					end
					local f = io.open(line, "r")
					if not f then
						break
					end
					f:close()
					
					offset[line] = #lines
					
					
					part_origin = line
					
					first = false
				else
					table.insert(lines, line)
					table.insert(origin, part_origin)
				end
			end
			
		end
		
		offset[filename] = #lines
		for _, line in ipairs(assemblies[name]) do
			table.insert(lines, line)
			table.insert(origin, filename)
		end
		
		sections = {}
		curSection = nil
		
		lineRefs = {}
		
		parse(lines)
		

		local rootlines = bufferlines
		local _, row, _, _ = unpack(vim.fn.getpos("."))
		local containing = get_section(rootlines, row)
		local name = resolve_root_section(containing)
		
		local tangled = {}
		outputSectionsFull(tangled, name)
		
		assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")
		
		local l = tangled[lnum]
		local lorigin = origin[l.lnum]
		assert(lorigin, "nil origin")
		
		local l = tangled[lnum]
		local relpos = l.lnum - offset[lorigin]
		
		if lorigin == filename then
			local jumpline
			local curassembly
			local curassemblyindex = 0
			for lnum, line in ipairs(rootlines) do
				if string.match(line, "^##%S*%s*$") then
					local name = string.match(line, "^##(%S*)%s*$")
					
					curassembly = name
					
				else
					if curassembly == assembly_name then
						curassemblyindex = curassemblyindex + 1
					end
					
					if curassemblyindex == relpos then
						jumpline = lnum
						break
					end
					
				end
			end
			
			vim.fn.setpos(".", {0, jumpline, 0, 0})
			
		else
			local jumpline
			local curassembly
			local curassemblyindex = 0
			local lnum = 1
			for line in io.lines(lorigin) do
				if string.match(line, "^##%S*%s*$") then
					local name = string.match(line, "^##(%S*)%s*$")
					
					curassembly = name
					
				else
					if curassembly == assembly_name then
						curassemblyindex = curassemblyindex + 1
					end
					
					if curassemblyindex == relpos then
						jumpline = lnum
						break
					end
					
				end
				lnum = lnum + 1
			end
			
			vim.api.nvim_command("e " .. lorigin)
			vim.fn.setpos(".", {0, jumpline, 0, 0})
		end
		
	else
		sections = {}
		curSection = nil
		
		lineRefs = {}
		
		parse(lines)
		
		local rootlines = lines
		local _, row, _, _ = unpack(vim.fn.getpos("."))
		local containing = get_section(rootlines, row)
		local name = resolve_root_section(containing)
		
		local tangled = {}
		outputSectionsFull(tangled, name)
		
		assert(lnum <= #tangled and lnum >= 1, "line number out of range (>" .. #tangled .. ") !")
		
		local l = tangled[lnum]
		vim.fn.setpos(".", {0, l.lnum, 0, 0})
		
	end
end

function outputSectionsFull(lines, name)
	if not sections[name] then
		return
	end
	
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.TEXT then
				table.insert(lines, line)
			end
			
			if line.linetype == LineType.REFERENCE then
				outputSectionsFull(lines, line.str)
			end
			
		end
	end
	return cur, nil
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
		if string.find(name, "/") then
			fn = parendir .. "/" .. name
		
		else 
			fn = parendir .. "/tangle/" .. name
		end
		
	end
	
	return fn
end

local function tangle(filename)
	local assemblies = {}
	if filename then
		local lines = {}
		for line in io.open(lines) do
			table.insert(lines, line)
		end
		
		local curassembly = "*"
		assemblies[curassembly] = {}
		
		for lnum, line in ipairs(lines) do
			if string.match(line, "^##%S*%s*$") then
				local name = string.match(line, "^##(%S*)%s*$")
				
				curassembly = name
				
				assemblies[curassembly] = assemblies[curassembly] or {}
				
			else
				table.insert(assemblies[curassembly], line)
				
			end
		end
		
	else
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		
		local curassembly = "*"
		assemblies[curassembly] = {}
		
		for lnum, line in ipairs(lines) do
			if string.match(line, "^##%S*%s*$") then
				local name = string.match(line, "^##(%S*)%s*$")
				
				curassembly = name
				
				assemblies[curassembly] = assemblies[curassembly] or {}
				
			else
				table.insert(assemblies[curassembly], line)
				
			end
		end
		
	end

	for name, lines in pairs(assemblies) do
		if name ~= "*" and #lines > 0 then
			if not filename then
				filename = vim.fn.expand("%:p")
			end
			
			local parendir = vim.fn.fnamemodify( filename, ":p:h" )
			local fn
			local fname = vim.fn.fnamemodify( filename, ":t:r" )
			local ns = vim.fn.fnamemodify( name, ":t" )
			local reldir = vim.fn.fnamemodify( name, ":h" )
			fn = parendir .. "/" .. reldir .. "/tangle/" .. ns .. "." .. fname .. ".tlpart"
			
			
			local parendir =  vim.fn.fnamemodify(fn, ":h") 
			local isdir = vim.fn.isdirectory(parendir)
			if isdir == 0 then
				vim.fn.mkdir(parendir, "p" )
			end
			
			local f = io.open(fn, "w")
			
			if not filename then
				filename = vim.api.nvim_buf_get_name()
			end
			f:write(filename .. "\n")
			for _, line in ipairs(lines) do
				f:write(line .. "\n")
			end
			
			f:close()
		end
	end
	
	for name, lines in pairs(assemblies) do
		if name ~= "*" and #lines > 0 then
			if not filename then
				filename = vim.fn.expand("%:p")
			end
			
			local parendir = vim.fn.fnamemodify( filename, ":p:h" )
			local fn
			local fname = vim.fn.fnamemodify( filename, ":t:r" )
			local ns = vim.fn.fnamemodify( name, ":t" )
			local reldir = vim.fn.fnamemodify( name, ":h" )
			fn = parendir .. "/" .. reldir .. "/tangle/" .. ns .. "." .. fname .. ".tlpart"
			
			
			local assembly = {
				name = vim.split(vim.fn.fnamemodify(fn, ":t"), "%.")[1],
				ext = vim.fn.fnamemodify(filename, ":e:e:r"),
				tangle_dir = vim.fn.fnamemodify(fn, ":h"),
				dir = vim.fn.fnamemodify(fn, ":h:h"),
			}
			local parts = vim.fn.glob(assembly.tangle_dir .. "/" .. assembly.name .. ".*.tlpart")
			parts = vim.split(parts, "\n")
			
			local lines = {}
			for _, part in ipairs(parts) do
				local first = true
				for line in io.lines(part) do
					if first then
						first = false
					else
						table.insert(lines, line)
					end
				end
				
			end
			
			sections = {}
			curSection = nil
			
			lineRefs = {}
			
			parse(lines)
			
			for name, section in pairs(sections) do
				if section.root then
					local fn
					if name == "*" then
						fn = assembly.tangle_dir .. "/" .. assembly.name .. "." .. assembly.ext
					
					else
						fn = assembly.dir .. "/" .. name
					end
					
					lines = {}
					local parts_tails = {}
					for _, part in ipairs(parts) do
						local fn = vim.fn.fnamemodify(part, ":t:r")
						fn = vim.split(fn, "%.")
						table.remove(fn, 1)
						table.insert(parts_tails, table.concat(fn, ".") .. ".tl")
					end
					
					if string.match(fn, "lua$") then
						table.insert(lines, "-- Generated from " .. table.concat(parts_tails, ", ") .. " using ntangle.nvim")
					elseif string.match(fn, "vim$") then
						table.insert(lines, "\" Generated from " .. table.concat(parts_tails, ", ") .. " using ntangle.nvim")
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
						local f = io.open(fn, "w")
						if f then
							for _,line in ipairs(lines) do
								f:write(line .. "\n")
							end
							f:close()
						else
							print("Could not write to " .. fn)
						end
					end
					
				end
			end
			
		end
	end
	
	if #assemblies["*"] > 0 then
		local lines = assemblies["*"]
		sections = {}
		curSection = nil
		
		lineRefs = {}
		
		parse(lines)
		
		local filename
		if not filename then
			filename = vim.api.nvim_call_function("expand", { "%:p"})
		end
		local parendir = vim.api.nvim_call_function("fnamemodify", { filename, ":p:h" })
		for name, section in pairs(sections) do
			if section.root then
				local fn
				if name == "*" then
					local tail = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
					fn = parendir .. "/tangle/" .. tail
				
				else
					if string.find(name, "/") then
						fn = parendir .. "/" .. name
					
					else 
						fn = parendir .. "/tangle/" .. name
					end
					
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
					local f = io.open(fn, "w")
					if f then
						for _,line in ipairs(lines) do
							f:write(line .. "\n")
						end
						f:close()
					else
						print("Could not write to " .. fn)
					end
				end
				
			end
		end
		
	end
	
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
		
		lineRefs[lnum] = curSection.str
		
		lnum = lnum+1;
	end
end

local function show_helper()
	sections = {}
	curSection = nil
	
	lineRefs = {}
	
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
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
	sections = {}
	curSection = nil
	
	lineRefs = {}
	
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	parse(lines)
	
	local curnum = vim.api.nvim_call_function("line", {"."})
	local name = lineRefs[curnum]
	
	local lines = {}
	local fn = name
	if name == "*" then
		local filename = vim.api.nvim_buf_get_name(0)
		fn = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
	end
	
	if string.match(fn, "lua$") then
		table.insert(lines, {1, "-- Generated from {relname} using ntangle.nvim"})
	elseif string.match(fn, "vim$") then
		table.insert(lines, {1, "\" Generated from {relname} using ntangle.nvim"})
	end
	
	local jumpline = collectLines(name, lines, "", curnum)
	
	local originbuf = vim.api.nvim_call_function("bufnr", {})
	local curcol = vim.api.nvim_call_function("col", {"."})
	

	local transpose_buf = vim.api.nvim_create_buf(false, true)
	local old_ft = vim.api.nvim_buf_get_option(0, "ft")
	if old_ft then
		vim.api.nvim_buf_set_option(transpose_buf, "ft", old_ft)
	end
	-- vim.api.nvim_buf_set_name(transpose_buf, "transpose")
	
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
	
	local border_title = "Transpose"
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
	vim.api.nvim_set_current_win(transpose_win)
	vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
	
	vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua navigateTo()<CR>', {noremap = true})
	
	vim.api.nvim_set_current_buf(transpose_buf)
	
	vim.api.nvim_command("normal ggdG")
	
	local lnumtr = 0
	for _,line in ipairs(lines) do
		local lnum, text = unpack(line)
		vim.api.nvim_buf_set_lines(transpose_buf, lnumtr, lnumtr, false, { text })
		lnumtr = lnumtr + 1
	end
	
	vim.api.nvim_command("normal Gddgg")
	navigationLines = {}
	for _,line in ipairs(lines) do 
		local lnum, _ = unpack(line)
		navigationLines[#navigationLines+1] = { buf = originbuf, lnum = lnum }
	end
	
	if jumpline then
		vim.api.nvim_call_function("cursor", { jumpline, curcol-1 })
	end
	
end

function collectLines(name, lines, prefix, curnum)
	local jumpline
	local s
	for n, section in pairs(sections) do
		if n == name then
			s = section
			break
		end
	end
	if not s then return end
	
	for section in linkedlist.iter(s.list) do
		for line in linkedlist.iter(section.lines) do
			if line.lnum == curnum then jumpline = #lines+1 end
	
			if line.linetype == LineType.TEXT then table.insert(lines, { line.lnum, prefix .. line.str })
			elseif line.linetype == LineType.REFERENCE then 
				jumpline = collectLines(line.str, lines, prefix .. line.prefix, curnum) or jumpline
			end
		end
	end
	
	return jumpline
end

function navigateTo()
	local curline = vim.api.nvim_call_function("line", {'.'})
	local curcol = vim.api.nvim_call_function("col", {'.'})
	local nav = navigationLines[curline]
	
	vim.api.nvim_win_close(transpose_win, true)
	
	vim.api.nvim_call_function("cursor", { nav.lnum, curcol })
	
end

return {
goto = goto,

tangleAll = tangleAll,

getRootFilename = getRootFilename,

tangle = tangle,

show_helper = show_helper,

collectSection = collectSection,

}

