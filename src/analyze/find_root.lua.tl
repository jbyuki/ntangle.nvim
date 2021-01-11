##../ntangle_main
@declare_functions+=
local get_section

@functions+=
function get_section(lines, row)
	local containing
	local lnum = row
	while lnum >= 1 do
		local line = lines[lnum]
		@if_line_is_section_save_it_and_quit
		lnum = lnum - 1
	end

	while lnum <= #lines do
		local line = lines[lnum]
		@if_line_is_section_save_it_and_quit
		lnum = lnum + 1
	end

	assert(containing, "no containing section!")
	return containing
end

@if_line_is_section_save_it_and_quit+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@parse_section_name
	containing = name
end

@declare_functions+=
local resolve_root_section

@functions+=
function resolve_root_section(containing)
	local open = { containing }
	local explored = {}
	local roots = {}
	while #open > 0 do
		local name = open[#open]
		table.remove(open)
		explored[name] = true

		@if_root_add_to_roots

		if refs[name] then
			local parents = refs[name]
			@remove_any_parent_which_was_already_explored
			@add_remaining_to_open
		end
	end

	assert(vim.tbl_count(roots) == 1, "multiple roots or none")
	local name = vim.tbl_keys(roots)[1]
	return name
end

@if_root_add_to_roots+=
if sections[name].root then
	roots[name] = true
end

@remove_any_parent_which_was_already_explored+=
local i = 1
while i <= #parents do
	if explored[parent] then
		table.remove(parents, i)
	else
		i = i + 1
	end
end

@add_remaining_to_open+=
for _, parent in ipairs(parents) do
	table.insert(open, parent)
end
