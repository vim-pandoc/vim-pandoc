" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#completion#Init() abort "{{{1
    " set up defaults:
    if !exists('g:pandoc#completion#bib#mode')
        let g:pandoc#completion#bib#mode = 'fallback'
        " Note: in the future citeproc will be the default.
        "if executable('pandoc-citeproc')
        "    let g:pandoc#completion#bib#mode = 'citeproc'
        "else
        "    let g:pandoc#completion#bib#mode = 'fallback'
        "endif
    endif
    if !exists('g:pandoc#completion#bib#use_preview')
        if g:pandoc#completion#bib#mode ==# 'citeproc'
            let g:pandoc#completion#bib#use_preview = 1
        else
            let g:pandoc#completion#bib#use_preview = 0
        endif
    endif

    " set the correct omnifunc completion
    if has('python3')
        setlocal omnifunc=pandoc#completion#Complete
    endif

    if g:pandoc#completion#bib#use_preview == 1
        " handle completeopt, so the preview is enabled
        if stridx(&completeopt, 'preview') > -1
            let b:pandoc_old_cot = &completeopt
            let &completeopt = &completeopt.',preview'
            au! VimPandoc BufEnter,WinEnter <buffer> let &completeopt = b:pandoc_old_cot.'.preview'
            au! VimPandoc BufLeave,WinLeave <buffer> let &completeopt = b:pandoc_old_cot
        endif
        " close the preview window when the completion has been inserted
        au! VimPandoc CompleteDone <buffer> pclose
    endif
endfunction

function! pandoc#completion#Complete(findstart, base) abort "{{{1
    if has('python3')
        if index(g:pandoc#modules#enabled, 'bibliographies') >= 0
            if a:findstart
                let l:line = getline('.')
                if l:line[:col('.')-1] =~# '@'
                    let l:pos = searchpos('@', 'Wncb')
                    if l:pos != [0,0]
                        return l:pos[1]
                    endif
                endif
            else
                let suggestions = pandoc#bibliographies#GetSuggestions(a:base)
                return suggestions
            endif
        endif
    endif
    return -3
endfunction
