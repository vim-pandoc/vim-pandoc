" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#sections#Init() "{{{1
    " Defaults: {{{2
    " What style to use when applying header styles {{{3
    " a: atx headers
    " s: setex headers for 1st and 2nd levels
    " 2: add hashes at both ends
    if !exists("g:pandoc#keyboard#sections#header_style")
        let g:pandoc#keyboard#sections#header_style = "a"
    endif
    " }}}2
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-apply-header) :<C-U>call pandoc#keyboard#sections#ApplyHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-remove-header) :call pandoc#keyboard#sections#RemoveHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-header) :call pandoc#keyboard#sections#NextHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-header) :call pandoc#keyboard#sections#PrevHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ff-header) :<C-U>call pandoc#keyboard#sections#ForwardHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-rw-header) :<C-U>call pandoc#keyboard#sections#BackwardHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ff-sect-end) :<C-U>call pandoc#keyboard#sections#NextSectionEnd(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-rw-sect-end) :<C-U>call pandoc#keyboard#sections#PrevSectionEnd(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-header) :call pandoc#keyboard#sections#CurrentHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-header-parent) :call pandoc#keyboard#sections#CurrentHeaderParent()<cr>
    vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-section-inclusive) :<C-U>call pandoc#keyboard#sections#SelectSection('inclusive')<cr>
    vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-section-exclusive) :<C-U>call pandoc#keyboard#sections#SelectSection('exclusive')<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-header-sibling) :call pandoc#keyboard#sections#NextSiblingHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-header-sibling) :call pandoc#keyboard#sections#PrevSiblingHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-first-header-child) :call pandoc#keyboard#sections#FirstChildHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-last-header-child) :call pandoc#keyboard#sections#LastChildHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-nth-header-child) :<C-U>call pandoc#keyboard#sections#GotoNthChildHeader(v:count1)<cr>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, "sections") == -1
        nmap <buffer> <localleader># <Plug>(pandoc-keyboard-apply-header)
        nmap <buffer> <localleader>hd <Plug>(pandoc-keyboard-remove-header)
        nmap <buffer> <localleader>hn <Plug>(pandoc-keyboard-next-header)
        nmap <buffer> <localleader>hb <Plug>(pandoc-keyboard-prev-header)
        nmap <buffer> <localleader>hh <Plug>(pandoc-keyboard-cur-header)
        nmap <buffer> <localleader>hp <Plug>(pandoc-keyboard-cur-header-parent)
        nmap <buffer> <localleader>hsn <Plug>(pandoc-keyboard-next-header-sibling)
        nmap <buffer> <localleader>hsb <Plug>(pandoc-keyboard-prev-header-sibling)
        nmap <buffer> <localleader>hcf <Plug>(pandoc-keyboard-first-header-child)
        nmap <buffer> <localleader>hcl <Plug>(pandoc-keyboard-last-header-child)
        nmap <buffer> <localleader>hcn <Plug>(pandoc-keyboard-nth-header-child)
        nmap <buffer> ]] <Plug>(pandoc-keyboard-ff-header)
        nmap <buffer> [[ <Plug>(pandoc-keyboard-rw-header)
        nmap <buffer> ][ <Plug>(pandoc-keyboard-ff-sect-end)
        nmap <buffer> [] <Plug>(pandoc-keyboard-rw-sect-end)
        vmap <buffer> aS <Plug>(pandoc-keyboard-select-section-inclusive)
        omap <buffer> aS :normal VaS<cr>
        vmap <buffer> iS <Plug>(pandoc-keyboard-select-section-exclusive)
        omap <buffer> iS :normal ViS<cr>
    endif
endfunction

" Functions: {{{1

" Handling: {{{2
function! pandoc#keyboard#sections#ApplyHeader(level) "{{{3
    call pandoc#keyboard#sections#RemoveHeader()
    if a:level == 0
        return
    endif

    let line_text = getline(".")
    if a:level < 3 && (g:pandoc#keyboard#sections#header_style =~ "s") == 1
       let text = line_text
    else
       if (g:pandoc#keyboard#sections#header_style =~ "2") == 1
           let tail = ' ' . repeat("#", a:level)
       else
           let tail = ''
       endif
       let text = repeat("#", a:level) . ' ' . line_text . tail
    endif
    call setline(line("."), text)
   
    if (g:pandoc#keyboard#sections#header_style =~ "s") == 1
        let l:len = strlen(substitute(text, '.', 'x', 'g'))
        if a:level == 1
            call append(line("."), repeat("=", l:len))
        elseif a:level == 2
            call append(line("."), repeat("-", l:len))
        endif
    endif
endfunction

function! pandoc#keyboard#sections#RemoveHeader() "{{{3
    let lnum = line(".")
    let line_text = getline(".")
    if match(line_text, "^#") > -1
        let line_text = substitute(line_text, "^#* *", '', '')
        if match(line_text, " #*$") > -1
            let line_text = substitute(line_text, " #*$", '', '')
        endif
    elseif match(getline(line(".")+1), "^[-=]") > -1
        exe line(".")+1.'delete "_'
    endif
    exe lnum
    call setline(line("."), line_text)
endfunction
" }}}2
" Navigation: {{{2
function! pandoc#keyboard#sections#NextHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#NextHeader())
endfunction

function! pandoc#keyboard#sections#PrevHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#PrevHeader())
endfunction

function! pandoc#keyboard#sections#ForwardHeader(count) "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#ForwardHeader(a:count))
endfunction

function! pandoc#keyboard#sections#BackwardHeader(count) "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#BackwardHeader(a:count))
endfunction

function! pandoc#keyboard#sections#NextSectionEnd(count) "{{{3
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#sections#NextEndSection(0, lnum)
    endfor
    call pandoc#keyboard#MovetoLine(lnum)
endfunction

function! pandoc#keyboard#sections#PrevSectionEnd(count) "{{{3
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#sections#PrevEndSection(lnum)
    endfor
    call pandoc#keyboard#MovetoLine(lnum)
endfunction

function! pandoc#keyboard#sections#CurrentHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#CurrentHeader())
endfunction

function! pandoc#keyboard#sections#CurrentHeaderParent() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#CurrentHeaderParent())
endfunction

function! pandoc#keyboard#sections#NextSiblingHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#NextSiblingHeader())
endfunction

function! pandoc#keyboard#sections#PrevSiblingHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#PrevSiblingHeader())
endfunction

function! pandoc#keyboard#sections#FirstChildHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#FirstChild())
endfunction

function! pandoc#keyboard#sections#LastChildHeader() "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#LastChild())
endfunction

function! pandoc#keyboard#sections#GotoNthChildHeader(count) "{{{3
    call pandoc#keyboard#MovetoLine(markdown#headers#NthChild(a:count))
endfunction
" "}}}2
" Objects: {{{2
function! pandoc#keyboard#sections#SelectSection(mode) "{{{3
    let range = markdown#sections#SectionRange(a:mode)
    let start= range[0]
    let end = range[1] - 1
    exe "normal! ".start."GV".end."G\<cr>"
endfunction
"}}}2
" }}}1

