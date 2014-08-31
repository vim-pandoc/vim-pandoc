" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#styles#Init() "{{{1
    for style in ["emphasis", "strong", "verbatim", "strikeout", "superscript", "subscript"]
        let u_style = substitute(style, '\<.', '\u&', '') " capitalize first char: emphasis -> Emphasis
        exe 'noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :set opfunc=pandoc#keyboard#styles#Toggle'.u_style.'<cr>g@'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :<C-U>call pandoc#keyboard#styles#Toggle'.u_style.'(visualmode())<CR>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-inclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("inclusive")<cr>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-exclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("exclusive")<cr>'
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
        vmap <buffer> <silent> ape <Plug>(pandoc-keyboard-select-emphasis-inclusive)
        vmap <buffer> <silent> ipe <Plug>(pandoc-keyboard-select-emphasis-exclusive)
        omap <buffer> ape :normal va*<cr>
        omap <buffer> ipe :normal vi*<cr>
        vmap <buffer> <silent> aps <Plug>(pandoc-keyboard-select-strong-inclusive)
        vmap <buffer> <silent> ips <Plug>(pandoc-keyboard-select-strong-exclusive)
        omap <buffer> aps :normal va*<cr>
        omap <buffer> ips :normal vi*<cr>
        vmap <buffer> <silent> apv <Plug>(pandoc-keyboard-select-verbatim-inclusive)
        vmap <buffer> <silent> ipv <Plug>(pandoc-keyboard-select-verbatim-exclusive)
        omap <buffer> apv :normal va*<cr>
        omap <buffer> ipv :normal vi*<cr>
        vmap <buffer> <silent> apk <Plug>(pandoc-keyboard-select-strikeout-inclusive)
        vmap <buffer> <silent> ipk <Plug>(pandoc-keyboard-select-strikeout-exclusive)
        omap <buffer> apk :normal va*<cr>
        omap <buffer> ipk :normal vi*<cr>
        vmap <buffer> <silent> apu <Plug>(pandoc-keyboard-select-superscript-inclusive)
        vmap <buffer> <silent> ipu <Plug>(pandoc-keyboard-select-superscript-exclusive)
        omap <buffer> apu :normal va*<cr>
        omap <buffer> ipu :normal vi*<cr>
        vmap <buffer> <silent> apl <Plug>(pandoc-keyboard-select-subscript-inclusive)
        vmap <buffer> <silent> ipl <Plug>(pandoc-keyboard-select-subscript-exclusive)
        omap <buffer> apl :normal va*<cr>
        omap <buffer> ipl :normal vi*<cr>
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
    if synIDattr(synID(line('.'), col('.'), 1), "name") == "pandocEmphasis"
        let [start_l, start_c] = searchpos(a:char, 'bn')
        let [end_l, end_c] = searchpos(a:char, 'n')
        if a:mode == 'inclusive'
            let start_c = start_c - 1
            let end_c = end_c - 1
        elseif a:mode == 'exclusive'
            let end_c = end_c - 2
        endif
        exe "normal! ".start_l. "G". start_c. "lv". end_l . "G". end_c ."l"
    endif
endfunction

function! pandoc#keyboard#styles#SelectEmphasis(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '*')
endfunction
function! pandoc#keyboard#styles#SelectStrong(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '**')
endfunction
function! pandoc#keyboard#styles#SelectVerbatim(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '`')
endfunction
function! pandoc#keyboard#styles#SelectStrikeout(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '~~')
endfunction
function! pandoc#keyboard#styles#SelectSuperscript(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '^')
endfunction
function! pandoc#keyboard#styles#SelectSubscript(mode)
    call pandoc#keyboard#styles#SelectSpan(a:mode, '_')
endfunction
" }}}2
"
"}}}1

