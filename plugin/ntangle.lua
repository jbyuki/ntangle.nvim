vim.api.nvim_create_autocmd("BufWrite", { pattern = {"*.t"}, callback = function(ev) require"ntangle".tangle_buf() end })
vim.api.nvim_create_autocmd("BufWrite", { pattern = {"*.t2"}, callback = function(ev) require"ntangle".tangle_buf_v2() end })
vim.api.nvim_create_autocmd("BufRead", { pattern = {"*.t2"}, callback = function(ev)
		vim.bo.completefunc = [[v:lua.require'ntangle'.autocomplete_v2]]
		vim.keymap.set("n", "*", require"ntangle".star_search, { buffer = true, noremap = true, expr=true })
end })

vim.api.nvim_create_user_command("TangleBuildCache", function(...) 
	local dir = vim.fn.fnamemodify("~/tangle_cache.txt", ":p")
	require"ntangle".build_cache(dir) 
end, { bang = true})

vim.api.nvim_create_user_command("TangleAll", function(...) require"ntangle".tangle_all() end, { bang = true})
vim.api.nvim_create_user_command("TangleAllV2", function(...) require"ntangle".tangle_all_v2() end, { bang = true})

vim.api.nvim_create_user_command("TangleMigrateV2", function(...) require"ntangle".tangle_migrate_v2() end, { bang = true})

