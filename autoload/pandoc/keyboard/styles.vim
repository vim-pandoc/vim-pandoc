" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#styles#Init() abort "{{{1
    for style in ['emphasis', 'strong', 'verbatim', 'strikeout', 'superscript', 'subscript']
        let u_style = substitute(style, '\<.', '\u&', '') " capitalize first char: emphasis -> Emphasis
        exe 'noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :set opfunc=pandoc#keyboard#styles#Toggle'.u_style.'<cr>g@'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :<C-U>call pandoc#keyboard#styles#Toggle'.u_style.'(visualmode())<CR>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-inclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("inclusive")<cr>'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-'.style.'-exclusive) :<C-U>call pandoc#keyboard#styles#Select'.u_style.'("exclusive")<cr>'
    endfor
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, 'styles') == -1
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
function! s:EscapeEnds(ends) abort
    return escape(a:ends, '*^~')
endfunction
function! s:IsCursorAtEndofNonEmptyLine() abort
    return (col('.')+1) == col('$') && col('.') != 1
endfunction
" Base: {{{2
" Toggle Operators, WYSIWYG-style {{{3
function! pandoc#keyboard#styles#ToggleOperator(type, ends) abort
    let sel_save = &selection
    let &selection = 'old'
    if has('clipboard')
        let reg = '*'
    else
        let reg = '"'
    endif
    let reg_save = getreg(reg)
    if a:type ==# 'v'
        execute 'normal! `<'.a:type.'`>'.'"'.reg.'x'
    elseif a:type ==# 'char'
        let cline = getline('.')
        let ccol = getpos('.')[2]
        let nchar = cline[ccol]
        let pchar = cline[ccol-2]
        if cline[ccol] ==# ''
            " at end
            execute 'normal! `[Bv`]BE'.'"'.reg.'x'
        elseif match(pchar, '[[:blank:]]') > -1
            if match(nchar, '[[:blank:]]') > -1
                " single char
                execute 'normal! `[v`]ege'.'"'.reg.'x'
            else
                " after space
                execute 'normal! `[v`]BE'.'"'.reg.'x'
            endif
        elseif match(nchar, '[[:blank:]]') > -1
            " before space
            execute 'normal! `[Bv`]BE'.'"'.reg.'x'
        else
            " inside a word
            execute 'normal! `[EBv`]BE'.'"'.reg.'x'
        endif
    else
        return
    endif
    let match_data = matchlist(getreg(reg), '\('.s:EscapeEnds(a:ends).'\)\(.*\)\('.s:EscapeEnds(a:ends).'\)')
    if len(match_data) == 0
        call setreg(reg, a:ends.getreg(reg).a:ends)
        if s:IsCursorAtEndofNonEmptyLine()
            execute 'normal "'.reg.'p'
        else
            execute 'normal "'.reg.'P'
        endif
    else
        call setreg(reg, match_data[2])
        if s:IsCursorAtEndofNonEmptyLine()
            execute 'normal "'.reg.'p'
        else
            execute 'normal "'.reg.'P'
        endif
    endif
    call setreg(reg, reg_save)
    let &selection = sel_save
endfunction "}}}3

" Apply style {{{3
function! pandoc#keyboard#styles#Apply(type, ends) abort
    let sel_save = &selection
    let &selection = 'old'
    if has('clipboard')
        let reg = '*'
    else
        let reg = '"'
    endif
    let reg_save = getreg(reg)
    if a:type ==# 'v'
        execute 'normal! `<'.a:type.'`>'.'"'.reg.'x'
    elseif a:type ==# 'char'
        execute 'normal! `[v`]'.'"'.reg.'x'
    else
        return
    endif
    call setreg(reg, a:ends.getreg(reg).a:ends)
    execute 'normal "'.reg.'P'
    call setreg(reg, reg_save)
    let &selection = sel_save
endfunction
"}}}3
"}}}2
" Emphasis: {{{2
" Apply emphasis, straight {{{3
function! pandoc#keyboard#styles#Emph(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '*')
endfunction
" }}}3
" WYSIWYG-style toggle {{{3
"
function! pandoc#keyboard#styles#ToggleEmphasis(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '*')
endfunction
" }}}3
"}}}2
" Strong: {{{2
function! pandoc#keyboard#styles#Strong(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '**')
endfunction
function! pandoc#keyboard#styles#ToggleStrong(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '**')
endfunction
"}}}2
" Verbatim: {{{2
function! pandoc#keyboard#styles#Verbatim(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '`')
endfunction
function! pandoc#keyboard#styles#ToggleVerbatim(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '`')
endfunction
" }}}2
" Strikeout: {{{2
function! pandoc#keyboard#styles#Strikeout(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '~~')
endfunction
function! pandoc#keyboard#styles#ToggleStrikeout(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '~~')
endfunction
" }}}2
" Superscript: {{{2
function! pandoc#keyboard#styles#Superscript(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '^')
endfunction
function! pandoc#keyboard#styles#ToggleSuperscript(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '^')
endfunction
" }}}2
" Subscript: {{{2
function! pandoc#keyboard#styles#Subscript(type) abort
    return pandoc#keyboard#styles#Apply(a:type, '~')
endfunction
function! pandoc#keyboard#styles#ToggleSubscript(type) abort
    return pandoc#keyboard#styles#ToggleOperator(a:type, '~')
endfunction
" }}}2
" Objects: {{{2
function! pandoc#keyboard#styles#SelectSpan(mode, char) abort
    let [start_l, start_c] = searchpos(a:char, 'bn')
    let [end_l, end_c] = searchpos(a:char, 'n')
    let offset = len(substitute(a:char, '\\', '', 'g')) - 1
    if a:mode ==# 'inclusive'
        let start_c = start_c - 1
        let end_c = end_c + offset  - 1
    elseif a:mode ==# 'exclusive'
        let start_c = start_c + offset
        let end_c = end_c - 2
    endif
    exe 'normal! '.start_l. 'G'. start_c. 'lv'. end_l . 'G'. end_c .'l'
endfunction

function! pandoc#keyboard#styles#SelectEmphasis(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocEmphasis'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\*')
    endif
endfunction
function! pandoc#keyboard#styles#SelectStrong(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocStrong'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\*\*')
    endif
endfunction
function! pandoc#keyboard#styles#SelectVerbatim(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocNoFormatted'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\`')
    endif
endfunction
function! pandoc#keyboard#styles#SelectStrikeout(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocStrikeout'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\~\~')
    endif
endfunction
function! pandoc#keyboard#styles#SelectSuperscript(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocSuperscript'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\^')
    endif
endfunction
function! pandoc#keyboard#styles#SelectSubscript(mode) abort
    if synIDattr(synID(line('.'), col('.'), 1), 'name') ==# 'pandocSubscript'
        call pandoc#keyboard#styles#SelectSpan(a:mode, '\~')
    endif
endfunction
" }}}2
"
"}}}1

