" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#styles#Init() "{{{1
    for style in ["emphasis", "strong", "verbatim", "strikeout", "superscript", "subscript"]
        let u_style = substitute(style, '\<.', '\u&', '') " capitalize first char: emphasis -> Emphasis
        exe 'noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :set opfunc=pandoc#keyboard#styles#Toggle'.u_style.'<cr>g@'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :<C-U>call pandoc#keyboard#styles#Toggle'.u_style.'(visualmode())<CR>'
    endfor
    if g:pandoc#keyboard#use_default_mappings == 1
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
"}}}1

