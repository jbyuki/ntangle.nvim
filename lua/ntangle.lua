require("linkedlist")

local sections = {}
local curSection = nil

local LineType = {
	SECTION = 3,
	
	REFERENCE = 1,
	
	TEXT = 2,
	
}

local outputSections

local getlinenum

local toluapat

local function tangle(filename)
	sections = {}
	curSection = nil
	
	if filename then
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
		
	else
		lnum = 1
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
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
				if string.match(name, "%./") then
					fn = parendir .. string.sub(name, 2)
				
				else 
					fn = parendir .. "/tangle/" .. name
				end
				
			end
			
			lines = {}
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
	
	local _,lnum = getlinenum(root, 1, linenum)
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

local function collectSection(filename, name)
	sections = {}
	curSection = nil
	
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
	
	local s
	for n, section in pairs(sections) do
		if n == name then
			s = section
			break
		end
	end
	if not s then
		print("Could not find section " .. name)
		return
	end
	
	local lines = {}
	for section in linkedlist.iter(s.list) do
		for line in linkedlist.iter(section.lines) do
			if line.linetype == LineType.TEXT then
				lines[#lines+1] = { filename = filename, lnum = line.lnum, text = line.str }
			end
			
			if line.linetype == LineType.REFERENCE then
				lines[#lines+1] = { filename = filename, lnum = line.lnum, text = line.prefix .. "@" .. line.str}
			end
			
		end
	end
	
	vim.api.nvim_call_function("setqflist", { lines, "r" })
	
	vim.api.nvim_command(":copen")
end

return {
tangle = tangle,

goto = goto,

tangleAll = tangleAll,

collectSection = collectSection,

}

