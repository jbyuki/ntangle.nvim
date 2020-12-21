@*=
@set_default_global_variables
@functions
@register_filetype_detection
@load_lua_module
@register_commands

@set_default_global_variables+=
let g:tangle_dir = "tangle"
let g:tangle_cache_file = expand("~/tangle_cache.txt")

@functions+=
function! SaveTangle()
	let path_dir = expand("%:p:h") . "/" . g:tangle_dir
	if !isdirectory(path_dir)
		call mkdir(path_dir)
	endif
	call v:lua.ntangle.tangle()
endfunction

@register_filetype_detection+=
autocmd BufWrite *.tl call SaveTangle()

@load_lua_module+=
lua ntangle = require("ntangle")

@functions+=
function! GoToTangle(args)
	@parse_argument
	call v:lua.ntangle.goto(expand("%:p"), linesearch, node)
endfunction

@parse_argument+=
let node = "*"
if a:args =~ ":"
	let m = split(a:args, ":")
	let node = m[0]
	let linesearch = str2nr(m[1])
else
	let linesearch = str2nr(a:args)
endif

@register_commands+=
command! -nargs=1 TangleGoto call GoToTangle("<args>")

@load_lua_module+=
lua buildcache = require("buildcache")

@register_commands+=
command! TangleBuildCache call v:lua.buildcache.build(fnamemodify("~/tangle_cache.txt", ":p"))

@functions+=
function! SaveTangleAll()
	let path_dir = expand("%:p:h") . "/" . g:tangle_dir
	if !isdirectory(path_dir)
		call mkdir(path_dir)
	endif
	call v:lua.ntangle.tangleAll()
endfunction

@register_commands+=
command! TangleAll call SaveTangleAll()

@register_commands+=
command! TangleCollect call v:lua.ntangle.collectSection()

@functions+=
function! TangleShowErrors()
	call v:lua.ntangle.show_errors(expand("%:p"))
endfunction

@register_commands+=
command! TangleFix call TangleShowErrors()

@functions+=
function! TangleShowTodo()
	call v:lua.ntangle.show_todo(bufnr("%"))
endfunction

@register_commands+=
command! TangleShowTodo call TangleShowTodo()
