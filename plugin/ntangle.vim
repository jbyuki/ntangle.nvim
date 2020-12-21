" Generated from ntangle.vim.tl using ntangle.nvim
let g:tangle_dir = "tangle"
let g:tangle_cache_file = expand("~/tangle_cache.txt")

function! SaveTangle()
	let path_dir = expand("%:p:h") . "/" . g:tangle_dir
	if !isdirectory(path_dir)
		call mkdir(path_dir)
	endif
	call v:lua.ntangle.tangle()
endfunction

function! GoToTangle(args)
	let node = "*"
	if a:args =~ ":"
		let m = split(a:args, ":")
		let node = m[0]
		let linesearch = str2nr(m[1])
	else
		let linesearch = str2nr(a:args)
	endif
	
	call v:lua.ntangle.goto(expand("%:p"), linesearch, node)
endfunction

function! SaveTangleAll()
	let path_dir = expand("%:p:h") . "/" . g:tangle_dir
	if !isdirectory(path_dir)
		call mkdir(path_dir)
	endif
	call v:lua.ntangle.tangleAll()
endfunction

function! TangleShowErrors()
	call v:lua.ntangle.show_errors(expand("%:p"))
endfunction

function! TangleShowTodo()
	call v:lua.ntangle.show_todo(bufnr("%"))
endfunction

autocmd BufWrite *.tl call SaveTangle()

lua ntangle = require("ntangle")

lua buildcache = require("buildcache")

command! -nargs=1 TangleGoto call GoToTangle("<args>")

command! TangleBuildCache call v:lua.buildcache.build(fnamemodify("~/tangle_cache.txt", ":p"))

command! TangleAll call SaveTangleAll()

command! TangleCollect call v:lua.ntangle.collectSection()

command! TangleFix call TangleShowErrors()

command! TangleShowTodo call TangleShowTodo()

