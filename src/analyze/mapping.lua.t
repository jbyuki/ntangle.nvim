##../ntangle_main
@functions+=
local function get_location_list()
	local curassembly
	local lines = {}
	@read_lines_from_buffer

  @save_cursor_position
  @read_assembly_name_if_any

	local tangled = {}
	local filename

	if curassembly then
		@construct_path_for_link_file
		
		local assembled = {}
		@glob_all_links_and_assemble

		local rootlines = lines
		local lines = assembled
		@clear_sections
		@read_file_line_by_line_from_variable

		@get_containing_root_section

		@set_filename_of_assembled
		@tangle_for_containing_section

    @increase_all_line_number_by_one_for_assembly_header

    return tangled
  else
		@clear_sections
		@read_file_line_by_line_from_variable
		@set_filename_of_current_buf

		local rootlines = lines
		@get_containing_root_section
		@tangle_for_containing_section

    return tangled
  end
end

@export_symbols+=
get_location_list = get_location_list,

@o+=
local

@increase_all_line_number_by_one_for_assembly_header+=
for _, line in ipairs(tangled) do
  local prefix, l = unpack(line)
  if l and l.lnum then
    l.lnum = l.lnum + 1
  end
end
