if ( exists('g:loaded_ctrlp_tangle') && g:loaded_ctrlp_tangle )
	\ || v:version < 700 || &cp
	finish
endif
let g:loaded_ctrlp_tangle = 1

call add(g:ctrlp_ext_vars, {
	\ 'init':  'ctrlp#tangle#init()',
	\ 'accept':'ctrlp#tangle#accept',
	\ 'lname': 'long statusline name',
	\ 'sname': 'shortname',
	\ 'type':  'line',
	\ 'sort': 0,
	\ })

let s:sections = []

function! ctrlp#tangle#init()
	if len(s:sections) == 0
		let s:sections = readfile(expand("~/tangle_cache.txt"))
	endif
	return s:sections
endfunction

function! ctrlp#tangle#accept(mode, str)
	" For this example, just exit ctrlp and run help
	call ctrlp#exit()
	let comp = split(a:str, ' ')
	call execute("edit " . comp[-1])
	call search('@' . join(comp[0:-2], '_') . '[+\-]\?=')
endfunction

" (optional) Do something before enterting ctrlp
function! ctrlp#tangle#enter()
endfunction


" (optional) Do something after exiting ctrlp
function! ctrlp#tangle#exit()
endfunction


" (optional) Set or check for user options specific to this extension
function! ctrlp#tangle#opts()
endfunction


" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

" Allow it to be called later
function! ctrlp#tangle#id()
	return s:id
endfunction
