" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#links#Init() "{{{1
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-links-open) :call pandoc#hypertext#OpenLink()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-back-from-header) :call pandoc#hypertext#GotoSavedCursor()<cr>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, "links") == -1
        nmap <buffer> <localleader>gl <Plug>(pandoc-keyboard-links-open)
        nmap <buffer> <localleader>gb <Plug>(pandoc-keyboard-back-from-header)
    endif
endfunction

