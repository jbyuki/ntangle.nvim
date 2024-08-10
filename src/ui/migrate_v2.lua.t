##../ntangle_main
@declare_functions+=
local tangle_migrate_v2

@export_symbols+=
tangle_migrate_v2 = tangle_migrate_v2 ,

@functions+=
function tangle_migrate_v2(path)
	@glob_all_tangle_files

	for _, file in ipairs(files) do
		@read_lines_from_file
		if #lines > 1 then
			@tangle_variables
			@define_parse
			@parse_for_migration
			@output_all_to_v2
			@write_out_file_migrated
		end
	end
end

@parse_migration_variables+=
local untangled_ll = {}

@parse_for_migration+=
parse(nil, lines, nil)

@output_all_to_v2+=
local lines_v2 = {}
for line in linkedlist.iter(untangled_ll) do
  if line.linetype == LineType.TEXT then
		@output_text_line_v2
	elseif line.linetype == LineType.REFERENCE then
		@output_reference_line_v2
	elseif line.linetype == LineType.SECTION then
		@output_section_line_v2
	elseif line.linetype == LineType.ASSEMBLY then
		@output_assembly_line_v2
	end
end

@output_text_line_v2+=
table.insert(lines_v2, line.str)

@output_reference_line_v2+=
table.insert(lines_v2, ("%s; %s"):format(line.prefix, line.str:gsub("_", " ")))

@output_section_line_v2+=
if roots[line.str] then
	table.insert(lines_v2, (":: %s"):format( line.str))
else
	if line.op == "-=" then
		table.insert(lines_v2, (";;- %s"):format( line.str:gsub("_", " ")))
	else
		table.insert(lines_v2, (";; %s"):format(line.str:gsub("_", " ")))
	end
end

@output_assembly_line_v2+=
table.insert(lines_v2,(";;; %s"):format(vim.trim(line.line:sub(3)):gsub("_", " ")))

@write_out_file_migrated+=
local t2_file = file .. "2"
local new_f = io.open(t2_file, "w")
for _, line in ipairs(lines_v2) do 
	new_f:write(line .. "\n")
end
new_f:close()
