-- Generated using ntangle.nvim
local assemble_nav

local transpose_win, transpose_buf

local navigationLines = {}

local LineType = {
	ASSEMBLY = 5,

	REFERENCE = 1,

	TEXT = 2,

	SECTION = 3,

	SENTINEL = 4,

	TANGLED = 6,

}

local contextmenu_contextmenu

local contextmenu_win

local span_ns = vim.api.nvim_create_namespace("")

local clear_highlight_span
local highlighted = {}

local undefined_ns

linkedlist = {}

local get_origin

local create_transpose_buf

local tangle_buf
local tangle_lines
local tangle_write

local generate_header

local tangle_all

local generate_comment

local tangle_buf_with_comments

local contextmenu_open

local jump_cache

local jump_this_ref

local close_preview_autocmd

local clear_highlight_autocmd

local function build_cache(filename)
	local tangle_code_dir = "~/fakeroot/code"
	local filelist = vim.api.nvim_call_function("glob", { tangle_code_dir .. "/**/*.t" })

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

local function get_code_at_cursor()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  local start_part, end_part
  for part in linkedlist.iter(tangled.parts_ll) do
    if part.origin == buf then
      start_part = part.start_part
      end_part = part.end_part
      break
    end
  end

  local it = start_part
  local lnum = 1
  while it and it ~= end_part do
    local line = it.data
    if line.linetype ~= LineType.SENTINEL then
      line.lnum = lnum
      lnum = lnum + 1
    end
    it = it.next
  end


  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local start_code, end_code

  local it = start_part
  while it and it ~= end_part do
    local line = it.data
    if line.linetype == LineType.SECTION and line.tangled[1] then
      it = it.next
      local tangled_line = it.data
      while it and it ~= end_part do
        tangled_line = it.data
        if tangled_line.linetype == LineType.SECTION then
          break
        end
        it = it.next
      end

      tangled_line = it.prev.data
      if tangled_line.lnum > row and tangled_line.tangled[1] then
        start_code = line.tangled[1]
        end_code = tangled_line.tangled[1]
        break
      end
    else
      it = it.next
    end
  end

  if not start_code or not end_code then
    start_code = tangled.tangled_ll.head
    end_code = nil
  end

  local code = {}
  local it = start_code
  local prefix
  while it and it.prev and it.prev ~= end_code do 
    local line = it.data
    if line.linetype == LineType.TANGLED and line.str then
      if #code == 0 then
        prefix = string.match(line.str, "^%s*"):len()
      end

      local txt = line.str:sub(prefix+1)

      table.insert(code, txt)
      print(txt)
    end
    it = it.next
  end

  return code
end

local function get_code_at_vrange()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  local start_part, end_part
  for part in linkedlist.iter(tangled.parts_ll) do
    if part.origin == buf then
      start_part = part.start_part
      end_part = part.end_part
      break
    end
  end

  local it = start_part
  local lnum = 1
  while it and it ~= end_part do
    local line = it.data
    if line.linetype ~= LineType.SENTINEL then
      line.lnum = lnum
      lnum = lnum + 1
    end
    it = it.next
  end


  local _,slnum,sbyte,vscol = unpack(vim.fn.getpos("'<"))
  local _,elnum,ebyte,vecol = unpack(vim.fn.getpos("'>"))

  local it = start_part
  local start_code, end_code

  while it and it ~= end_part do
    local line = it.data
    if line.lnum and line.tangled[1] then
      if line.lnum == slnum then
        start_code = line.tangled[1]
      end

      if line.lnum == elnum then
        end_code = line.tangled[1]
      end
    end
    it = it.next
  end
  local code = {}
  local it = start_code
  local prefix
  while it and it.prev and it.prev ~= end_code do 
    local line = it.data
    if line.linetype == LineType.TANGLED and line.str then
      if #code == 0 then
        prefix = string.match(line.str, "^%s*"):len()
      end

      local txt = line.str:sub(prefix+1)

      table.insert(code, txt)
      print(txt)
    end
    it = it.next
  end

  return code
end

