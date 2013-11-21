" vim: set fdm=marker fdc=2: {{{1

" File: ftplugin/pantondoc.vim
" Description: pantondoc-handled buffer settings
" Author: Felipe Morales
" Version: alpha.mark2 }}}1

" Modules: {{{1
" depending on the value of g:pantondoc_enabled_modules, we initialize stuff,
" so this ftplugin is simply a loader.
"
" Formatting: {{{2
if index(g:pantondoc_enabled_modules, "formatting") >= 0
	call pantondoc_formatting#InitFormatting()
    endif

" Folding: {{{2
if index(g:pantondoc_enabled_modules, "folding") >= 0
	call pantondoc_folding#InitFolding()
endif

" Completion: {{{2
if index(g:pantondoc_enabled_modules, "completion") >= 0
	call pantondoc_completion#InitCompletion()
endif

" Keyboard: {{{2
if index(g:pantondoc_enabled_modules, "keyboard") >= 0
	call pantondoc_keyboard#InitKeyboard()
endif

" Metadata: {{{2
if index(g:pantondoc_enabled_modules, "metadata") >= 0
	call pantondoc_metadata#InitMetadata()
endif

" Bibliographies: {{{2
if index(g:pantondoc_enabled_modules, "bibliographies") >= 0
	call pantondoc_biblio#InitBiblio()
endif

" Command: {{{2
if index(g:pantondoc_enabled_modules, "command") >= 0
	call pantondoc_command#InitCommand()
endif

" Menu: {{{2
if index(g:pantondoc_enabled_modules, "menu") >= 0
	call pantondoc_menu#CreateMenu()
endif

let b:pantondoc_loaded = 1
