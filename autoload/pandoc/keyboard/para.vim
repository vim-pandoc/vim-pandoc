function! pandoc#keyboard#para#Init() abort
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, 'para') == -1
        noremap <buffer> <localleader>o }o<esc>O
        noremap <buffer> <localleader>O {O<esc>o
    endif
endfunction
