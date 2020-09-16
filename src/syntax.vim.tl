@syntax.vim=
@fetch_extension
@fetch_filetype_from_extension
@set_code_syntax
@if_vim_extension_add_to_cluster
@if_lua_fix_some_syntax
@set_tangle_syntax

@fetch_extension+=
let ext = expand("%:e:e:r")

@fetch_filetype_from_extension+=
let lang = ""
let matching = uniq(sort(filter(split(execute('autocmd filetypedetect'), "\n"), 'v:val =~ "\*\." . ext')))

if len(matching) >= 1 && matching[0]  =~ 'setf'
   let lang = matchstr(matching[0], 'setf\s\+\zs\k\+')
elseif len(matching) >= 1 && matching[0]  =~ 'filetype'	
   let lang = matchstr(matching[0], 'filetype=\zs\k\+')
endif

@set_code_syntax+=
call execute("set filetype=" . lang)

@set_tangle_syntax+=
syntax match ntangleSection /^@[^[:space:]@]\+[+\-]\?=\s*$/
syntax match ntangleSectionReference /^\s*@[^=@[:space:]]\+\s*$/
highlight link ntangleSectionReference Special
highlight link ntangleSection Special

@if_vim_extension_add_to_cluster+=
if lang == "vim"
	syn cluster vimFuncBodyList	add=ntangleSection,ntangleSectionReference
endif

@if_lua_fix_some_syntax+=
if lang == "lua"
	syn clear luaError	
	syn match  luaNonError "\<\%(end\|else\|elseif\|then\|until\|in\)\>"
	hi def link luaNonError	Statement
endif
