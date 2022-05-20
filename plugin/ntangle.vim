" Generated using ntangle.nvim
autocmd BufWrite *.t lua require"ntangle".tangle_buf()

command! TangleBuildCache lua require"ntangle".build_cache(fnamemodify("~/tangle_cache.txt", ":p"))

command! TangleAll lua require"ntangle".tangle_all()

command! TangleWithComments lua require"ntangle".tangle_buf_with_comments()
