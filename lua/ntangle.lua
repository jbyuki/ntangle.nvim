-- Generated from assemble.lua.tl, border_window.lua.tl, contextmenu.lua.tl, debug.lua.tl, find_root.lua.tl, incremental.lua.tl, mapping.lua.tl, ntangle.lua.tl, parse.lua.tl, search_cache.lua.tl, show_helper.lua.tl, transpose.lua.tl, treesitter.lua.tl using ntangle.nvim
require("linkedlist")

local assemble_nav = {}

local sections = {}
local curSection = nil

local LineType = {
	SECTION = 3,
	
	REFERENCE = 1,
	
	TEXT = 2,
	
}

local refs = {}

local cache_jump

local transpose_win, transpose_buf

local borderwin 

local nagivationLines = {}

local ntangle_required

local ext_to_lang = {
  ["rs"] = "rust",
}

local fill_border

local contextmenu_open

local debug_array

local get_section

local resolve_root_section

local outputSections

local parse

local visitSections

local searchOrphans

local close_preview_autocmd

local outputSectionsFull

local function show_assemble()
	local lines = {}
	local curassembly

	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	

	local filename = nil
	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
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
		fill_border(borderbuf, border_opts, center_title, border_title)
		
		
		borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
		vim.api.nvim_set_current_win(transpose_win)
		vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
		
		vim.api.nvim_buf_set_option(0, "ft", ext_to_lang[ft] or ft)
		

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
		vim.api.nvim_command("e " .. nav.origin)
	end
	vim.fn.setpos(".", {0, nav.lnum, 0, 0})
end

function fill_border(borderbuf, border_opts, center_title, border_title)
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
	
end

function contextmenu_open(candidates, callback)
	local max_width = 0
	for _, el in ipairs(candidates) do
		max_width = math.max(max_width, vim.api.nvim_strwidth(el))
	end
	
	local buf = vim.api.nvim_create_buf(false, true)
	local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
	
	local opts = {
		relative = "cursor",
		width = max_width,
		height = #candidates,
		col = 2,
		row =  2,
		style = 'minimal'
	}
	
	contextmenu_win = vim.api.nvim_open_win(buf, false, opts)
	
	local borderbuf = vim.api.nvim_create_buf(false, true)
	
	local border_opts = {
		relative = "cursor",
		width = opts.width+2,
		height = opts.height+2,
		col = 1,
		row =  1,
		style = 'minimal'
	}
	
	fill_border(borderbuf, border_opts, false, "")
	
	local borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
	
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, candidates)
	
	vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<cmd>lua require"ntangle".select_contextmenu()<CR>', {noremap = true})
	
	vim.api.nvim_win_set_option(borderwin, "winblend", 30)
	vim.api.nvim_win_set_option(contextmenu_win, "winblend", 30)
	vim.api.nvim_win_set_option(contextmenu_win, "cursorline", true)
	vim.api.nvim_set_current_win(contextmenu_win)
	contextmenu_contextmenu = callback
	
	vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
	
end

local function select_contextmenu()
	local row = vim.fn.line(".")
	if contextmenu_contextmenu then
		vim.api.nvim_win_close(contextmenu_win, true)
		
		contextmenu_contextmenu(row)
		contextmenu_contextmenu = nil
	end
