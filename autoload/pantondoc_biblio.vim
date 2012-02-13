function! pantondoc_biblio#InitBiblio()
	let b:pantondoc_bibs = pantondoc_biblio#Find_Bibliographies()
endfunction

function! pantondoc_biblio#Find_Bibliographies()
	if has("python")
		python pantondoc.bib.find_bibfiles()
	endif
endfunction
