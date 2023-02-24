" vint: -ProhibitAutocmdWithNoGroup
autocmd BufNewFile,BufRead,BufFilePost *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc

if get(g:, 'pandoc#filetypes#pandoc_markdown', 1) == 1
	if exists('#filetypedetect#BufNewFile,BufRead#*.{md,markdown,mdown,mkd,mkdn}')
        autocmd! filetypedetect BufNewFile,BufRead *.{md,markdown,mdown,mkd,mkdn}
    endif
    autocmd BufNewFile,BufRead,BufFilePost *.{md,markdown,mdown,mkd,mkdn} setlocal filetype=pandoc
endif

" vim: set fdm=marker et ts=4 sw=4 sts=4 :