end

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

		if sections[name] and sections[name].root then
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
			-- @parse_variables+=
			-- local buf_attach = {}
			-- 
			-- @functions+=
			-- local function create_buf_attach(buf)
			  -- if buf_attach[buf] then return end
			-- 
			  -- @set_as_buf_attach
			-- 
			  -- local initial = true
			  -- @attach_variables
			  -- vim.api.nvim_buf_attach(buf, false, { 
			    -- on_lines = function(_, _, firstline, lastline, new_lastline, _) 
			      -- if initial then
			        -- local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
			        -- for lnum,line in ipairs(lines) do
			          -- @insert_new_line_initial
			        -- end
			        -- initial = false
			      -- else
			        -- for i=firstline+1,lastline do
			          -- @remove_current_line
			        -- end
			        -- for i=firstline+1,new_lastline do
			          -- @insert_new_line
			        -- end
			      -- end
			    -- end
			  -- })
			-- end
			-- 
			-- @export_symbols+=
			-- create_buf_attach = create_buf_attach,
			-- @o+=
			-- local
			-- 
			-- @set_as_buf_attach+=
			-- buf_attach[buf] = true
			-- 
			-- @declare_functions+=
			-- local insert_line, delete_line
			-- 
			-- @functions+=
			-- function insert_line(references, tangle_index, tangle_lines, source_index, source_lines, i, line)
			  -- @get_line_type
			  -- local modified
			  -- if type == LineType.REFERENCE then
			    -- @if_section_is_defined_add_new_lines
			  -- elseif type == LineType.SECTION then
			    -- @delete_following_lines_from_previous_containing_section
			    -- @insert_lines_into_new_section_and_modify_referenced
			  -- elseif type == LineType.TEXT then
			    -- @compute_line_number_recursively
			    -- @add_text_to_containing_section
			    -- @update_containing_section_part_length
			    -- @insert_text_line_into_source
			    -- @reformat_modified_for_text_line
			    -- @update_section_total_length
			  -- end
			  -- return modified
			-- end
			-- 
			-- function delete_line(tangle_index, tangle_lines, i)
			  -- @get_line_to_delete
			  -- @get_line_type
			  -- if type == LineType.REFERENCE then
			    -- @if_section_is_defined_remove_lines
			  -- elseif type == LineType.SECTION then
			    -- @delete_following_lines_from_previous_containing_section
			    -- @insert_lines_into_current_containing_section
			  -- elseif type == LineType.TEXT then
			    -- @remove_text_from_containing_section
			  -- end
			-- end
			-- 
			-- @declare_functions+=
			-- local get_line_type
			-- 
			-- @functions+=
			-- function get_line_type(line)
			  -- if string.match(line, "^%s*@@") then
			    -- return LineType.TEXT
			  -- elseif string.match(line, "^@[^@]%S*[+-]?=%s*$") then
			    -- return LineType.SECTION
			  -- elseif string.match(line, "^%s*@[^@]%S*%s*$") then
			    -- return LineType.REFERENCE
			  -- else
			    -- return LineType.TEXT
			  -- end
			-- end
			-- 
			-- 
			-- @get_line_type+=
			-- local type = get_line_type(line)
			-- 
			-- @declare_functions+=
			-- local get_line_number
			-- 
			-- @functions+=
			-- function get_line_number(tangle_index, references, i)
			  -- @get_relative_offset_in_section_part
			  -- @if_no_offset_found_return_none
			  -- @get_relative_offset_in_section
			  -- @if_section_is_root_return_offset
			  -- @otherwise_recursively_search_for_references
			-- end
			-- 
			-- @get_relative_offset_in_section_part+=
			-- local offset, section_part
			-- local tangle_line = tangle_index[i-1]
			-- local rel = 0
			-- 
			-- while tangle_line do
			  -- local line = tangle_line.data
			  -- if line.type == LineType.SECTION then
			    -- offset = rel
			    -- section_part = line
			    -- break
			  -- end
			  -- tangle_line = tangle_line.prev
			-- end
			-- 
			-- @if_no_offset_found_return_none+=
			-- if not offset then
			  -- break
			-- end
			-- 
			-- @get_relative_offset_in_section+=
			-- local node = section_part.node
			-- while node.prev do
			  -- node = node.prev
			  -- offset = offset + node.data.len
			-- end
			-- 
			-- @if_section_is_root_return_offset+=
			-- if node.data.root then
			  -- return {{ node.data.name, offset }}
			-- end
			-- 
			-- @otherwise_recursively_search_for_references+=
			-- local result = {}
			-- for _, ref in ipairs(references[node.data.name]) do
			  -- local ret = get_line_number(tangle_index, references,ref)
			  -- for _, r in ipairs(ret) do
			    -- table.insert(result, r)
			  -- end
			-- end
			-- 
			-- for _, r in ipairs(result) do
			  -- r[1] = r[1] + offset
			-- end
			-- 
			-- return result
			-- 
			-- @compute_line_number_recursively+=
			-- local changes = get_line_number(tangle_index, tangle_lines, references, i)
			-- 
			-- @add_text_to_containing_section+=
			-- local tangle_line = {
			  -- str = line,
			  -- type = LineType.TEXT,
			-- }
			-- 
			-- local new_node
			-- 
			-- if i == 0 then
			  -- new_node = linkedlist.push_front(tangle_lines, list, tangle_line)
			-- else
			  -- local before = tangle_index[i]
			  -- new_node = linkedlist.insert_after(tangle_lines, before, tangle_line)
			-- end
			-- 
			-- table.insert(tangle_index, i+1, new_node)
			-- 
			-- @declare_functions+=
			-- local get_containing_section_part
			-- 
			-- @functions+=
			-- function get_containing_section_part(tangle_index, i)
			  -- local node = tangle_index[i]
			  -- while node do
			    -- if node.data.type == LineType.SECTION then
			      -- return node.data
			    -- end
			    -- node = node.prev
			  -- end
			-- end
			-- 
			-- @update_containing_section_part_length+=
			-- local section = get_containing_section_part(tangle_index, i)
			-- section.len = section.len + 1
			-- 
			-- @insert_text_line_into_source+=
			-- local new_node
			-- if i == 0 then
			  -- new_node = linkedlist.push_front(source_lines, line)
			-- else
			  -- local before = source_index[i]
			  -- new_node = linkedlist.push_front(source_lines, before, line)
			-- end
			-- table.insert(source_index, i+1, new_node)
			-- 
			-- @declare_functions+=
			-- local update_length
			-- 
			-- @functions+=
			-- function update_length(lengths, name, delta)
			  -- lengths[name] = lengths[name] + delta
			  -- local parent = {}
			  -- for _, ref in ipairs(references[name]) do
			  -- end
			-- end
			-- 
			-- @update_section_total_length+=
			-- 
			-- @delete_following_lines_from_previous_containing_section+=
			-- local range_start = i+1
			-- local range_end = #tangle_index
			-- 
			-- for j=i+1,#tangle_index do
			  -- local type = tangle_index[i].data.type
			  -- if type == LineType.SECTION then
			    -- range_end = j
			    -- break
			  -- end
			-- end
			-- 
			-- 
		end
	end

	assert(vim.tbl_count(roots) == 1, "multiple roots or none")
	local name = vim.tbl_keys(roots)[1]
	return name
