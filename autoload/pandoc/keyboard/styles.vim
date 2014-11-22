" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#styles#Init() "{{{1
    for style in ["emphasis", "strong", "verbatim", "strikeout", "superscript", "subscript"]
        let u_style = substitute(style, '\<.', '\u&', '') " capitalize first char: emphasis -> Emphasis
        exe 'noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :set opfunc=pandoc#keyboard#styles#Toggle'.u_style.'<cr>g@'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :<C-U>call pandoc#keyboard#styles#Toggle'.u_style.'(visualmode())<CR>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-inclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("inclusive")<cr>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-exclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("exclusive")<cr>'
    endfor
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, "styles") == -1
        nmap <buffer> <localleader>i <Plug>(pandoc-keyboard-toggle-emphasis)
        vmap <buffer> <localleader>i <Plug>(pandoc-keyboard-toggle-emphasis)
        nmap <buffer> <localleader>b <Plug>(pandoc-keyboard-toggle-strong)
        vmap <buffer> <localleader>b <Plug>(pandoc-keyboard-toggle-strong)
        nmap <buffer> <localleader>' <Plug>(pandoc-keyboard-toggle-verbatim)
        vmap <buffer> <localleader>' <Plug>(pandoc-keyboard-toggle-verbatim)
        nmap <buffer> <localleader>~~ <Plug>(pandoc-keyboard-toggle-strikeout)
        vmap <buffer> <localleader>~~ <Plug>(pandoc-keyboard-toggle-strikeout)
        nmap <buffer> <localleader>^ <Plug>(pandoc-keyboard-toggle-superscript)
        vmap <buffer> <localleader>^ <Plug>(pandoc-keyboard-toggle-superscript)
        nmap <buffer> <localleader>_ <Plug>(pandoc-keyboard-toggle-subscript)
        vmap <buffer> <localleader>_ <Plug>(pandoc-keyboard-toggle-subscript)
        vmap <buffer> <silent> aPe <Plug>(pandoc-keyboard-select-emphasis-inclusive)
        vmap <buffer> <silent> iPe <Plug>(pandoc-keyboard-select-emphasis-exclusive)
        omap <buffer> aPe :normal vaPe<cr>
        omap <buffer> iPe :normal viPe<cr>
        vmap <buffer> <silent> aPs <Plug>(pandoc-keyboard-select-strong-inclusive)
        vmap <buffer> <silent> iPs <Plug>(pandoc-keyboard-select-strong-exclusive)
        omap <buffer> aPs :normal vaPs<cr>
        omap <buffer> iPs :normal viPs<cr>
        vmap <buffer> <silent> aPv <Plug>(pandoc-keyboard-select-verbatim-inclusive)
        vmap <buffer> <silent> iPv <Plug>(pandoc-keyboard-select-verbatim-exclusive)
        omap <buffer> aPv :normal vaPv<cr>
        omap <buffer> iPv :normal viPv<cr>
        vmap <buffer> <silent> aPk <Plug>(pandoc-keyboard-select-strikeout-inclusive)
        vmap <buffer> <silent> iPk <Plug>(pandoc-keyboard-select-strikeout-exclusive)
        omap <buffer> aPk :normal vaPk<cr>
        omap <buffer> iPk :normal viPk<cr>
        vmap <buffer> <silent> aPu <Plug>(pandoc-keyboard-select-superscript-inclusive)
        vmap <buffer> <silent> iPu <Plug>(pandoc-keyboard-select-superscript-exclusive)
        omap <buffer> aPu :normal vaPu<cr>
        omap <buffer> iPu :normal viPu<cr>
        vmap <buffer> <silent> aPt <Plug>(pandoc-keyboard-select-subscript-inclusive)
        vmap <buffer> <silent> iPt <Plug>(pandoc-keyboard-select-subscript-exclusive)
        omap <buffer> aPt :normal vaPl<cr>
        omap <buffer> iPt :normal viPl<cr>
    endif
endfunction 

" Functions: {{{1
" Auxiliary: {{{2
function! s:EscapeEnds(ends)
    return escape(a:ends, '*^~')
endfunction
" Base: {{{2
" Toggle Operators, WYSIWYG-style {{{3
function! pandoc#keyboard#styles#ToggleOperator(type, ends)
    let sel_save = &selection
    let &selection = "old"
    let reg_save = getreg('*')
    if a:type ==# "v"
        execute "normal! `<".a:type."`>".'"*x'
    elseif a:type ==# "char"
        let cline = getline(".")
        let ccol = getpos(".")[2]
        let nchar = cline[ccol]
        let pchar = cline[ccol-2]
        if cline[ccol] == ""
            " at end
            execute "normal! `[Bv`]BE".'"*x'
        elseif match(pchar, '[[:blank:]]') > -1
            if match(nchar, '[[:blank:]]') > -1
                " single char
                execute "normal! `[v`]ege".'"*x'
            else
                " after space
                execute "normal! `[v`]BE".'"*x'
            endif
        elseif match(nchar, '[[:blank:]]') > -1
            " before space
            execute "normal! `[Bv`]BE".'"*x'
        else
            " inside a word
            execute "normal! `[EBv`]BE".'"*x'
        endif
    else
        return
    endif
    let match_data = matchlist(getreg('*'), '\('.s:EscapeEnds(a:ends).'\)\(.*\)\('.s:EscapeEnds(a:ends).'\)')
    if len(match_data) == 0
        call setreg('*', a:ends.getreg('*').a:ends)
        execute 'normal "*P'
    else
        call setreg('*', match_data[2])
        execute 'normal "*P'
    endif
    call setreg('*', reg_save)
    let &selection = sel_save
endfunction "}}}3

" Apply style {{{3
function! pandoc#keyboard#styles#Apply(type, ends)
    let sel_save = &selection
    let &selection = "old"
    let reg_save = getreg('*')
    if a:type ==# "v"
        execute "normal! `<".a:type."`>".'"*x'
    elseif a:type ==# "char"
        execute "normal! `[v`]".'"*x'
    else
        return
    endif
    call setreg('*', a:ends.getreg('*').a:ends)
    execute 'normal "*P'
    call setreg('*', reg_save)
    let &selection = sel_save
endfunction
"}}}3
"}}}2
" Emphasis: {{{2
" Apply emphasis, straight {{{3
function! pandoc#keyboard#styles#Emph(type)
    return pandoc#keyboard#styles#Apply(a:type, "*")
endfunction
" }}}3
" WYSIWYG-style toggle {{{3
"
function! pandoc#keyboard#styles#ToggleEmphasis(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "*")
endfunction
" }}}3
"}}}2
" Strong: {{{2
function! pandoc#keyboard#styles#Strong(type)
    return pandoc#keyboard#styles#Apply(a:type, "**")
endfunction
function! pandoc#keyboard#styles#ToggleStrong(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "**")
endfunction
"}}}2
" Verbatim: {{{2
function! pandoc#keyboard#styles#Verbatim(type)
    return pandoc#keyboard#styles#Apply(a:type, "`")
endfunction
function! pandoc#keyboard#styles#ToggleVerbatim(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "`")
endfunction
" }}}2
" Strikeout: {{{2
function! pandoc#keyboard#styles#Strikeout(type)
    return pandoc#keyboard#styles#Apply(a:type, "~~")
endfunction
function! pandoc#keyboard#styles#ToggleStrikeout(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "~~")
endfunction
" }}}2
" Superscript: {{{2
function! pandoc#keyboard#styles#Superscript(type)
    return pandoc#keyboard#styles#Apply(a:type, "^")
endfunction
function! pandoc#keyboard#styles#ToggleSuperscript(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "^")
endfunction
" }}}2
" Subscript: {{{2
function! pandoc#keyboard#styles#Subscript(type)
    return pandoc#keyboard#styles#Apply(a:type, "~")
endfunction
function! pandoc#keyboard#styles#ToggleSubscript(type)
    return pandoc#keyboard#styles#ToggleOperator(a:type, "~")
endfunction
" }}}2
" Objects: {{{2
function! pandoc#keyboard#styles#SelectSpan(mode, char)
    let [start_l, start_c] = searchpos(a:char, 'bn')
    let [end_l, end_c] = searchpos(a:char, 'n')
    let offset = len(substitute(a:char, '\\', '', 'g')) - 1
    if a:mode == 'inclusive'
        let start_c = start_c - 1
        let end_c = end_c + offset  - 1
    elseif a:mode == 'exclusive'
        let start_c = start_c + offset
        let end_c = end_c - 2 
    endif
    exe "normal! ".start_l. "G". start_c. "lv". end_l . "G". end_c ."l"
endfunction

function! pandoc#keyboard#styles#SelectEmphasis(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocEmphasis"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\*')
    endif
endfunction
function! pandoc#keyboard#styles#SelectStrong(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocStrong"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\*\*')
    endif
endfunction
function! pandoc#keyboard#styles#SelectVerbatim(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocNoFormatted"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\`')
    endif
endfunction
function! pandoc#keyboard#styles#SelectStrikeout(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocStrikeout"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\~\~')
    endif
endfunction
function! pandoc#keyboard#styles#SelectSuperscript(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocSuperscript"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\^')
    endif
endfunction
function! pandoc#keyboard#styles#SelectSubscript(mode)
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocSubscript"
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\~')
    endif
endfunction
" }}}2
"
"}}}1

