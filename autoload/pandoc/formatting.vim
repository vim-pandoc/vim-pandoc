" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#formatting#Init() "{{{1
    " set up defaults {{{2
   
    " Formatting mode {{{3
    " s: use soft wraps
    " h: use hard wraps
    " a: auto format (only used if h is set)
    if !exists("g:pandoc#formatting#mode")
        let g:pandoc#formatting#mode = "s"
    endif
    "}}}
    " = {{{3
    " what program to use equalprg? {{{4
    if !exists("g:pandoc#formattingequalprg")
        let g:pandoc#formatting#equalprg = "pandoc -t markdown --reference-links"
        if g:pandoc#formatting#mode =~ "h"
            let g:pandoc#formatting#equalprg.= " --columns 79"
        else
            let g:pandoc#formatting#equalprg.= " --no-wrap"
        endif
    endif
    " }}}4
    " Use a custom indentexpr? {{{4
    if !exists("g:pandoc#formatting#set_indentexpr")
        let g:pandoc#formatting#set_indentexpr = 0
    endif
    " }}}4
    " }}}3
    " set up soft or hard wrapping modes "{{{2
    if stridx(g:pandoc#formatting#mode, "h") >= 0 && stridx(g:pandoc#formatting#mode, "s") < 0
        call pandoc#formatting#UseHardWraps()
    elseif stridx(g:pandoc#formatting#mode, "s") >= 0 && stridx(g:pandoc#formatting#mode, "h") < 0
        call pandoc#formatting#UseSoftWraps()
    else
        echoerr "pandoc: The value of g:pandoc#formatting#mode is inconsistent. Using default."
        call pandoc#formatting#UseSoftWraps()
    endif

    " equalprog {{{2
    "
    " Use pandoc to tidy up text?
    "
    " NOTE: If you use this on your entire file, it will wipe out title blocks.
    "
    if g:pandoc#formatting#equalprg != ''
        let &l:equalprg=g:pandoc#formatting#equalprg
    endif

    " common settings {{{2
   
    " indent using a custom indentexpr
    if g:pandoc#formatting#set_indentexpr == 1
        setlocal indentexpr=pandoc#formatting#IndentExpr()
    endif

    " Don't add two spaces at the end of punctuation when joining lines
    setlocal nojoinspaces

    " Always use linebreak.
    setlocal linebreak
    setlocal breakat-=*

    " Textile uses .. for comments
    if &ft == "textile"
        setlocal commentstring=..%s
        setlocal comments=f:..
    else " Other markup formats use HTML-style comments
        setlocal commentstring=<!--%s-->
        setlocal comments=s:<!--,m:\ \ \ \ ,e:-->
    endif
    "}}}2
endfunction

function! pandoc#formatting#UseHardWraps() "{{{1
    " reset settings that might have changed by UseSoftWraps
    setlocal formatoptions&
    setlocal display&
    silent! unmap j
    silent! unmap k

    " hard wrapping at 79 chars (like in gq default)
    if &textwidth == 0
        setlocal textwidth=79
    endif
    " t: wrap on &textwidth
    " n: keep inner indent for list items.
    setlocal formatoptions=tn
    " will detect numbers, letters, *, +, and - as list headers, according to
    " pandoc syntax.
    " TODO: add support for roman numerals
    setlocal formatlistpat=^\\s*\\([*+-]\\\|\\((*\\d\\+[.)]\\+\\)\\\|\\((*\\l[.)]\\+\\)\\)\\s\\+
   
    if stridx(g:pandoc#formatting#mode, "a") >= 0
        " a: auto-format
        " w: lines with trailing spaces mark continuing
        " paragraphs, and lines ending on non-spaces end paragraphs.
        " we add `w` as a workaround to `a` joining compact lists.
        setlocal formatoptions+=aw
    endif
endfunction

function! pandoc#formatting#UseSoftWraps() "{{{1
    " reset settings that might have been changed by UseHardWraps
    setlocal textwidth&
    setlocal formatoptions&
    setlocal formatlistpat&

    " soft wrapping
    setlocal formatoptions=1

    " Show partial wrapped lines
    setlocal display=lastline
endfunction

function! pandoc#formatting#IndentExpr() "{{{1
    let cline = getline(v:lnum)
    let pline = getline(v:lnum - 1)
    let cline_li = matchstr(cline, '^\s*[*-:]\s*')
    if cline_li != ""
        return len(matchstr(cline_li, '^\s*'))
    endif
    let pline_li = matchstr(pline, '^\s*[*-:]\s\+')
    if pline_li != ""
        return len(pline_li)
    endif
    if pline == ""
        return indent(v:lnum)
    else
        return indent(v:lnum - 1)
    endif
endfunction