local function show_assemble()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)
	local assembled = {}

  for line in linkedlist.iter(tangled.untangled_ll) do
    if line.linetype ~= LineType.SENTINEL then
      table.insert(assembled, line.line)
    end
  end
  local lnum = 1
  for line in linkedlist.iter(tangled.untangled_ll) do
    if line.linetype ~= LineType.SENTINEL then
      line.lnum = lnum
      lnum = lnum + 1
    end
  end


  local _, row, _, _ = unpack(vim.fn.getpos("."))

  local ft = vim.api.nvim_buf_get_option(0, "ft")

  create_transpose_buf()

  vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, assembled)

  local start_part, end_part
  for part in linkedlist.iter(tangled.parts_ll) do
    if part.origin == buf then
      start_part = part.start_part
      end_part = part.end_part
      break
    end
  end

  local untangled_it

  local it = start_part
  local lnum = 1
  while it and it ~= end_part do
    local line = it.data
    if line.linetype ~= LineType.SENTINEL then
      if lnum == row then
        untangled_it = it
        break
      end
      lnum = lnum + 1
    end
    it = it.next
  end

  if untangled_it then
    vim.api.nvim_win_set_cursor(0, {untangled_it.data.lnum, 0})
  end


  assemble_nav = {
    tangled = tangled,
    buf = buf
  }


  vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>u', '<cmd>lua require"ntangle".assembleNavigate()<CR>', {noremap = true})

end

local function assembleNavigate()
	local _, row, _, _ = unpack(vim.fn.getpos("."))

	vim.api.nvim_win_close(transpose_win, true)

	local tangled = assemble_nav.tangled
	local buf = assemble_nav.buf

	local origin, lnum
	for part in linkedlist.iter(tangled.parts_ll) do
	  local start_part = part.start_part
	  local end_part = part.end_part
	  local it = start_part.next
	  local part_lnum = 1
	  while it and it ~= end_part do
	    if it.data.linetype ~= LineType.SENTINEL then
	      if it.data.lnum == row then
	        origin = part.origin
	        lnum = part_lnum
	        break
	      end
	      part_lnum = part_lnum + 1
	    end
	    it = it.next
	  end

	  if origin then break end
	end

	if origin ~= buf then
		vim.api.nvim_command("e " .. origin)
	end
	vim.api.nvim_win_set_cursor(0, {lnum, 0})

end

local function getRootFilename()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  local roots = {}
  for name, root in pairs(tangled.roots) do
    table.insert(roots, get_origin(buf, tangled.asm, name))
  end

  if #roots == 0 then
    print("No root found!")
  end

  if #roots > 1 then
    print("multiple roots !")
  end

	return roots[1]
end

function get_origin(filename, asm, name)
  local curassembly = asm
  local fn = filename or vim.api.nvim_buf_get_name(0)
  fn = vim.fn.fnamemodify(fn, ":p")
  local parendir = vim.fn.fnamemodify(fn, ":p:h")
  local assembly_parendir = vim.fn.fnamemodify(curassembly, ":h")
  local assembly_tail = vim.fn.fnamemodify(curassembly, ":t")
  local part_tails = {}
  local copy_fn = fn
  local copy_curassembly = curassembly
  while true do
    local part_tail = vim.fn.fnamemodify(copy_fn, ":t")
    table.insert(part_tails, 1, part_tail)
    copy_fn = vim.fn.fnamemodify(copy_fn, ":h")

    copy_curassembly = vim.fn.fnamemodify(copy_curassembly, ":h")
    if copy_curassembly == "." then
      break
    end
    if copy_curassembly ~= ".." and vim.fn.fnamemodify(copy_curassembly, ":h") ~= ".." then
      error("Assembly can't be in a subdirectory (it must be either in parent or same directory")
    end
  end
  local part_tail = table.concat(part_tails, ".")

  local link_name = parendir .. "/" .. assembly_parendir .. "/tangle/" .. assembly_tail .. "." .. part_tail
  local path = vim.fn.fnamemodify(link_name, ":h")
  if vim.fn.isdirectory(path) == 0 then
  	-- "p" means create also subdirectories
  	vim.fn.mkdir(path, "p") 
  end



  local parendir = vim.fn.fnamemodify(filename, ":p:h" ) .. "/" .. assembly_parendir

  local fn
  if name == "*" then
  	local tail = vim.fn.fnamemodify(filename, ":t:r" )
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

