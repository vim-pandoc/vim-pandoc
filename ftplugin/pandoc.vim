" vim: set fdm=marker et ts=4 sw=4 sts=4:

" File: ftplugin/pandoc.vim
" Description: vim-pandoc-handled buffer settings
" Author: Felipe Morales

if exists("b:pandoc_loaded") && b:pandoc_loaded == 1
    finish
endif

" Modules: {{{1
" we initialize stuff depending on the values of g:pandoc#modules#enabled and
" g:pandoc#modules#disabled so this ftplugin is simply a loader.
"
let s:enabled_modules = []
for module in g:pandoc#modules#enabled
    if index(g:pandoc#modules#disabled, module) == -1
        let s:enabled_modules = add(s:enabled_modules, module)
    endif
endfor

for module in s:enabled_modules
    exe 'call pandoc#' . module . '#Init()'
endfor

let b:pandoc_loaded = 1
