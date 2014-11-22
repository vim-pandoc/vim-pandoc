" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#lists#Init() "{{{1
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-li) :call pandoc#keyboard#lists#NextListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-li) :call pandoc#keyboard#lists#PrevListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-li) :call pandoc#keyboard#lists#CurrentListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-li-parent) :call pandoc#keyboard#lists#CurrentListItemParent()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-li-sibling) :call pandoc#keyboard#lists#NextListItemSibling()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-li-sibling) :call pandoc#keyboard#lists#PrevListItemSibling()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-first-li-child) :call pandoc#keyboard#lists#FirstListItemChild()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-last-li-child) :call pandoc#keyboard#lists#LastListItemChild()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-nth-li-child) :<C-U>call pandoc#keyboard#lists#GotoNthListItemChild(v:count1)<cr>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, "lists") == -1
        nmap <buffer> <localleader>ln <Plug>(pandoc-keyboard-next-li)
        nmap <buffer> <localleader>lp <Plug>(pandoc-keyboard-prev-li)
        nmap <buffer> <localleader>ll <Plug>(pandoc-keyboard-cur-li)
        nmap <buffer> <localleader>llp <Plug>(pandoc-keyboard-cur-li-parent)
        nmap <buffer> <localleader>lsn <Plug>(pandoc-keyboard-next-li-sibling)
        nmap <buffer> <localleader>lsp <Plug>(pandoc-keyboard-prev-li-sibling)
        nmap <buffer> <localleader>lcf <Plug>(pandoc-keyboard-first-li-child)
        nmap <buffer> <localleader>lcl <Plug>(pandoc-keyboard-last-li-child)
        nmap <buffer> <localleader>lcn <Plug>(pandoc-keyboard-nth-li-child)
    endif
endfunction

" Functions: {{{1

function! pandoc#keyboard#lists#NextListItem() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#NextListItem())
endfunction

function! pandoc#keyboard#lists#PrevListItem() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#PrevListItem())
endfunction

function! pandoc#keyboard#lists#CurrentListItem() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#CurrentListItem())
endfunction

function! pandoc#keyboard#lists#CurrentListItemParent() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#CurrentListItemParent())
endfunction

function! pandoc#keyboard#lists#NextListItemSibling() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#NextListItemSibling())
endfunction

function! pandoc#keyboard#lists#PrevListItemSibling() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#PrevListItemSibling())    
endfunction

function! pandoc#keyboard#lists#FirstListItemChild() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#FirstChild())
endfunction

function! pandoc#keyboard#lists#LastListItemChild() "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#LastChild())
endfunction

function! pandoc#keyboard#lists#GotoNthListItemChild(count) "{{{2
    call pandoc#keyboard#MovetoLine(markdown#lists#NthChild(a:count))
endfunction
