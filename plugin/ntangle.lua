vim.cmd [[autocmd BufWrite *.t lua require"ntangle".tangle_buf()]]
vim.cmd [[autocmd BufWrite *.t2 lua require"ntangle".tangle_buf_v2()]]

vim.cmd [[command! TangleBuildCache lua require"ntangle".build_cache(fnamemodify("~/tangle_cache.txt", ":p"))]]

vim.cmd [[command! TangleAll lua require"ntangle".tangle_all()]]

vim.cmd [[command! TangleWithComments lua require"ntangle".tangle_buf_with_comments()]]