local function transpose()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)
	local assembled = {}

	local _, row, _, _ = unpack(vim.fn.getpos("."))

	local ft = vim.api.nvim_buf_get_option(0, "ft")


  local jumplines = {}
  for name, root in pairs(tangled.roots) do
    local lnum = 1
    local lines = {}
    local fn = get_origin(buf, tangled.asm, name)
    generate_header(fn, lines)

    lnum = lnum + #lines

    local it = root.tangled[1]
    while it and it ~= root.tangled[2] do
      if it.data.linetype ~= LineType.SENTINEL then
        it.data.lnum = lnum
        it.data.root = name
        lnum = lnum + 1
      end
      it = it.next
    end
  end

  for part in linkedlist.iter(tangled.parts_ll) do
    if part.origin == buf then
      local part_lnum = 1
      local it = part.start_part
      while it and it ~= part.end_part do
        if it.data.linetype ~= LineType.SENTINEL then
          if part_lnum == row then
            jumplines = it.data.tangled
            break
          end
          part_lnum = part_lnum + 1
        end
        it = it.next
      end

      if jumplines then break end
    end
  end


	local selected = function(row) 
		local jumpline = jumplines[row]

    create_transpose_buf()

		local transpose_lines = {}

		local lines = {}
		local fn = get_origin(buf, tangled.asm, jumpline.data.root)
		generate_header(fn, lines)


		for _, line in ipairs(lines) do
		  table.insert(transpose_lines, line)
		end

		local root = tangled.roots[jumpline.data.root]
		local it = root.tangled[1]
		while it and it ~= root.tangled[2] do
		  if it.data.linetype ~= LineType.SENTINEL then
		    table.insert(transpose_lines, it.data.str)
		  end
		  it = it.next
		end

		vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)

		vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua require"ntangle".navigateTo()<CR>', {noremap = true})


    navigationLines = {
      tangled = tangled,
      buf = buf,
      root = jumpline.data.root,
    }

		vim.schedule(function()
		  vim.api.nvim_win_set_cursor(transpose_win, {jumpline.data.lnum, 0})
		end)

	end

	assert(jumplines and #jumplines > 0, "Could not find line to jump")
	if #jumplines == 1 then
		selected(1)
	else
		local options = {}
		for _, jumpline in ipairs(jumplines) do
			table.insert(options, "L" .. jumpline.data.lnum .. " " .. jumpline.data.root)
		end
		contextmenu_open(options, selected)
	end
end

function create_transpose_buf()
  transpose_buf = vim.api.nvim_create_buf(false, true)

  local perc = 0.9
  local win_width  = vim.o.columns
  local win_height = vim.o.lines
  local width = math.floor(perc*win_width)
  local height = math.floor(perc*win_height)

  local opts = {
  	width = width,
  	height = height,
  	row = math.floor((win_height-height)/2),
  	col = math.floor((win_width-width)/2),
  	relative = "editor",
    border = "single",
  }

  transpose_win = vim.api.nvim_open_win(transpose_buf, true, opts)

  -- @setup_transpose_buffer
end

local function navigateTo()
	local _, row, _, _ = unpack(vim.fn.getpos("."))

	vim.api.nvim_win_close(transpose_win, true)

  local tangled = navigationLines.tangled
  local root = navigationLines.root
  local start_root = tangled.roots[root].tangled[1]
  local end_root = tangled.roots[root].tangled[2]
  local tangled_it = start_root
  while tangled_it and tangled_it ~= end_root do
    if tangled_it.data.linetype ~= LineType.SENTINEL then
      if tangled_it.data.lnum == row then
        break
      end
    end
    tangled_it = tangled_it.next
  end

  if tangled_it then
    local untangled = tangled_it.data.untangled
    local origin, lnum
    for part in linkedlist.iter(tangled.parts_ll) do
      local part_lnum = 1
      local it = part.start_part
      while it and it ~= part.end_part do
        if it.data.linetype ~= LineType.SENTINEL then
          if it == untangled then
            origin = part.origin
            lnum = part_lnum
            break
          end
          part_lnum = part_lnum + 1
        end
        it = it.next
      end

      if origin then break end
    end

    if vim.fn.expand("%:p") ~= origin then
      vim.api.nvim_command("e " .. origin)
    end
    vim.api.nvim_win_set_cursor(0, {lnum, 0})

  end
end

function tangle_buf()
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  tangle_write(filename, lines, false)
end

function tangle_write(filename, lines, comment)
  local tangled = tangle_lines(filename, lines, comment)

  for name, root in pairs(tangled.roots) do
    local fn = get_origin(filename, tangled.asm, name)

    local lines = {}
    generate_header(fn, lines)

    local it = root.tangled[1]
    while it and it ~= root.tangled[2] do
      if it.data.linetype == LineType.TANGLED then
        table.insert(lines, it.data.str)
      end
      it = it.next
    end


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

function tangle_lines(filename, lines, comment)
  local sections_ll = {}

  local roots = {}

  local asm

  local untangled_ll = {}

  local parts_ll = {}

  local tangled_ll = {}


  if string.match(lines[1], "^##%S*%s*$") then
    local line = lines[1]
  	local name = string.match(line, "^##(%S*)%s*$")

    asm = name
    local curassembly = asm
    local fn = filename or vim.api.nvim_buf_get_name(0)
    fn = vim.fn.fnamemodify(fn, ":p")
    local parendir = vim.fn.fnamemodify(fn, ":p:h")
    local assembly_parendir = vim.fn.fnamemodify(curassembly, ":h")
    local assembly_tail = vim.fn.fnamemodify(curassembly, ":t")
    local part_tails = {}
    local copy_fn = fn
    local copy_curassembly = curassembly
    while true do
      local part_tail = vim.fn.fnamemodify(copy_fn, ":t")
      table.insert(part_tails, 1, part_tail)
      copy_fn = vim.fn.fnamemodify(copy_fn, ":h")

      copy_curassembly = vim.fn.fnamemodify(copy_curassembly, ":h")
      if copy_curassembly == "." then
        break
      end
      if copy_curassembly ~= ".." and vim.fn.fnamemodify(copy_curassembly, ":h") ~= ".." then
        error("Assembly can't be in a subdirectory (it must be either in parent or same directory")
      end
    end
    local part_tail = table.concat(part_tails, ".")

    local link_name = parendir .. "/" .. assembly_parendir .. "/tangle/" .. assembly_tail .. "." .. part_tail
    local path = vim.fn.fnamemodify(link_name, ":h")
    if vim.fn.isdirectory(path) == 0 then
    	-- "p" means create also subdirectories
    	vim.fn.mkdir(path, "p") 
    end


    local asm_folder = vim.fn.fnamemodify(filename, ":p:h") .. "/" .. assembly_parendir .. "/tangle/"

    local link_file = io.open(link_name, "w")
    link_file:write(fn)
    link_file:close()



    local asm_tail = vim.fn.fnamemodify(asm, ":t")
    local parts = vim.split(vim.fn.glob(asm_folder .. asm_tail .. ".*.t"), "\n")

    for _, part in ipairs(parts) do
      local origin
      local f = io.open(part, "r")
      if f then
        origin = f:read("*line")
        f:close()
      end

      local start_part, end_part
      if origin then
        start_part = linkedlist.push_back(untangled_ll, {
          linetype = LineType.SENTINEL,
          str = origin
        })

        end_part = linkedlist.push_back(untangled_ll, {
          linetype = LineType.SENTINEL,
          str = origin
        })
      end

      if origin then
        linkedlist.push_back(parts_ll, {
          start_part = start_part,
          end_part = end_part,
          origin = origin,
        })
      end

    end


  else
    local origin = filename
    local start_part, end_part
    if origin then
      start_part = linkedlist.push_back(untangled_ll, {
        linetype = LineType.SENTINEL,
        str = origin
      })

      end_part = linkedlist.push_back(untangled_ll, {
        linetype = LineType.SENTINEL,
        str = origin
      })
    end

    if origin then
      linkedlist.push_back(parts_ll, {
        start_part = start_part,
        end_part = end_part,
        origin = origin,
      })
    end


  end


  local function parse(origin, lines, it)
    for lnum, line in ipairs(lines) do
      if string.match(line, "^%s*@@") then
        local _,_,pre,post = string.find(line, '^(.*)@@(.*)$')
        local text = pre .. "@" .. post
        local l = { 
        	linetype = LineType.TEXT, 
          line = line,
        	str = text 
        }

        it = linkedlist.insert_after(untangled_ll, it, l)


      elseif string.match(line, "^@[^@]%S*[+-]?=%s*$") then
      	local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")

      	local l = {
      	  linetype = LineType.SECTION,
      	  str = name,
      	  line = line,
      	  op = op,
      	}

        it = linkedlist.insert_after(untangled_ll, it, l)

        sections_ll[name] = sections_ll[name] or {}
        linkedlist.push_back(sections_ll[name], it)

        if op == "=" then 
          roots[name] = {
            untangled = it,
            origin = origin,
          }
        end

      elseif string.match(line, "^%s*@[^@]%S*%s*$") then
        local _, _, prefix, name = string.find(line, "^(%s*)@(%S+)%s*$")
        if name == nil then
        	print(line)
        end

      	local l = { 
      		linetype = LineType.REFERENCE, 
      		str = name,
      	  line = line,
      		prefix = prefix
      	}

        it = linkedlist.insert_after(untangled_ll, it, l)


      elseif string.match(line, "^##%S*%s*$") then
        local l = {
          linetype = LineType.ASSEMBLY,
          line = line,
          str = asm,
        }

        it = linkedlist.insert_after(untangled_ll, it, l)


      else
      	local l = { 
      		linetype = LineType.TEXT, 
      	  line = line,
      		str = line 
      	}

        it = linkedlist.insert_after(untangled_ll, it, l)

      end

    end
  end

  for part in linkedlist.iter(parts_ll) do
    local part_lines
    if part.origin == filename then
      part_lines = lines
    else
      part_lines = {}
      local f = io.open(part.origin, "r")
      if f then
        while true do
          local line = f:read("*line")
          if not line then break end
          table.insert(part_lines, line)
        end
        f:close()
      end

    end
    parse(part.origin, part_lines, part.start_part)
  end


  local function tangle_rec(name, tangled_it, prefix, root_name)
    if not sections_ll[name] then
      return nil, tangled_it
    end

    local start_section = linkedlist.insert_after(tangled_ll, tangled_it, {
      linetype = LineType.SENTINEL,
      str = "START " .. name,
    })

    local end_section = linkedlist.insert_after(tangled_ll,  start_section, {
      linetype = LineType.SENTINEL,
      str = "END " .. name,
    })

    for ref in linkedlist.iter(sections_ll[name]) do
      local it = ref.next
      local tangled_it
      if ref.data.op == "+=" then
        tangled_it = end_section.prev
      elseif ref.data.op == "-=" then
        tangled_it = start_section
      elseif ref.data.op == "=" then
        tangled_it = start_section
      end

      ref.data.tangled = ref.data.tangled or {}
      table.insert(ref.data.tangled, tangled_it)

      while it do
        local line = it.data
        if line.linetype == LineType.SECTION then
          break

        elseif line.linetype == LineType.REFERENCE then
          local start_ref
          if comment then
            local l = {
              linetype = LineType.TANGLED,
              str = prefix .. line.prefix .. generate_comment(root_name,  line.str),
              untangled = nil,
            }
            tangled_it = linkedlist.insert_after(tangled_ll, tangled_it, l)
          end

          start_ref, tangled_it = tangle_rec(line.str, tangled_it, prefix .. line.prefix, root_name)
          line.tangled = line.tangled or {}
          -- can get range by picking the next element tangled
          table.insert(line.tangled, start_ref)


        elseif line.linetype == LineType.ASSEMBLY then
          break

        elseif line.linetype == LineType.TEXT then
          local l = {
            linetype = LineType.TANGLED,
            str = (line.str ~= "" and prefix .. line.str) or "",
            untangled = it
          }
          tangled_it = linkedlist.insert_after(tangled_ll, tangled_it, l)
          line.tangled = line.tangled or {}
          table.insert(line.tangled, tangled_it)
        end


        it = it.next
      end
    end
    return start_section, end_section
  end

  local tangled_it = nil
  for name, ref in pairs(roots) do
    local it = ref.untangled.next
    local start_root, end_root = tangle_rec(name, tangled_it, "", name)
    roots[name].tangled = { start_root, end_root }
    tangled_it = end_root

  end

  return {
    sections_ll = sections_ll,

    parts_ll = parts_ll,

    asm = asm,
    roots = roots,
    tangled_ll = tangled_ll,
    untangled_ll = untangled_ll,

  }
end

function generate_header(fn, lines)
  if string.match(fn, "%.lua$") then
    table.insert(lines, "-- Generated using ntangle.nvim")
  end

  if string.match(fn, "%.vim$") then
    table.insert(lines, "\" Generated using ntangle.nvim")
  end

  if string.match(fn, "%.cpp$") or string.match(fn, "%.h$") then
    table.insert(lines, "// Generated using ntangle.nvim")
  end
end

function tangle_all(path)
  local files = vim.split(vim.fn.glob((path or "") .. "**/*.t"), "\n")

  -- kind of ugly but works
  -- first pass to write link files
  for i=1,2 do
    for _, file in ipairs(files) do
      local lines = {}
      for line in io.lines(file) do
        table.insert(lines, line)
      end

      -- skip link files
      if #lines > 1 then 
        tangle_write(vim.fn.fnamemodify(file, ":p"), lines)
      end
    end
  end
end

function generate_comment(root_name, line)
  -- Taken from http://lua-users.org/wiki/StringRecipes
  title_case = line:gsub("_", " ")
  title_case = title_case:gsub("^(%a)", string.upper)
  if string.match(root_name, "%.py$") then
    return ("# %s"):format(title_case)
  end
  return ""
end

function tangle_buf_with_comments()
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  tangle_write(filename, lines, true)
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
		style = 'minimal',
	  border = 'single',
	}

	contextmenu_win = vim.api.nvim_open_win(buf, false, opts)

	vim.api.nvim_buf_set_lines(buf, 0, -1, true, candidates)

	vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<cmd>lua require"ntangle".select_contextmenu()<CR>', {noremap = true})

	vim.api.nvim_win_set_option(contextmenu_win, "winblend", 30)
	vim.api.nvim_win_set_option(contextmenu_win, "cursorline", true)
	vim.api.nvim_set_current_win(contextmenu_win)
	contextmenu_contextmenu = callback

