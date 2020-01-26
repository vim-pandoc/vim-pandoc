function! pandoc#keyboard#para#Init() abort
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, 'para') == -1
        noremap <localleader>o }o<esc>O
        noremap <localleader>O {O<esc>o
    endif
endfunction
