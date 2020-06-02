function! coc#source#pandoc#init() abort
	return {
				\ 'priority': 9,
				\ 'shortcut': 'pandoc',
				\ 'filetypes': ['pandoc'],
				\ 'triggerCharacters': ['@'],
				\ }
endfunction

function! coc#source#pandoc#complete(opt, cb) abort
	let l:classes = []
	let l:items = []
	let l:bibs = split(glob('%:p:h/**/*.bib'))
	for l:bib in l:bibs
		let l:lines = readfile(l:bib)
		for l:line in l:lines
			if l:line =~# '^@\l*{.*,'
				let l:items += [split(l:line, '{\|,')[1]]
			endif
		endfor
	endfor
	for l:item in l:items
		call add(l:classes, {'word': l:item})
	endfor
	call a:cb(l:classes)
endfunction
