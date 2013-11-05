" populates b:pantondoc_bibs
function! pantondoc_biblio#InitBiblio()
    let b:pantondoc_bibs = pantondoc_biblio#Find_Bibliographies()
endfunction

" gives a list of bibliographies in g:pantondoc_biblio_sources
function! pantondoc_biblio#Find_Bibliographies()
    if has("python")
	python import pantondoc.bib
	return pyeval("pantondoc.bib.find_bibfiles()")
    endif
    return []
endfunction

" returns bibliographic suggestions.
" called by our omnifunc, if completion is enabled
function! pantondoc_biblio#GetSuggestions(partkey)
    if has("python")
	python import pantondoc.bib
	return pyeval("pantondoc.bib.get_suggestions()")
    endif
endfunction
