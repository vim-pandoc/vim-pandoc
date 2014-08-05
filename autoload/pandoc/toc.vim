" vim: set fdm=marker et ts=4 sw=4 sts=4:

" Init(): set up defaults, create TOC command {{{1
function! pandoc#toc#Init()
    " set up defaults {{{2
    " where to open the location list {{{3
    if !exists("g:pandoc#toc#position")
        let g:pandoc#toc#position = "right"
    endif
    if !exists("g:pandoc#toc#close_after_navigating")
        let g:pandoc#toc#close_after_navigating = 1
    endif
    " create :TOC command {{{2
    command! -buffer TOC call pandoc#toc#Show()
    "}}}
endfunction

" Show(): show a table of contents using the quickfix window. {{{1
" based on plasticboy/vim-markdown implementation by cirosantilli
function! pandoc#toc#Show()
    let bufname=expand("%")

    " prepare the location-list buffer
    call pandoc#toc#Update()
    if g:pandoc#toc#position == "right"
        let toc_pos = "vertical"
    elseif g:pandoc#toc#position == "left"
        let toc_pos = "topleft vertical"
    elseif g:pandoc#toc#position == "top"
        let toc_pos = "topleft"
    elseif g:pandoc#toc#position == "bottom"
        let toc_pos = "botright"
    else
        let toc_pos == "vertical"
    endif
    try
        exe toc_pos . " lopen"
    catch /E776/ " no location list
        echohl ErrorMsg
        echom "pandoc:toc: no places to show"
        echohl None
        return
    endtry

    call pandoc#toc#ReDisplay(bufname)
    " move to the top
    normal! gg
endfunction

" Update(): update location list {{{1
function! pandoc#toc#Update()
    try
        silent lvimgrep /\(^\S.*\(\n[=-]\+\n\)\@=\|^#\{1,6}[^.]\|\%^%\)/ %
    catch /E480/
        return
    catch /E499/ " % has no name
        return
    endtry
endfunction

" ReDisplay(bufname): Prepare the location list window four our uses {{{1
function! pandoc#toc#ReDisplay(bufname)
    if len(getloclist(0)) == 0
        lclose
        return
    endif
    let &winwidth=(&columns/3)
    execute "setlocal statusline=pandoc#TOC:".escape(a:bufname, ' ')

    " change the contents of the location-list buffer
    set modifiable
    silent %s/\v^([^|]*\|){2,2} #//e
    for l in range(1, line("$"))
        " this is the location-list data for the current item
        let d = getloclist(0)[l-1]
        " titleblock
        if match(d.text, "^%") > -1
            let l:level = 0
        " atx headers
        elseif match(d.text, "^#") > -1
            let l:level = len(matchstr(d.text, '#*', 'g'))-1
            let d.text = '· '.d.text[l:level+2:]
        " setex headers
        else
            let l:next_line = getbufline(bufname(d.bufnr), d.lnum+1)
            if match(l:next_line, "=") > -1
        	let l:level = 0
            elseif match(l:next_line, "-") > -1
        	let l:level = 1
            endif
            let d.text = '· '.d.text
        endif
        call setline(l, repeat(' ', 2*l:level-1). d.text)
    endfor
    set nomodified
    set nomodifiable

    " re-highlight the quickfix buffer
    syn match pandocTocHeader /^.*\n/
    syn match pandocTocBullet /·/ contained containedin=pandocTocHeader
    syn match pandocTocTitle /^%.*\n/
    hi link pandocTocHeader Title
    hi link pandocTocTitle Directory
    hi link pandocTocBullet Delimiter

    setlocal linebreak

    noremap <buffer> q :lclose<CR>
    if g:pandoc#toc#close_after_navigating == 1
        let mod = ""
        noremap <buffer> <C-CR> <CR>
    else
        let mod = "C-"
    endif
    exe "noremap <buffer> <".mod."CR> <CR>:lclose<CR>"
endfunction