end

local function select_contextmenu()
	local row = vim.fn.line(".")
	if contextmenu_contextmenu then
		vim.api.nvim_win_close(contextmenu_win, true)

		contextmenu_contextmenu(row)
		contextmenu_contextmenu = nil
	end
end

local function highlight_span()
  local searched = vim.fn.expand("<cword>")


  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

  local start_part, end_part
  for part in linkedlist.iter(tangled.parts_ll) do
    if part.origin == buf then
      start_part = part.start_part
      end_part = part.end_part
      break
    end
  end

  local it = start_part
  local lnum = 1
  while it and it ~= end_part do
    local line = it.data
    if line.linetype ~= LineType.SENTINEL then
      line.lnum = lnum
      lnum = lnum + 1
    end
    it = it.next
  end



  vim.api.nvim_buf_clear_namespace(0, span_ns, 0, -1)


  local sections_ll = tangled.sections_ll 

  local highlight_all
  highlight_all = function(name, stack)
    if not sections_ll[name] then
      return
    end

    for it in linkedlist.iter(sections_ll[name]) do
      local next_section = false
      while it do
        local line = it.data
        if line.linetype ~= LineType.SENTINEL then
          if line.linetype == LineType.SECTION then
            if next_section then
              break
            else
              next_section = true
            end
          end

          if line.lnum then
            local len = string.len(line.line)
            vim.api.nvim_buf_set_extmark(0, span_ns, line.lnum-1, 0, { hl_group = "IncSearch",
            end_col = len
            })

          end

          if line.linetype == LineType.REFERENCE then
            if not vim.tbl_contains(stack, line.str) then
              table.insert(stack, line.str)
              highlight_all(line.str, stack)
              table.remove(stack)
            end

          end
        end
        it = it.next
      end

    end
  end

  if searched then
    local stack = {}
    table.insert(stack, searched)
    highlight_all(searched, stack)
  end

  local line = vim.api.nvim_get_current_line()
  local len = string.len(line)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_extmark(0, span_ns, row-1, 0, { 
    hl_group = "IncSearch",
    end_col = len
  })

  highlighted[buf] = true
  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", [[:lua require"ntangle".clear_highlight_span()<CR>]], { noremap = true, silent = true })

