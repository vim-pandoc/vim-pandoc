" vim: set fdm=marker : 

function! pantondoc#formatting#Init() "{{{1
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
    " Use pandoc as equalprg?
    if !exists("g:pandoc#formatting#pandoc_equalprg")
	let g:pandoc#formatting#pandoc_equalprg = 1
    endif
    " }}}

    " set up soft or hard wrapping modes "{{{2
    if stridx(g:pandoc#formatting#mode, "h") >= 0 && stridx(g:pandoc#formatting#mode, "s") < 0
	call pantondoc#formatting#UseHardWraps()
    elseif stridx(g:pandoc#formatting#mode, "s") >= 0 && stridx(g:pandoc#formatting#mode, "h") < 0
	call pantondoc#formatting#UseSoftWraps()
    else
	echoerr "pandoc: The value of g:pandoc#formatting#mode is inconsistent. Using default."
	call pantondoc#formatting#UseSoftWraps()
    endif

    " equalprog {{{2
    "
    " Use pandoc to tidy up text?
    "
    " NOTE: If you use this on your entire file, it will wipe out title blocks.
    "
    if g:pandoc#formatting#pandoc_equalprg > 0	
	let &l:equalprg="pandoc -t markdown --reference-links"
	if &textwidth > 0
	    let &l:equalprg.=" --columns " . &textwidth
	endif
    endif

    " common settings {{{2

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

function! pantondoc#formatting#UseHardWraps() "{{{1
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

function! pantondoc#formatting#UseSoftWraps() "{{{1
    " reset settings that might have been changed by UseHardWraps
    setlocal textwidth&
    setlocal formatoptions&
    setlocal formatlistpat&

    " soft wrapping
    setlocal formatoptions=1
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Remappings that make j and k behave properly with
    " soft wrapping.
    nnoremap <buffer> j gj
    nnoremap <buffer> k gk
    vnoremap <buffer> j gj
    vnoremap <buffer> k gk

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Show partial wrapped lines
    setlocal display=lastline
endfunction
