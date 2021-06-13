-- Generated using ntangle.nvim
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")

local cache


local function ntangle_picker()
	if not cache then
		cache = {}
		local cache_filename = vim.fn.fnamemodify("~/tangle_cache.txt", ":p")
		for line in io.lines(cache_filename) do
			local terms = {}
			for term in vim.gsplit(line, " ") do
				table.insert(terms, term)
			end
			local filename = terms[#terms]
			table.remove(terms)
			table.insert(cache, {
				name = table.concat(terms, " "),
				filename = filename
			})
		end
	end

	pickers.new {
		prompt_title = "ntangle section search",
		finder = finders.new_table {
			results = cache,
			entry_maker = function(section)
				return {
					ordinal = section.name,
					display = section.name .. " [" .. vim.fn.fnamemodify(section.filename, ":~") .. "]",
					filename = section.filename
				}
			end
		},
		sorter = sorters.fuzzy_with_index_bias(),
		previewer = previewers.cat.new({}),
	}:find()
end

return {
	ntangle_picker = ntangle_picker,
}