end

function clear_highlight_span()
  local buf = vim.fn.expand("%:p")
  if highlighted[buf] then
    vim.api.nvim_buf_clear_namespace(0, span_ns, 0, -1)

    vim.api.nvim_buf_del_keymap(0, "n", "<CR>")
    highlighted[buf] = nil
  end
end

function jump_cache(cache_file)
  create_transpose_buf()

  cache_file = vim.fn.expand(cache_file)
  local f = io.open(cache_file)
  assert(f, "Could not open " .. cache_file)
  f:close()

  local lines = {}
  for line in io.lines(cache_file) do
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, true, lines)

  local ns = vim.api.nvim_create_namespace("")
  for lnum, line in ipairs(lines) do
    local words = vim.split(line, " ")
    local fname = words[#words]
    local len = string.len(fname)
    local total_len = string.len(line)

    vim.api.nvim_buf_set_extmark(transpose_buf, ns, lnum-1, total_len-len-1, {
      end_col = total_len,
      hl_group = "NonText",
    })
  end

  vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<CR>', '<cmd>lua require"ntangle".jump_this_ref()<CR>', {noremap = true})

end

function jump_this_ref()
  local line = vim.api.nvim_get_current_line()

  local words = vim.split(line, " ")
  local fname = words[#words]
  table.remove(words)
  local ref = table.concat(words, "_")


  vim.cmd(string.format("e %s", fname))
  print(fname)

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local row
  for lnum, line in ipairs(lines) do
    if line:match("^%@" .. ref .. "%+%=") then
      row = lnum
      break
    end
  end

  if row then
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  end

end

local function show_helper()
  local buf = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  local tangled = tangle_lines(buf, lines)

	local qflist = {}
	local undefined_section = {}
	for line in linkedlist.iter(tangled.untangled_ll) do
	  if line.linetype == LineType.REFERENCE then
	    if not line.tangled or #line.tangled == 0 then
	      undefined_section[line.str] = true
	    end
	  end
	end

	local orphan_section = {}
	for line in linkedlist.iter(tangled.untangled_ll) do
	  if line.linetype == LineType.SECTION then
	    if not line.tangled or #line.tangled == 0 then
	      orphan_section[line.str] = true
	    end
	  end
	end


  for name, _ in pairs(undefined_section) do
  	table.insert(qflist, { name:gsub("_", " "), " is empty" } )
  end

  for name, _ in pairs(orphan_section) do
  	table.insert(qflist, { name:gsub("_", " ") , " orphan section" })
  end


	if #qflist == 0 then
		table.insert(qflist, { "  No warnings :)  ", "" })
	end

	local max_width = 0
	for _, line in ipairs(qflist) do
		max_width = math.max(max_width, vim.api.nvim_strwidth(line[1] .. " " .. line[2]) + 2)
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
		style = 'minimal',
	  border = 'single',
	}

	local win = vim.api.nvim_open_win(buf, false, opts)

	vim.api.nvim_win_set_option(win, "winblend", 30)

	local newlines = {}
	for _, p in ipairs(qflist) do
	  table.insert(newlines, p[1])
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, true, newlines)

  local ns_id = vim.api.nvim_create_namespace("")
  for lnum, p in ipairs(qflist) do
    vim.api.nvim_buf_set_extmark(buf, ns_id, lnum-1, 0, {
      virt_text = {{ p[2], "NonText"}}
    })
    table.insert(newlines, p[1])
  end

	close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, win)


  undefined_ns = vim.api.nvim_create_namespace("")

  for lnum, line in ipairs(lines) do
    for name, _ in pairs(undefined_section) do
      local s1, s2 = line:find("@" .. name .. "$")
      if s1 then
        vim.api.nvim_buf_set_extmark(0, undefined_ns, lnum-1, s1-1, {
          hl_group = "IncSearch",
          end_col = s2
        })

      end
    end
  end

  clear_highlight_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, undefined_ns)
