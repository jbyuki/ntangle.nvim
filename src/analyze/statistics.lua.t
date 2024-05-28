##../ntangle_main
@functions+=
local function print_statistics()
	@tangle_current_buffer
	@print_maximum_depth
	@print_maximum_span
end

@export_symbols+=
print_statistics = print_statistics,

@tangle_current_buffer+=
local filename = vim.fn.expand("%:p")
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
local tangled = tangle_lines(filename, lines, comment)

@print_maximum_depth+=
local max_depth = {}
local get_max_depth
get_max_depth = function(name)
	if max_depth[name] then
		local path = vim.deepcopy(max_depth[name])
		table.insert(path, name)
		return path
	end

	local depth = { }
	if tangled.sections_ll[name] then
		local it
    for it in linkedlist.iter(tangled.sections_ll[name]) do
			it = it.next
			@find_maximum_depth_in_part
    end
	end

	max_depth[name] = vim.deepcopy(depth)
	table.insert(depth, name)
	return depth
end

@find_maximum_depth_in_part+=
while it do
  local line = it.data
  if line.linetype ~= LineType.SENTINEL then
    if line.linetype == LineType.REFERENCE then
			local path = get_max_depth(line.str)
			if #path > #depth then
				depth = path
			end
		elseif line.linetype == LineType.SECTION or line.linetype == LineType.ASSEMBLY then
			break
    end
  end
  it = it.next
end

@print_maximum_depth+=
for name, _ in pairs(tangled.roots) do
	local max_path = get_max_depth(name)
	print(name, " max path is ", #max_path)
	@reverse_path
	print(vim.inspect(max_path))
end

@reverse_path+=
local rev_max_path = {}
for i=1,#max_path do
	table.insert(rev_max_path, max_path[#max_path - i + 1])
end
max_path = rev_max_path

@print_maximum_span+=
local section_span = {}
local get_span
get_span = function(name)
	if section_span[name] then
		return section_span[name]
	end

	local num_span = 0
	if tangled.sections_ll[name] then
		local it
    for it in linkedlist.iter(tangled.sections_ll[name]) do
			it = it.next
			@find_span_for_part
    end
	end

	section_span[name] = num_span
	return num_span
end

@find_span_for_part+=
while it do
  local line = it.data
  if line.linetype ~= LineType.SENTINEL then
    if line.linetype == LineType.REFERENCE then
			get_span(line.str)
			num_span = num_span + 1
		elseif line.linetype == LineType.SECTION or line.linetype == LineType.ASSEMBLY then
			break
    end
  end
  it = it.next
end

@print_maximum_span+=
for name, _ in pairs(tangled.roots) do
	get_span(name)
end

local max_span = 0
local max_span_name = "NONE"

local counts = {}
local names = {}
local indices = {}

for name, span in pairs(section_span) do
	table.insert(counts, span)
	table.insert(names, name)
	table.insert(indices, #indices+1)
end

table.sort(indices, function(i1,i2) return counts[i1] > counts[i2] end)

for i=1,5 do
	print("SPAN ", counts[indices[i]], names[indices[i]])
end

