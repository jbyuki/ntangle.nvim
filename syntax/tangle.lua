let ext = expand("%:e:e:r")

let lang = ""
let matching = uniq(sort(filter(split(execute('autocmd filetypedetect'), "\n"), 'v:val =~ "\*\." . ext')))

if len(matching) >= 1 && matching[0]  =~ 'setf'
   let lang = matchstr(matching[0], 'setf\s\+\zs\k\+')
elseif len(matching) >= 1 && matching[0]  =~ 'filetype'	
   let lang = matchstr(matching[0], 'filetype=\zs\k\+')
endif

call execute("set filetype=" . lang)

if lang == "vim"
	syn cluster vimFuncBodyList	add=ntangleSection,ntangleSectionReference
endif

if lang == "lua"
	syn clear luaError	
	syn match  luaNonError "\<\%(end\|else\|elseif\|then\|until\|in\)\>"
	hi def link luaNonError	Statement
endif
syntax match ntangleSection /^@[^[:space:]@]\+[+\-]\?=\s*$/
syntax match ntangleSectionReference /^\s*@[^=@[:space:]]\+\s*$/
highlight link ntangleSectionReference Special
highlight link ntangleSection Special


