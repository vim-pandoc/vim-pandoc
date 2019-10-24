" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#links#Init() abort "{{{1
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-links-open) :call pandoc#hypertext#OpenLink( g:pandoc#hypertext#edit_open_cmd )<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-links-split) :call pandoc#hypertext#OpenLink( g:pandoc#hypertext#split_open_cmd )<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-links-back) :call pandoc#hypertext#BackFromLink()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-links-file-back) :call pandoc#hypertext#BackFromFile()<cr>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, 'links') == -1
        nmap <buffer> <localleader>gl <Plug>(pandoc-keyboard-links-open)
        nmap <buffer> <localleader>sl <Plug>(pandoc-keyboard-links-split)
        nmap <buffer> <localleader>gb <Plug>(pandoc-keyboard-links-back)
        nmap <buffer> <localleader>gB <Plug>(pandoc-keyboard-links-file-back)
    endif
endfunction