end

function close_preview_autocmd(events, winnr)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_win_close, "..winnr..", true)")
end

function clear_highlight_autocmd(events, ns)
  vim.api.nvim_command("autocmd "..table.concat(events, ',').." <buffer> ++once lua pcall(vim.api.nvim_buf_clear_namespace, 0, "..ns..", 0, -1)")
end

function linkedlist.push_back(list, el)
	local node = { data = el }

	if list.tail  then
		list.tail.next = node
		node.prev = list.tail
		list.tail = node

	else
		list.tail  = node
		list.head  = node

	end
	return node

end

function linkedlist.push_front(list, el)
	local node = { data = el }

	if list.head then
		node.next = list.head
		list.head.prev = node
		list.head = node

	else
		list.tail  = node
		list.head  = node

	end
	return node

end

function linkedlist.insert_after(list, it, el)
	local node = { data = el }

  if not it then
		if not list then
		  print(debug.traceback())
		end
		node.next = list.head
		if list.head then
		  list.head.prev = node
		end
		list.head = node

  elseif it.next == nil then
		it.next = node
		node.prev = it
		list.tail = node

	else
		node.next = it.next
		node.prev = it
		node.next.prev = node
		it.next = node

	end
	return node

end

function linkedlist.remove(list, it)
	if list.head == it then
		if it.next then
			it.next.prev = nil
		else
			list.tail = nil
		end
		list.head = list.head.next

	elseif list.tail == it then
		if it.prev then
			it.prev.next = nil
		else
			list.head = nil
		end
		list.tail = list.tail.prev

	else
		it.prev.next = it.next
		it.next.prev = it.prev

	end
end

function linkedlist.get_size(list)
	local l = list.head
	local s = 0
	while l do
		l = l.next
		s = s + 1
	end
	return s
end

function linkedlist.iter_from(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.next
			return cur 
		end
	end
end

function linkedlist.iter(list)
	local pos = list.head
	return function ()
		local cur = pos
		if cur then 
			pos = pos.next
			return cur.data
		end
	end
end

function linkedlist.iter_from_back(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.prev
			return cur 
		end
	end
end
return {
build_cache = build_cache,

get_code_at_cursor = get_code_at_cursor,

get_code_at_vrange = get_code_at_vrange,

show_assemble = show_assemble,

assembleNavigate = assembleNavigate,

getRootFilename = getRootFilename,
transpose = transpose,

navigateTo = navigateTo,

tangle_buf = tangle_buf,
tangle_lines = tangle_lines,

tangle_all = tangle_all,
tangle_buf_with_comments = tangle_buf_with_comments, 
select_contextmenu = select_contextmenu,

highlight_span = highlight_span,

clear_highlight_span = clear_highlight_span,

jump_cache = jump_cache,

jump_this_ref = jump_this_ref,

show_helper = show_helper,

}
