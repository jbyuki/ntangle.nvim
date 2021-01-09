##ntangle_main
@functions+=
local function collectSection()
	@clear_sections
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
	@read_file_line_by_line_from_variable
	@get_section_name_of_current_line
	@collect_recursively_lines
	@save_current_buffer

	@create_buffer_if_not_existent
	@get_current_window_dimensions
	@create_window_for_transpose
	@create_border_around_transpose_window
	@keymap_transpose_buffer
	@switch_to_buffer
	@clear_buffer
	@put_lines_in_buffer
	@remove_last_line_in_buffer
	@save_lines_for_navigation
	@jump_to_lines_in_transpose_buffer
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

@parse_variables+=
local lineRefs = {}

@save_line_reference+=
lineRefs[lnum] = curSection.str

@clear_sections+=
lineRefs = {}

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

@switch_to_buffer+=
vim.api.nvim_set_current_buf(transpose_buf)

@clear_buffer+=
vim.api.nvim_command("normal ggdG")

@put_lines_in_buffer+=
local lnumtr = 0
for _,line in ipairs(lines) do
	local lnum, text = unpack(line)
	vim.api.nvim_buf_set_lines(transpose_buf, lnumtr, lnumtr, false, { text })
	lnumtr = lnumtr + 1
end

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

@jump_to_lines_in_transpose_buffer+=
if jumpline then
	vim.api.nvim_call_function("cursor", { jumpline, curcol-1 })
end

@remove_last_line_in_buffer+=
vim.api.nvim_command("normal Gddgg")