end

local function get_location_list()
	local curassembly
	local lines = {}
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	

  local _, row, _, _ = unpack(vim.fn.getpos("."))
  
  local line = lines[1] or ""
  if string.match(lines[1], "^##%S*%s*$") then
  	local name = string.match(line, "^##(%S*)%s*$")
  	
  	curassembly = name
  	
  end
  

	local tangled = {}
	local filename

	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
			end
		end
		

		local rootlines = lines
		local lines = assembled
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local containing = get_section(rootlines, row)
		containing = resolve_root_section(containing)
		

		local ext = vim.fn.fnamemodify(fn, ":e:e")
		local filename = parendir .. "/" .. assembly_parendir .. "/" .. assembly_tail .. "." .. ext
		
		outputSectionsFull(filename, tangled, containing)
		

    for _, line in ipairs(tangled) do
      local prefix, l = unpack(line)
      if l and l.lnum then
        l.lnum = l.lnum + 1
      end
    end

    return tangled
  else
		sections = {}
		curSection = nil
		
		parse(lines)
		
		filename = vim.api.nvim_buf_get_name(0)
		

		local rootlines = lines
		local containing = get_section(rootlines, row)
		containing = resolve_root_section(containing)
		
		outputSectionsFull(filename, tangled, containing)
		

    return tangled
  end
end

