" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#formatting#Init() abort "{{{1
    " set up defaults {{{2

    " Formatting mode {{{3
    " s: use soft wraps
    " h: use hard wraps
    " a: auto format (only used if h is set)
    " A: smart auto format
    if !exists('g:pandoc#formatting#mode')
        let g:pandoc#formatting#mode = 's'
    endif
    "}}}3
    " Auto-format {{{3
    " Autoformat blacklist {{{4
    if !exists('g:pandoc#formatting#smart_autoformat_blacklist')
        let g:pandoc#formatting#smart_autoformat_blacklist = [
                    \ 'pandoc.+header',
                    \ 'pandoc\S{-}(code|title|line|math)block(title)?',
                    \ 'pandoc.+table',
                    \ 'pandoctable',
                    \ 'pandoc.+latex',
                    \ 'pandocreferencedefinition',
                    \ 'pandocreferencelabel',
                    \ 'tex.*',
                    \ 'yaml.*',
                    \ 'delimiter'
                    \]
    endif
    " }}}4
    " Autoformat on CursorMovedI {{{4
    if !exists('g:pandoc#formatting#smart_autoformat_on_cursormoved')
        let g:pandoc#formatting#smart_autoformat_on_cursormoved = 0
    endif
    "}}}4
    "}}}3
    " Text width {{{3
    if !exists('g:pandoc#formatting#textwidth')
        let g:pandoc#formatting#textwidth = 79
    endif
    " }}}3
    " equalprg {{{3
    if !exists('g:pandoc#formatting#equalprg')
        if executable('pandoc')
            let g:pandoc#formatting#equalprg = 'pandoc -t markdown'
            if g:pandoc#formatting#mode =~# 'h'
                let g:pandoc#formatting#equalprg.= ' --columns '.g:pandoc#formatting#textwidth
            else
                let g:pandoc#formatting#equalprg.= ' --wrap=none'
            endif
        else
            let g:pandoc#formatting#equalprg = ''
        endif
    endif
    " extend the value of equalprg if needed
    if !exists('g:pandoc#formatting#extra_equalprg')
        let g:pandoc#formatting#extra_equalprg = '--reference-links'
    endif
    " }}}3
    " formatprg {{{3
    if !exists('g:pandoc#formatting#formatprg#use_pandoc')
        let g:pandoc#formatting#formatprg#use_pandoc = 0
    endif
    if !exists('g:pandoc#formatting#formatprg')
        if g:pandoc#formatting#formatprg#use_pandoc == 1
            if executable('pandoc')
                let g:pandoc#formatting#formatprg = 'pandoc -t markdown'
                if g:pandoc#formatting#mode =~# 'h'
                    let g:pandoc#formatting#formatprg.= ' --columns '.g:pandoc#formatting#textwidth
                else
                    let g:pandoc#formatting#formatprg.= ' --wrap=none'
                endif
            endif
        else
            let g:pandoc#formatting#formatprg = ''
        endif
    endif
    " }}}3
    " Use a custom indentexpr? {{{3
    if !exists('g:pandoc#formatting#set_indentexpr')
        let g:pandoc#formatting#set_indentexpr = 0
    endif
    " }}}3
    " set up soft or hard wrapping modes "{{{2
    if stridx(g:pandoc#formatting#mode, 'h') >= 0 && stridx(g:pandoc#formatting#mode, 's') < 0
        call pandoc#formatting#UseHardWraps()
    elseif stridx(g:pandoc#formatting#mode, 's') >= 0 && stridx(g:pandoc#formatting#mode, 'h') < 0
        call pandoc#formatting#UseSoftWraps()
    else
        echoerr 'pandoc: The value of g:pandoc#formatting#mode is inconsistent. Using default.'
        call pandoc#formatting#UseSoftWraps()
    endif

    " equalprog {{{2
    "
    " Use pandoc to tidy up text?
    "
    " NOTE: If you use this on your entire file, it will wipe out title blocks.
    "
    if g:pandoc#formatting#equalprg !=? ''
        let &l:equalprg=g:pandoc#formatting#equalprg.' '.g:pandoc#formatting#extra_equalprg
    endif

    " formatprg {{{2
    if g:pandoc#formatting#formatprg !=? ''
        let &l:formatprg=g:pandoc#formatting#formatprg
    endif

    " common settings {{{2

    " indent using a custom indentexpr
    if g:pandoc#formatting#set_indentexpr == 1
        setlocal indentexpr=pandoc#formatting#IndentExpr()
    endif
    setlocal autoindent " copy indent level from previous line.

    " Don't add two spaces at the end of punctuation when joining lines
    setlocal nojoinspaces

    " Always use linebreak.
    setlocal linebreak
    setlocal breakat-=*
    if exists('+breakindent')
        setlocal breakindent
    endif

    if has('smartindent')
        setlocal nosmartindent
    endif

    " Textile uses .. for comments
    if &filetype ==? 'textile'
        setlocal commentstring=..%s
        setlocal comments=f:..
    else " Other markup formats use HTML-style comments
        setlocal commentstring=<!--%s-->
        setlocal comments=s:<!--,m:\ \ \ \ ,e:-->,:\|,n:>
    endif

    let s:last_autoformat_lnum = 0
    "}}}2
    "
    " Global settings we must override {{{2
    let s:original_breakat = &breakat
    augroup pandoc_formatting
        au! BufEnter <buffer> set breakat-=@
        au! BufLeave <buffer> exe 'set breakat='.substitute(s:original_breakat, '\s*', '\\ ', 1)
    augroup END
    set breakat-=@
    "}}}2
endfunction

" Autoformat switches {{{1
function! pandoc#formatting#isAutoformatEnabled() abort
    if exists('b:pandoc_autoformat_enabled')
        return b:pandoc_autoformat_enabled
    else
        return 1
    endif
endfunction
function! pandoc#formatting#EnableAutoformat() abort
    let b:pandoc_autoformat_enabled = 1
endfunction
function! pandoc#formatting#DisableAutoformat() abort
    let b:pandoc_autoformat_enabled = 0
endfunction
function! pandoc#formatting#ToggleAutoformat() abort
    if get(b:, 'pandoc_autoformat_enabled', 1) == 1
        let b:pandoc_autoformat_enabled = 0
    else
        let b:pandoc_autoformat_enabled = 1
    endif
endfunction

function! pandoc#formatting#AutoFormat(force) abort "{{{1
    if !exists('b:pandoc_autoformat_enabled') || b:pandoc_autoformat_enabled == 1
        let l:line = line('.')
        if a:force == 1 || l:line != s:last_autoformat_lnum || (l:line == s:last_autoformat_lnum && col('.') == 1)
            let s:last_autoformat_lnum = l:line
            let l:stack = []
            let l:should_enable = 1
            let l:context_prevents = 0
            let l:blacklist_re = '\c\v('.join(g:pandoc#formatting#smart_autoformat_blacklist, '|').')'
            let l:stack = synstack(l:line, col('.'))
            if len(l:stack) == 0
                " let's try with the first column in this line
                let l:stack = synstack(l:line, 1)
            endif
            if len(l:stack) > 0
                let l:synName = synIDattr(l:stack[0], 'name')
                " we check on the base syntax id, so we don't have to pollute the
                " blacklist with stuff like pandocAtxMark, which is contained
                if match(l:synName, l:blacklist_re) >= 0
                    let l:should_enable = 0
                endif
                if match(l:synName, 'pandocdefinitionblock') >= 0
                    let context_prevents = 1
                endif
                try
                    let l:p_synName = synIDattr(synstack(l:line-1, col('$'))[0], 'name')
                catch /E684/
                    let l:p_synName = ''
                endtry
                if match(l:synName.l:p_synName, '\c\vpandocu?list') >= 0
                    let l:context_prevents = 1
                endif
            else
                let l:p_synName = synIDattr(synID(l:line-1, col('$'), 0), 'name')
                if l:p_synName =~? '\c\vpandoc(u?list|referencedef)'
                    let l:context_prevents = 1
                elseif l:p_synName =~? '\c\vpandochrule'
                    let l:context_prevents = 1
                elseif l:p_synName =~? '\c\vpandoccodeblock' && indent('.')%4 == 0
                    let l:context_prevents = 1
                elseif getline(l:line -1) =~? '^\w\+:'
                    let l:context_prevents = 1
                endif
            endif
            if l:should_enable == 1
                if l:context_prevents != 1
                    setlocal formatoptions+=a
                else
                    setlocal formatoptions-=a " in case it is set
                endif
                setlocal formatoptions+=t
                " block quotes are formatted like text comments (hackish, i know),
                " so we want to make them break at textwidth
                if l:stack != [] && l:synName ==? 'pandocBlockQuote'
                    setlocal formatoptions+=c
                endif
            elseif l:should_enable == 0
                setlocal formatoptions-=a
                setlocal formatoptions-=t
                setlocal formatoptions-=c "just in case we have added it for a block quote
            endif
        endif
    elseif &formatoptions !=# 'tn'
        setlocal formatoptions=tnroq
    endif
endfunction


function! pandoc#formatting#UseHardWraps() abort "{{{1
    " reset settings that might have changed by UseSoftWraps
    setlocal formatoptions&
    setlocal display&
    setlocal wrap&
    " textwidth
    exec 'setlocal textwidth='.g:pandoc#formatting#textwidth

    " t: wrap on &textwidth
    " n: keep inner indent for list items.
    setlocal formatoptions=tnroq
    " will detect numbers, letters, *, +, and - as list headers, according to
    " pandoc syntax.
    " TODO: add support for roman numerals
    setlocal formatlistpat=^\\s*\\([*+-]\\\|\\((*\\d\\+[.)]\\+\\)\\\|\\((*\\l[.)]\\+\\)\\)\\s\\+

    if stridx(g:pandoc#formatting#mode, 'a') >= 0
        " a: auto-format
        " w: lines with trailing spaces mark continuing
        " paragraphs, and lines ending on non-spaces end paragraphs.
        " we add `w` as a workaround to `a` joining compact lists.
        setlocal formatoptions+=aw
    elseif stridx(g:pandoc#formatting#mode, 'A') >= 0
        augroup pandoc_autoformat
        au InsertEnter <buffer> call pandoc#formatting#AutoFormat(1)
        au InsertLeave <buffer> setlocal formatoptions=tnroq
        if g:pandoc#formatting#smart_autoformat_on_cursormoved == 1
            au CursorMovedI <buffer> call pandoc#formatting#AutoFormat(0)
        endif
        augroup END
    endif
endfunction

function! pandoc#formatting#UseSoftWraps() abort "{{{1
    " reset settings that might have been changed by UseHardWraps
    setlocal textwidth&
    setlocal formatoptions&
    setlocal formatlistpat&

    " soft wrapping
    setlocal wrap
    setlocal formatoptions=1n

    " Show partial wrapped lines
    setlocal display=lastline
endfunction

function! pandoc#formatting#IndentExpr() abort "{{{1
    let l:cline = getline(v:lnum)
    let l:pline = getline(v:lnum - 1)
    let l:cline_li = matchstr(l:cline, '^\s*[*-:]\s*')
    if l:cline_li !=? ''
        return len(matchstr(l:cline_li, '^\s*'))
    endif
    let l:pline_li = matchstr(l:pline, '^\s*[*-:]\s\+')
    if l:pline_li !=? ''
        return len(l:pline_li)
    endif
    if l:pline ==? ''
        return indent(v:lnum)
    else
        return indent(v:lnum - 1)
    endif
endfunction
