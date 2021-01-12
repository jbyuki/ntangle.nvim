##ntangle_main
@functions+=
local function collectSection()
	local curassembly
	local lines = {}
	@read_lines_from_buffer

	@save_cursor_position

	@create_buffer_if_not_existent
	@get_current_window_dimensions
	@create_window_for_transpose
	@create_border_around_transpose_window

	@read_assembly_name_if_any
	
	local tangled = {}
	if curassembly then
	else
		@clear_sections
		@read_file_line_by_line_from_variable

		local rootlines = lines
		@get_containg_section_name
		@tangle_for_containing_section
		@search_in_tangled_the_line_where_the_cursor_was
		@put_lines_in_buffer
		@jump_to_lines_in_transpose_buffer
	end

	-- @get_section_name_of_current_line
	-- @collect_recursively_lines
	-- @save_current_buffer
-- 
	-- @keymap_transpose_buffer
	-- @save_lines_for_navigation
end

@export_symbols+=
collectSection = collectSection,

@check_if_section_is_present+=
local s
for n, section in pairs(sections) do
	if n == name then
		s = section
		break
	end
end
if not s then return end

@declare_functions+=
local collectLines

@functions+=
function collectLines(name, lines, prefix, curnum)
	local jumpline
	@check_if_section_is_present
	@collect_every_line_in_section
	return jumpline
end

@collect_every_line_in_section+=
for section in linkedlist.iter(s.list) do
	for line in linkedlist.iter(section.lines) do
		if line.lnum == curnum then jumpline = #lines+1 end

		if line.linetype == LineType.TEXT then table.insert(lines, { line.lnum, prefix .. line.str })
		elseif line.linetype == LineType.REFERENCE then 
			jumpline = collectLines(line.str, lines, prefix .. line.prefix, curnum) or jumpline
		end
	end
end

@collect_recursively_lines+=
local lines = {}
@get_expanded_name_from_current_buffer
@output_generated_header_fake
local jumpline = collectLines(name, lines, "", curnum)

@get_section_name_of_current_line+=
local curnum = vim.api.nvim_call_function("line", {"."})
local name = lineRefs[curnum]

@create_buffer_if_not_existent+=
local transpose_buf = vim.api.nvim_create_buf(false, true)
local old_ft = vim.api.nvim_buf_get_option(0, "ft")
if old_ft then
	vim.api.nvim_buf_set_option(transpose_buf, "ft", old_ft)
end
-- vim.api.nvim_buf_set_name(transpose_buf, "transpose")


@keymap_transpose_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>i', '<cmd>lua navigateTo()<CR>', {noremap = true})

@parse_variables+=
local nagivationLines = {}

@save_current_buffer+=
local originbuf = vim.api.nvim_call_function("bufnr", {})
local curcol = vim.api.nvim_call_function("col", {"."})

@save_lines_for_navigation+=
navigationLines = {}
for _,line in ipairs(lines) do 
	local lnum, _ = unpack(line)
	navigationLines[#navigationLines+1] = { buf = originbuf, lnum = lnum }
end

@functions+=
function navigateTo()
	@get_current_line_number
	@switch_to_back_to_buffer
	@jump_to_linenumber
end

@get_current_line_number+=
local curline = vim.api.nvim_call_function("line", {'.'})
local curcol = vim.api.nvim_call_function("col", {'.'})
local nav = navigationLines[curline]

@jump_to_linenumber+=
vim.api.nvim_call_function("cursor", { nav.lnum, curcol })

@remove_last_line_in_buffer+=
vim.api.nvim_buf_set_lines(transpose_buf, -2, -1, false, {})

@save_cursor_position+=
local _, row, _, _ = unpack(vim.fn.getpos("."))

@get_containg_section_name+=
print("row " .. row)
local containing = get_section(rootlines, row)

@tangle_for_containing_section+=
local tangled = {}
outputSectionsFull(tangled, containing)

@search_in_tangled_the_line_where_the_cursor_was+=
local jumpline

for lnum, line in ipairs(tangled) do
	local _, l = unpack(line)
	if l.lnum == row then
		jumpline = lnum
		break
	end
end

assert(jumpline, "Could not find line to jump")

@put_lines_in_buffer+=
local transpose_lines = {}
for _, l in ipairs(tangled) do
	local prefix, line = unpack(l)
	table.insert(transpose_lines, prefix .. line.str)
end

vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, transpose_lines)

@jump_to_lines_in_transpose_buffer+=
vim.fn.setpos(".", {0, jumpline, 0, 0})
