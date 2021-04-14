##../ntangle_main
@functions+=
local function tangle_to_table(tables)
	local curassembly
	local lines = {}
  local lookup = {}
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
		@output_sections_assembly_to_tables
	else
		@clear_sections
		@read_file_line_by_line_from_variable
		@output_sections_to_tables
	end
  return lookup
end

@export_symbols+=
tangle_to_table = tangle_to_table,

@output_sections_assembly_to_tables+=
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header_assembly
    @create_table_if_none_for_output_path
    lookup[fn] = {}
		outputSectionsWithLookup(lines, file, name, "", lookup[fn])
		@set_untangled_lines_to_table
	end
end

@create_table_if_none_for_output_path+=
if not tables[fn] then
  tables[fn] = {}
end

@set_untangled_lines_to_table+=
tables[fn] = lines

@output_sections_to_tables+=
filename = filename or vim.api.nvim_buf_get_name(0)
local parendir = vim.fn.fnamemodify(filename, ":p:h" )
for name, section in pairs(sections) do
	if section.root then
		local fn
		@if_star_replace_with_current_filename
		@otherwise_put_node_name
		lines = {}
		@output_generated_header
    @create_table_if_none_for_output_path
    lookup[fn] = {}
		outputSectionsWithLookup(lines, file, name, "", lookup[fn])
    @set_untangled_lines_to_table
	end
end
