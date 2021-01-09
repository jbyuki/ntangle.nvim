-- Generated from ntangle.lua.tl using ntangle.nvim
require("linkedlist")

local sections = {}
local curSection = nil

local LineType = {
	SECTION = 3,
	
	REFERENCE = 1,
	
	TEXT = 2,
	
}

local lineRefs = {}

local nagivationLines = {}

local storages = {}

local task_prefix = "→ "

local transpose_win

local outputSections

local getlinenum

local toluapat

local collectLines

local visitSections

local searchOrphans

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

local function goto(filename, linenum, root_pattern)
	sections = {}
	curSection = nil
	
	lineRefs = {}
	
	lnum = 1
	for line in io.lines(filename) do
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
	
	local root
	if root_pattern ~= "*" then
		for name,section in pairs(sections) do
			if section.root and string.find(name, toluapat(root_pattern)) then
				root = name
				break
			end
		end
	
		if not root then
			print("Could not root section " .. root_pattern .. " " .. toluapat(root_pattern))
		end
	else
		root = root_pattern
	end
	
	if root == "*" and not sections["*"] then
		for name,section in pairs(sections) do
			if section.root then
				root = name
				break
			end
		end
	end
	
	local startline = 1
	local fn = root
	if root == "*" then
		fn = vim.api.nvim_call_function("fnamemodify", { filename, ":t:r" })
	end
	
	if string.match(fn, "lua$") then
		startline = startline + 1
	end
	
	if string.match(fn, "vim$") then
		startline = startline + 1
	end
	
	local _,lnum = getlinenum(root, startline, linenum)
	assert(lnum, "Could not go to line " .. linenum .. " in " .. root)
	
	vim.api.nvim_command("normal " .. lnum .. "gg")
	
end