local function tangle(filename)
	local curassembly
	local lines = {}
	if filename then
		for line in io.lines(filename) do
			table.insert(lines, line)
		end
		
	else
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
		
	end

	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
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
					if string.find(name, "/") then
						fn = parendir .. "/" .. name
					else
						fn = parendir .. "/tangle/" .. name
					end
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
  local roots = {}

  lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  
	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	
	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
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
					if string.find(name, "/") then
						fn = parendir .. "/" .. name
					else
						fn = parendir .. "/tangle/" .. name
					end
				end
				
				lines = {}
		    table.insert(roots, fn)
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
					if string.find(name, "/") then
						fn = parendir .. "/" .. name
					else
						fn = parendir .. "/tangle/" .. name
					end
				end
				
				lines = {}
		    table.insert(roots, fn)
			end
		end
		
	end

  if #roots == 0 then
    print("No root found!")
  end

  if #roots > 1 then
    print("multiple roots " .. vim.inspect(roots))
  end

	return roots[1]
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
			
			if not curSection then
				return
			end
			linkedlist.push_back(curSection.lines, l)
			
		end
		
		lnum = lnum+1;
	end
end

local function search_cache()
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
  
  local border_title = " ntangle cache "
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
  fill_border(borderbuf, border_opts, center_title, border_title)
  
  
  borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
  vim.api.nvim_set_current_win(transpose_win)
  vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
  

  local filename = vim.g.tangle_cache_file
  
  if not cache_jump then
    cache_jump = {}
    for line in io.lines(filename) do
      table.insert(cache_jump, line)
    end
  end
  
  vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, true, cache_jump)
  

  vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<cr>', [[<cmd>lua require"ntangle".jump_cache()<cr>]], { noremap = true })
  
end

