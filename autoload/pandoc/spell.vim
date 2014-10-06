function! pandoc#spell#Init()
    if !exists("g:pandoc#spell#enabled")
        let g:pandoc#spell#enabled = 1
    endif
    if !exists("g:pandoc#spell#default_langs")
        let g:pandoc#spell#default_langs = []
    endif

    if g:pandoc#spell#enabled == 1
        set spell
    endif
    if g:pandoc#spell#default_langs != []
        exe "set spelllang=".join(g:pandoc#spell#default_langs, ',')
    endif
endfunction
