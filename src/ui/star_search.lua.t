##../ntangle_main
@declare_functions+=
local star_search

@export_symbols+=
star_search = star_search,

@functions+=
function star_search(...)
	@get_current_line
	@get_cursor_position

	local start, stop =  string.find(line, '^%s*;+%s*')
	if start then
		local name = trim1(line:sub(stop+1))
		@decide_if_needs_to_advance
		@search_for_section_and_reference_name
	else
		@fire_default_star_search
	end
end

@fire_default_star_search+=
return "*"

@decide_if_needs_to_advance+=
local advance = ""
if col <= stop then
	advance = "n" 
end

@search_for_section_and_reference_name+=
return "/" .. name .. '<CR>' .. advance
