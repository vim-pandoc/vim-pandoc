" vim: set fdm=marker et ts=4 sw=4 sts=4:

" Init(): sets up defaults, populates b:pandoc_biblio_bibs {{{1
function! pandoc#bibliographies#Init()
    " set up defaults {{{2
    " Places to look for bibliographies {{{3
    " b: bibs named after the current file in the working dir
    " c: any bib in the working dir
    " l: pandoc local dir
    " t: texmf
    " g: append values in g:pandoc#biblio#bibs
    "
    if !exists("g:pandoc#biblio#sources")
        let g:pandoc#biblio#sources = "bcg"
    endif
    "}}}
    " File extensions to check for {{{3
    if !exists("g:pandoc#biblio#bib_extensions")
        let g:pandoc#biblio#bib_extensions = ["bib", "bibtex", "ris", "mods", "enl", "wos", "medline", "copac"]
    endif
    " }}}
    " Use bibtool for queries? {{{3
    if !exists("g:pandoc#biblio#use_bibtool")
        let g:pandoc#biblio#use_bibtool = 0
    endif
    "}}}
    " Files to add to b:pandoc_biblio_bibs if "g" is in g:pandoc#biblio#sources {{{3
    if !exists("g:pandoc#biblio#bibs")
        let g:pandoc#biblio#bibs = []
    endif
    " populate b:pandoc_biblio_bibs {{{2
    let b:pandoc_biblio_bibs = []
endfunction

" Find_Bibliographies(): gives a list of bibliographies in g:pandoc#biblio#sources {{{1
function! pandoc#bibliographies#Find_Bibliographies()
    if has("python")
        python import vim_pandoc.bib.vim_completer
        return pyeval("vim_pandoc.bib.vim_completer.find_bibfiles()")
    endif
    return []
endfunction

" GetSuggestions(partkey): returns bibliographic suggestions. {{{1
" called by our omnifunc, if completion is enabled
function! pandoc#bibliographies#GetSuggestions(partkey)
    if has("python")
        python import vim_pandoc.bib.vim_completer
        let l:sugs = pyeval('vim_pandoc.bib.vim_completer.VimCompleter().get_suggestions(vim.eval("a:partkey"))')
        if len(l:sugs) > 0
            return l:sugs
        else
            return []
        endif
    endif
endfunction
