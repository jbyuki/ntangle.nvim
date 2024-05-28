##../ntangle_main
@declare_functions+=
local autocomplete_v2

@functions+=
function autocomplete_v2(findstart, base)
	@get_current_line
	@get_cursor_position
	if findstart == 1 then
		@find_col_where_completion_should_start
	else
		@completion_candidate_list
		@scan_section_and_references_in_current_buffer
		@scan_section_and_references_in_opened_buffer
		@return_completition_candidates
	end
end

@export_symbols+=
autocomplete_v2 = autocomplete_v2,

@get_cursor_position+=
local  col= vim.fn.col('.')

@find_col_where_completion_should_start+=
local start, stop =  string.find(line, '^%s*;+%s*')
if not start then
	return -3
end
return stop


@completion_candidate_list+=
local candidates = {}
local candidates_list = {}

@functions+=

@scan_section_and_references_in_current_buffer+=
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
for _, l in ipairs(lines) do
	@add_line_to_candidates_list
end

@add_line_to_candidates_list+=
local start, stop = l:find('^%s*;+%s*')
if start then
	local name = trim1(l:sub(stop+1))
	if #base == 0 or (#base < #name and name:sub(1,#base) == base) then
		if not candidates[name] then
			table.insert(candidates_list, name)
			candidates[name] = true
		end
	end
end

@scan_section_and_references_in_opened_buffer+=
local bufs = vim.api.nvim_list_bufs()

for _, buf in ipairs(bufs) do
	if vim.api.nvim_buf_is_loaded(buf) then
		if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e") == "t2" then
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			for _, l in ipairs(lines) do
				@add_line_to_candidates_list
			end
		end
	end
end

@return_completition_candidates+=
return candidates_list


