" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#completion#Init() "{{{1
    " set up defaults:
    if !exists('g:pandoc#completion#bib#mode')
        if executable('pandoc-citeproc') 
            let g:pandoc#completion#bib#mode = 'citeproc'
        else
            let g:pandoc#completion#bib#mode = 'fallback'
        endif
    endif
    if !exists('g:pandoc#completion#bib#use_preview')
        let g:pandoc#completion#bib#use_preview = 1
    endif

    " set the correct omnifunc completion
    if has("python")
        setlocal omnifunc=pandoc#completion#Complete
    endif
    if g:pandoc#completion#bib#use_preview == 1
        " handle completeopt, so the preview is enabled
        if stridx(&cot, "preview") > -1
            let b:pandoc_old_cot = &cot
            let &cot = &cot.",preview"
            au! BufLeave <buffer> let &cot = b:pandoc_old_cot
        endif
        " close the preview window when the completion has been inserted
        au! CompleteDone <buffer> pclose
    endif
endfunction

function! pandoc#completion#Complete(findstart, base) "{{{1
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
