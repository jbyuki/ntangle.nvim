##../ntangle_main
@functions+=
local function show_assemble()
	local lines = {}
	local curassembly

	@read_lines_from_buffer
	@read_assembly_name_if_any

	local filename = nil
	if curassembly then
		@construct_path_for_link_file
		local assembled = {}
		@glob_all_links_and_assemble_except_current
		@append_current_buffer_to_the_assembled

		@save_cursor_position
		@save_current_filetype
		@create_buffer_if_not_existent
		@get_current_window_dimensions
		@create_window_for_transpose
		local border_title = "Assembly"
		@create_border_around_transpose_window
		@setup_transpose_buffer

		@put_lines_in_assemble_buffer
		@jump_to_lines_in_assemble_buffer

		@build_navigation_lines
		@keymap_assemble_buffer
	end
end

@export_symbols+=
show_assemble = show_assemble,

@put_lines_in_assemble_buffer+=
vim.api.nvim_buf_set_lines(transpose_buf, 0, -1, false, assembled)

@jump_to_lines_in_assemble_buffer+=
vim.fn.setpos(".", {0, row+offset[fn]-1, 0, 0})

@parse_variables+=
local assemble_nav = {}

@build_navigation_lines+=
assemble_nav = {}
for i=1,#assembled do
	local org = origin[i]
	local nav = {
		lnum = i - offset[org] + 1,
		origin = org,
	}
	table.insert(assemble_nav, nav)
end

@keymap_assemble_buffer+=
vim.api.nvim_buf_set_keymap(transpose_buf, 'n', '<leader>u', '<cmd>lua require"ntangle".assembleNavigate()<CR>', {noremap = true})

@functions+=
local function assembleNavigate()
	@save_cursor_position
	@close_transpose_window
	@jump_to_linenumber_assemble
end

@export_symbols+=
assembleNavigate = assembleNavigate,

@jump_to_linenumber_assemble+=
local nav = assemble_nav[row]
if nav.origin ~= vim.api.nvim_buf_get_name(0) then
	vim.fn.nvim_command("e " .. nav.origin)
end
vim.fn.setpos(".", {0, nav.lnum, 0, 0})
