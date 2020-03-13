autocmd BufNewFile,BufRead,BufFilePost *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc

if !exists('g:pandoc#filetypes#pandoc_markdown')
    let g:pandoc#filetypes#pandoc_markdown = 1
endif

if g:pandoc#filetypes#pandoc_markdown == 1
    autocmd BufNewFile,BufRead,BufFilePost *.markdown,*.mdown,*.mkd,*.mkdn,*.mdwn,*.md
                \ let b:did_ftplugin=1 | setlocal filetype=pandoc
endif

" vim: set fdm=marker et ts=4 sw=4 sts=4 :
