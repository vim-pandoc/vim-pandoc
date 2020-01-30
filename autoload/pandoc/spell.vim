function! pandoc#spell#Init() abort
    if !exists('g:pandoc#spell#enabled')
        let g:pandoc#spell#enabled = 1
    endif
    if !exists('g:pandoc#spell#default_langs')
        let g:pandoc#spell#default_langs = []
    endif

    if g:pandoc#spell#enabled == 1
        setlocal spell
    endif
    if g:pandoc#spell#default_langs != []
        exe 'setlocal spelllang='.join(g:pandoc#spell#default_langs, ',')
    endif
endfunction
