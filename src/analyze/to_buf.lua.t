##../ntangle_main
@functions+=
local function tangle_to_buf(bufs)
	local curassembly
	local lines = {}
  @read_lines_from_buffer

	@read_assembly_name_if_any
	if curassembly then
		@if_any_assembly_write_link_file
		local assembled = {}
		@glob_all_links_and_assemble
		local lines = assembled 
		@set_filename_of_assembled

		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_assembly_to_buffers
	else
		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_to_buffers
	end
end

@export_symbols+=
tangle_to_buf = tangle_to_buf,

@output_sections_assembly_to_buffers+=
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header_assembly
		outputSections(lines, file, name, "")
    @create_buffer_if_none_for_output_path
		@set_untangled_lines_to_buffer
	end
end

@create_buffer_if_none_for_output_path+=
if not bufs[fn] then
  bufs[fn] = vim.api.nvim_create_buf(false, true)
end

@set_untangled_lines_to_buffer+=
vim.api.nvim_buf_set_lines(bufs[fn], 0, -1, true, lines)

@output_sections_to_buffers+=
filename = filename or vim.api.nvim_buf_get_name(0)
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header
		outputSections(lines, file, name, "")
    @create_buffer_if_none_for_output_path
    @set_untangled_lines_to_buffer
	end
end