function getlinenum(name, cur, goal)
	if not sections[name] then
		return cur, nil
	end
	
	for section in linkedlist.iter(sections[name].list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.TEXT then
				if cur == goal then 
					return cur, line.lnum 
				end
				cur = cur + 1
			end
			
			if line.linetype == LineType.REFERENCE then
				local found
				cur, found = getlinenum(line.str, cur, goal)
				if found then 
					return cur, found 
				end
			end
			
		end
	end
	return cur, nil
end

local function tangleAll()
	local filelist = vim.api.nvim_call_function("glob", { "**/*.tl" })
	
	for file in vim.gsplit(filelist, "\n") do
		tangle(file)
	end
end

function toluapat(pat)
	local luapat = ""
	for i=1,#pat do
		local c = string.sub(pat, i, i)

		if c == '*' then luapat = luapat .. "."
		elseif c == '.' then luapat = luapat .. "%."
		else luapat = luapat .. c end
	end
	return luapat
end

local function collectSection()
	sections = {}
	curSection = nil
	
	lineRefs = {}
	
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
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

local function show_errors(filename)
	sections = {}
	curSection = nil
	
	lineRefs = {}
	
	lnum = 1
	for line in io.lines(filename) do
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
	
	local visited, notdefined = {}, {}
	for name, section in pairs(sections) do
		if section.root then
			visitSections(visited, notdefined, name, 0)
		end
	end
	
	local qflist = {}
	for name, lnum in pairs(notdefined) do
		table.insert(qflist, {
			filename = filename,
			lnum = lnum,
			text = name .. " is empty",
			type = "W",
		})
	end
	
	local orphans = {}
	for name, section in pairs(sections) do
		if not section.root then
			searchOrphans(name, visited, orphans, 0)
		end
	end
	
	for name, lnum in pairs(orphans) do
		table.insert(qflist, {
			filename = filename,
			lnum = lnum,
			text = name .. " is an orphan section",
			type = "W",
		})
	end
	
	vim.fn.setqflist(qflist, "r")
	
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

local function show_storage(buf)
	local storagebuf = vim.api.nvim_create_buf(false, true)
	local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
	
	local popup = {
		width = 40,
		height = 15,
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
	
	if storages[buf] then
		vim.api.nvim_win_close(storages[buf].win, true)
	end
	local storagewin = vim.api.nvim_open_win(storagebuf, false, opts)
	
	vim.api.nvim_win_set_option(storagewin, "winblend", 30)
	
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
	
	local border_title = "Storage"
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
	
	
	if storages[buf] then
		vim.api.nvim_win_close(storages[buf].borderwin, true)
	end
	
	local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
	
	vim.api.nvim_win_set_option(borderwin, "winblend", 30)
	
	local parent_win = vim.api.nvim_get_current_win()
	vim.api.nvim_set_current_win(storagewin)
	vim.api.nvim_set_current_win(parent_win)
	
	local hi_ns = vim.api.nvim_create_namespace("")
	
	vim.api.nvim_buf_attach(buf, false, { on_lines = function(...)
		vim.schedule(function()
			sections = {}
			curSection = nil
			
			lineRefs = {}
			
			vim.api.nvim_buf_clear_namespace(storagebuf, hi_ns, 0, -1)
			
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
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
			
			local visited, notdefined = {}, {}
			for name, section in pairs(sections) do
				if section.root then
					visitSections(visited, notdefined, name, 0)
				end
			end
			
			local undefined = {}
			for name, lnum in pairs(notdefined) do
				table.insert(undefined, name)
			end
			table.sort(undefined, function(a, b) return notdefined[a] < notdefined[b] end)
			
			local tasks = {}
			for _, el in ipairs(undefined) do
				table.insert(tasks, task_prefix .. el)
			end
			
			vim.api.nvim_buf_set_lines(storagebuf, 0, -1, true, tasks)
			for i=0,#undefined-1 do
				vim.api.nvim_buf_add_highlight(storagebuf, hi_ns, "Special", i, string.len(task_prefix), -1)
			end
			
			
		end)
	end})

	storages[buf] = {}
	storages[buf].win = storagewin
	
	storages[buf].borderwin = borderwin
	
end

local function close_storage()
	local buf = vim.api.nvim_get_current_buf()
	if storages[buf] then
		vim.api.nvim_win_close(storages[buf].win, true)
		vim.api.nvim_win_close(storages[buf].borderwin, true)
		
		storages[buf] = nil
	end
	
	
end

local function tangle(filename)
	local assemblies = {}
	if filename then
		local curassembly = "*"
		assemblies[curassembly] = {}
		
		for line in io.lines(filename) do
			if string.match(line, "^@@%S*+=%s*$") then
				local name = string.match(line, "^##(%S*)%s*$")
				
				curassembly = name
				assemblies[curassembly] = assemblies[curassembly] or {}
				
			else
				table.insert(assemblies[curassembly], line)
				
			end
		end
		
		
	else
		local curassembly = "*"
		assemblies[curassembly] = {}
		
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		for _, line in ipairs(lines) do
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
			
			
			local isdir = vim.fn.isdirectory( vim.fn.fnamemodify(fn, ":h") )
			if isdir == 0 then
				vim.fn.mkdir(parentdir, "p" )
			end
			
			local f = io.open(fn, "w")
			
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
				dir = vim.fn.fnamemodify(fn, ":h"),
			}
			local parts = vim.fn.glob(assembly.dir .. "/" .. assembly.name .. ".*.tlpart")
			parts = vim.split(parts, "\n")
			
			local lines = {}
			for _, part in ipairs(parts) do
				for line in io.lines(part) do
					table.insert(lines, line)
				end
			end
			
			sections = {}
			curSection = nil
			
			lineRefs = {}
			
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
			
			for name, section in pairs(sections) do
				if section.root then
					local fn
					if name == "*" then
						fn = assembly.dir .. "/" .. assembly.name .. "." .. assembly.ext
					
					else
						fn = assembly.dir .. "/" .. name
					end
					
					lines = {}
					local parts_tails = {}
					for _, part in ipairs(parts) do
						print(part)
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
	
	-- @if_there_is_an_unamed_assemble_just_tangle
end

return {
goto = goto,

tangleAll = tangleAll,

collectSection = collectSection,

getRootFilename = getRootFilename,

show_errors = show_errors,

show_storage = show_storage,

close_storage = close_storage,

tangle = tangle,

}

-- @functions+=
-- local function tangle(filename)
-- 	@clear_sections
-- 	if filename then
-- 		@read_file_line_by_line
-- 	else
-- 		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
-- 		@read_file_line_by_line_from_variable
-- 	end
-- 	@output_sections
-- end
-- 
-- @export_symbols+=
-- tangle = tangle,

