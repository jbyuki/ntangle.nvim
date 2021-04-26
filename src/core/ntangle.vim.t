@../../plugin/ntangle.vim=
@set_default_global_variables
@functions
@register_filetype_detection
@register_commands

@register_filetype_detection+=
autocmd BufWrite *.t lua require"ntangle".tangle_buf()

@register_commands+=
command! TangleBuildCache lua require"ntangle".build_cache(fnamemodify("~/tangle_cache.txt", ":p"))

@register_commands+=
command! TangleAll lua require"ntangle".tangle_all()
