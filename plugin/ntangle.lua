vim.api.nvim_create_autocmd("BufWrite", { pattern = {"*.t"}, callback = function(ev) require"ntangle".tangle_buf() end })
vim.api.nvim_create_autocmd("BufWrite", { pattern = {"*.t2"}, callback = function(ev) require"ntangle".tangle_buf_v2() end })
vim.api.nvim_create_autocmd("BufRead", { pattern = {"*.t2"}, callback = function(ev)
		vim.bo.completefunc = [[v:lua.require'ntangle'.autocomplete_v2]]
end })

vim.cmd [[command! TangleBuildCache lua require"ntangle".build_cache(fnamemodify("~/tangle_cache.txt", ":p"))]]

vim.cmd [[command! TangleAll lua require"ntangle".tangle_all()]]

vim.cmd [[command! TangleWithComments lua require"ntangle".tangle_buf_with_comments()]]
