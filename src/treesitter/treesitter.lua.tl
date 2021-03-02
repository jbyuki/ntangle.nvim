##../ntangle_main
@parse_variables+=
local ntangle_required

local ext_to_lang = {
  ["rs"] = "rust",
}

@functions+=
local function enable_syntax_highlighting()
	@get_language_extension
	if not ntangle_required then
		@require_ntangle_language
	end
	@create_parser_for_buffer
	@create_highlighter_for_buffer
	@set_filetype_to_original_language
end

@export_symbols+=
enable_syntax_highlighting = enable_syntax_highlighting,

@get_language_extension+=
local bufname = vim.api.nvim_buf_get_name(0)
local ext = vim.fn.fnamemodify(bufname, ":e:e:r")

@set_filetype_to_original_language+=
local lang = ext_to_lang[ext] or ext
vim.api.nvim_command("set ft=" .. lang)

@require_ntangle_language+=
local parser_dll = vim.api.nvim_get_runtime_file("ntangle.so", "all")
if #parser_dll > 0 then
	local success = vim.treesitter.require_language("ntangle", parser_dll[1])
	if success then
		ntangle_required = true
	end
end

@create_parser_for_buffer+=
local opts = {
	queries = {
		["ntangle"] = "(codeline) @combined @" .. ext
	}
}
local buf = vim.api.nvim_get_current_buf()
local parser = vim.treesitter.get_parser(buf, "ntangle", opts)

@create_highlighter_for_buffer+=
vim.treesitter.highlighter.new(parser, {})
