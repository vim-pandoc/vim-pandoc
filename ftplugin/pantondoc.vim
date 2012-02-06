" vim: set fdm=marker fdc=2: {{{1

" File: ftplugin/pantondoc.vim
" Description: pantondoc-handled buffer settings
" Author: Felipe Morales
" Version: alpha1 }}}1

" Modules: {{{1
"
" Formatting: {{{2
if index(g:pantondoc_enabled_modules, "formatting") >= 0
	call pantondoc_formatting#InitFormatting()
endif "{{{2

" Folding: {{{2
if index(g:pantondoc_enabled_modules, "folding") >= 0
	call pantondoc_folding#InitFolding()
endif

" Executors: {{{2
if index(g:pantondoc_enabled_modules, "executors") >= 0
	call pantondoc_executors#InitExecutors()
endif

" Movement: {{{2
if index(g:pantondoc_enabled_modules, "motions") >= 0
	call pantondoc_motions#RegisterMotions()
endif

" Tables: {{{2
if index(g:pantondoc_enabled_modules, "tables") >= 0
	call pantondoc_tables#InitTables()
endif

" Bibliographies: {{{2
if index(g:pantondoc_enabled_modules, "bibliographies") >= 0
	call pantondoc_biblio#InitBiblio()
endif

" Ids: {{{2
if index(g:pantondoc_enabled_modules, "completion") >= 0
	call pantondoc_completion#InitCompletion()
endif

" Metadata: {{{2
if index(g:pantondoc_enabled_modules, "metadata") >= 0
	call pantondoc_metadata#InitMetadata()
endif

" Menu: {{{2
if index(g:pantondoc_enabled_modules, "menu") >= 0
	call pantondoc_menu#CreateMenu()
endif

" Externals: {{{2
if index(g:pantondoc_enabled_modules, "externals") >= 0
	runtime plugin/pantondoc/externals/*.vim
endif

