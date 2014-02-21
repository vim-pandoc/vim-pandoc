" vim: set fdm=marker fdc=2: {{{1

" File: ftplugin/pantondoc.vim
" Description: pantondoc-handled buffer settings
" Author: Felipe Morales

if exists("b:pantondoc_loaded") && b:pantondoc_loaded == 1
    finish
endif

" Modules: {{{1
" we initialize stuff depending on the values of g:pantondoc_enabled_modules and
" g:pantondoc_disabled_modules so this ftplugin is simply a loader.
"
let s:enabled_modules = []
for module in g:pantondoc_enabled_modules
    if index(g:pantondoc_disabled_modules, module) == -1
	let s:enabled_modules = add(s:enabled_modules, module)
    endif
endfor

for module in s:enabled_modules
    exe 'call pantondoc#' . module . '#Init()'
endfor

let b:pantondoc_loaded = 1
