" vim: set fdm=marker:

" Pandoc: {{{1
" load vim-pandoc {{{2
runtime ftplugin/pandoc.vim

" init vim-pandoc-after, if present {{{2
try
    call pandoc#after#Init()
catch /E117/
endtry
