" vim: set fdm=marker et ts=4 sw=4 sts=4:

" set the correct omnifunc completion
function! pandoc#completion#Init()
    if has("python")
        setlocal omnifunc=pandoc#completion#Complete
    endif
endfunction

function! pandoc#completion#Complete(findstart, base)
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
            if index(g:pandoc#modules#enabled, "bibliographies") >= 0 &&
                        \ s:completion_type == 'bib'
                " suggest BibTeX entries
                let suggestions = pandoc#bibliographies#GetSuggestions(a:base)
            endif
            return suggestions
        endif
    endif
    return -3
endfunction
