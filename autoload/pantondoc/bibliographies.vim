" populates b:pantondoc#bibs
function! pantondoc#bibliographies#Init()
    let b:pantondoc_bibs = pantondoc#bibliographies#Find_Bibliographies()
endfunction

" gives a list of bibliographies in g:pantondoc_biblio_sources
function! pantondoc#bibliographies#Find_Bibliographies()
    if has("python")
	python import pantondoc.bib
	return pyeval("pantondoc.bib.find_bibfiles()")
    endif
    return []
endfunction

" returns bibliographic suggestions.
" called by our omnifunc, if completion is enabled
function! pantondoc#bibliographies#GetSuggestions(partkey)
    if has("python")
	python import pantondoc.bib
	return pyeval("pantondoc.bib.get_suggestions()")
    endif
endfunction