local function jump_cache()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  
  local entry = cache_jump[row]
  
  local words = vim.split(entry, " ")
  local filename = words[#words]
  table.remove(words)
  local section_name = table.concat(words, "_")
  
  vim.api.nvim_win_close(0, true)
  

  vim.api.nvim_command("edit " .. filename)
  vim.api.nvim_command("call search(\"" .. section_name .. "\")")
end

local function show_helper()
	local curassembly
	local lines = {}
	lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	

	local line = lines[1] or ""
	if string.match(lines[1], "^##%S*%s*$") then
		local name = string.match(line, "^##(%S*)%s*$")
		
		curassembly = name
		
	end
	

	local filename
	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
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
	

	if #qflist == 0 then
		table.insert(qflist, "  No warnings :)  ")
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
	fill_border(borderbuf, border_opts, center_title, border_title)
	
	
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
		
		curassembly = name
		
	end
	
	
	local tangled = {}
	local filename
	local jumplines = {}

	if curassembly then
		local fn = filename or vim.api.nvim_buf_get_name(0)
		fn = vim.fn.fnamemodify(fn, ":p")
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
		local parts = vim.split(vim.fn.glob(path .. assembly_tail .. ".*.tl"), "\n")
		link_name = vim.fn.fnamemodify(link_name, ":p")
		for _, part in ipairs(parts) do
			if link_name ~= part then
				local f = io.open(part, "r")
				local origin_path = f:read("*line")
				f:close()
				
				local f = io.open(origin_path, "r")
				if f then
					table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
					offset[origin_path] = #assembled
					
					local lnum = 1
					while true do
						local line = f:read("*line")
						if not line then break end
						if lnum > 1 then
							table.insert(assembled, line)
							table.insert(origin, origin_path)
							
						end
						lnum = lnum + 1
					end
					f:close()
				else
					os.remove(part)
					
				end
				
			else
				table.insert(valid_parts, vim.fn.fnamemodify(part, ":t:e:e:e"))
				offset[fn] = #assembled
				
				for lnum, line in ipairs(lines) do
					if lnum > 1 then
						table.insert(assembled, line)
						table.insert(origin, fn)
						
					end
				end
				
			end
		end
		

		local rootlines = lines
		local lines = assembled
		sections = {}
		curSection = nil
		
		parse(lines)
		

		local containing = get_section(rootlines, row)
		containing = resolve_root_section(containing)
		

		local ext = vim.fn.fnamemodify(fn, ":e:e")
		local filename = parendir .. "/" .. assembly_parendir .. "/" .. assembly_tail .. "." .. ext
		
		outputSectionsFull(filename, tangled, containing)
		
		for lnum, line in ipairs(tangled) do
			local _, l = unpack(line)
			local relpos = (l.lnum or -1) - offset[fn]
			if relpos == row-1 then
				table.insert(jumplines, lnum)
			end
		end
		
		assert(#jumplines > 0, "Could not jump to line")
		
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
		
		filename = vim.api.nvim_buf_get_name(0)
		

		local rootlines = lines
		local containing = get_section(rootlines, row)
		containing = resolve_root_section(containing)
		
		outputSectionsFull(filename, tangled, containing)
		
		for lnum, line in ipairs(tangled) do
			local _, l = unpack(line)
			if l.lnum == row then
				table.insert(jumplines, lnum)
			end
		end
		
		assert(#jumplines > 0, "Could not find line to jump")
		
		navigationLines = {}
		local curorigin = vim.api.nvim_buf_get_name(0)
		for _,line in ipairs(tangled) do 
			local _, l = unpack(line)
			local nav = { origin = curorigin, lnum = l.lnum }
			table.insert(navigationLines, nav)
		end
		
	end

	local ft = vim.api.nvim_buf_get_option(0, "ft")
	

	local selected = function(row) 
		local jumpline = jumplines[row]

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
		fill_border(borderbuf, border_opts, center_title, border_title)
		
		
		borderwin = vim.api.nvim_open_win(borderbuf, false, border_opts)
		vim.api.nvim_set_current_win(transpose_win)
		vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. borderwin .. ", false)")
		
		vim.api.nvim_buf_set_option(0, "ft", ext_to_lang[ft] or ft)
		

		local transpose_lines = {}
		for _, l in ipairs(tangled) do
			local prefix, line = unpack(l)
			table.insert(transpose_lines, prefix .. line.str)
		end
		
		vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)
		
		vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua require"ntangle".navigateTo()<CR>', {noremap = true})
		

		vim.fn.setpos(".", {0, jumpline, 0, 0})
		
	end

	if #jumplines == 1 then
		selected(1)
	else
		local options = {}
		for _, lnum in ipairs(jumplines) do
			table.insert(options, "L" .. lnum)
		end
		contextmenu_open(options, selected)
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
			if string.find(name, "/") then
				fn = parendir .. "/" .. name
			else
				fn = parendir .. "/tangle/" .. name
			end
		end
		
		if string.match(filename, "lua.tl$") then
			table.insert(lines, {"", { str = "-- Generated from {relname} using ntangle.nvim" }})
		elseif string.match(filename, "vim.tl$") then
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

local function navigateTo()
	local _, row, _, _ = unpack(vim.fn.getpos("."))
	
	vim.api.nvim_win_close(transpose_win, true)
	
	local n = navigationLines[row]
	if vim.api.nvim_buf_get_name(0) ~= n.origin then
		vim.api.nvim_command("e " .. n.origin)
	end
	vim.fn.setpos(".", {0, n.lnum, 0, 0})
	
end

local function enable_syntax_highlighting()
	local bufname = vim.api.nvim_buf_get_name(0)
	local ext = vim.fn.fnamemodify(bufname, ":e:e:r")
	
	if not ntangle_required then
		local parser_dll = vim.api.nvim_get_runtime_file("ntangle.so", "all")
		if #parser_dll > 0 then
			local success = vim.treesitter.require_language("ntangle", parser_dll[1])
			if success then
				ntangle_required = true
			end
		end
		
	end
	local opts = {
		queries = {
			["ntangle"] = "(codeline) @combined @" .. ext
		}
	}
	local buf = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(buf, "ntangle", opts)
	
	vim.treesitter.highlighter.new(parser, {})
	local lang = ext_to_lang[ext] or ext
	vim.api.nvim_command("set ft=" .. lang)
	
end

return {
show_assemble = show_assemble,

assembleNavigate = assembleNavigate,

select_contextmenu = select_contextmenu,

get_location_list = get_location_list,

tangle = tangle,

tangleAll = tangleAll,

getRootFilename = getRootFilename,

search_cache = search_cache,
jump_cache = jump_cache,
show_helper = show_helper,

collectSection = collectSection,

navigateTo = navigateTo,

enable_syntax_highlighting = enable_syntax_highlighting,

}

