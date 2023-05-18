##../ntangle_main
@functions+=
local function build_cache(filename)
	filename = filename or "~/ntangle_cache.txt"
	@get_filelist
	@cache_variables
	@foreach_file_get_all_sections
	@save_cache_file
end

@export_symbols+=
build_cache = build_cache,

@get_filelist+=
local tangle_code_dir = vim.fn.expand("~/fakeroot/code")
local filelist = vim.api.nvim_call_function("glob", { tangle_code_dir .. "/**/*.t" })

@foreach_file_get_all_sections+=
for file in vim.gsplit(filelist, "\n") do
	@init_ref_set
	@read_file_line_by_line
	@add_ref_set_to_global
end

@read_file_line_by_line+=
for line in io.lines(file) do
	@if_its_a_section_add_ref
end

@if_its_a_section_add_ref+=
if string.match(line, "^@[^@]%S*[+-]?=%s*$") then
	@extract_section_name
	@save_section_ref
end

@extract_section_name+=
local _, _, name, op = string.find(line, "^@(%S-)([+-]?=)%s*$")

@init_ref_set+=
local filerefs = {}

@save_section_ref+=
filerefs[name] = true

@cache_variables+=
local globalcache = {}

@add_ref_set_to_global+=
globalcache[file] = filerefs

@save_cache_file+=
local cache = io.open(vim.fn.expand(filename), "w")
for file, filerefs in pairs(globalcache) do
	for name,_ in pairs(filerefs) do
		local name_words = string.gsub(name, "_+", " ")
		cache:write(name_words .. " " .. file .. "\n")
	end
end
cache:close()
print("Cache written to " .. filename .. " !")
