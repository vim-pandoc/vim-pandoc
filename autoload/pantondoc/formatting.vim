function! pantondoc#formatting#Init()
	" set up soft or hard wrapping modes
	if stridx(g:pantondoc_formatting_settings, "h") >= 0 && stridx(g:pantondoc_formatting_settings, "s") < 0
		call pantondoc#formatting#UseHardWraps()
	elseif stridx(g:pantondoc_formatting_settings, "s") >= 0 && stridx(g:pantondoc_formatting_settings, "h") < 0
		call pantondoc#formatting#UseSoftWraps()
	else
		echoerr "The value of g:pantondoc_formatting_settings is inconsistent"
	endif

	" # Use pandoc to tidy up text
	"
	" NOTE: If you use this on your entire file, it will wipe out title blocks.
	"
	if g:pantondoc_use_pandoc_equalprg > 0	
	    let &l:equalprg="pandoc -t markdown --reference-links"
	    if &textwidth > 0
		let &l:equalprg.=" --columns " . &textwidth
	    endif
	endif

	" Don't add two spaces at the end of punctuation when joining lines
	setlocal nojoinspaces

	" Textile uses .. for comments
	if &ft == "textile"
		setlocal commentstring=..%s
		setlocal comments=f:..
	else " Other markup formats use HTML-style comments
		setlocal commentstring=<!--%s-->
		setlocal comments=s:<!--,m:\ \ \ \ ,e:-->
	endif
endfunction

function! pantondoc#formatting#UseHardWraps()
	" reset settings that might have changed by UseSoftWraps
	setlocal formatoptions&
	setlocal linebreak&
	setlocal breakat&
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
	
	if stridx(g:pantondoc_formatting_settings, "a") >= 0
		" a: auto-format
		" w: lines with trailing spaces mark continuing
		" paragraphs, and lines ending on non-spaces end paragraphs.
		" we add `w` as a workaround to `a` joining compact lists.
		setlocal formatoptions+=aw
	endif
endfunction

function! pantondoc#formatting#UseSoftWraps()
	" reset settings that might have been changed by UseHardWraps
	setlocal textwidth&
	setlocal formatoptions&
	setlocal formatlistpat&

	" soft wrapping
	setlocal formatoptions=1
	setlocal linebreak
	setlocal breakat-=*
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
