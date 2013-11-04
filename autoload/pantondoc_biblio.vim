function! pantondoc_biblio#InitBiblio()
	let b:pantondoc_bibs = pantondoc_biblio#Find_Bibliographies()
endfunction

function! pantondoc_biblio#Find_Bibliographies()
	if has("python")
	    python import pantondoc_bib
	    python pantondoc_bib.find_bibfiles()
	endif
endfunction

function! pantondoc_biblio#GetSuggestions(partkey)
	if has("python")
	    python import pantondoc_bib
	    python pantondoc_bib.get_suggestions()
	endif
endfunction
