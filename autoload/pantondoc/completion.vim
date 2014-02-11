" set the correct omnifunc completion
function! pantondoc#completion#Init()
    if has("python")
	setlocal omnifunc=pantondoc#completion#Complete
    endif
endfunction

function! pantondoc#completion#Complete(findstart, base)
    if has("python")
	if a:findstart
	    " return the starting position of the word
	    let line = getline('.')
	    let pos = col('.') - 1
	    while pos > 0 && line[pos - 1] !~ '\\\|{\|\[\|<\|\s\|@\|\^'
		let pos -= 1
	    endwhile

	    let line_start = line[:pos-1]
	    if line_start =~ '.*@$'
		let s:completion_type = 'bib'
	    else
		let s:completion_type = ''
	    endif
	    return pos
	else
	    "return suggestions in an array
	    let suggestions = []
	    if index(g:pantondoc_enabled_modules, "bibliographies") >= 0 && 
			\ s:completion_type == 'bib'
		" suggest BibTeX entries
		let suggestions = pantondoc#bibliographies#GetSuggestions(a:base)
	    endif
	    return suggestions
	endif
    endif
    return -3
endfunction
