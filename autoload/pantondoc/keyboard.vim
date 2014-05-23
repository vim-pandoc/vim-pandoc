" vim: set fdm=marker:

" Init: {{{1
function! pantondoc#keyboard#Init()
    " Styling:
    " Toggle emphasis, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>i :set opfunc=pantondoc#keyboard#ToggleEmphasis<cr>g@
    vnoremap <buffer> <silent> <localleader>i :<C-U>call pantondoc#keyboard#ToggleEmphasis(visualmode())<CR>
    " Toggle strong, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>b :set opfunc=pantondoc#keyboard#ToggleStrong<cr>g@
    vnoremap <buffer> <silent> <localleader>b :<C-U>call pantondoc#keyboard#ToggleStrong(visualmode())<CR>
    " Toggle verbatim, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>` :set opfunc=pantondoc#keyboard#ToggleVerbatim<cr>g@
    vnoremap <buffer> <silent> <localleader>` :<C-U>call pantondoc#keyboard#ToggleVerbatim(visualmode())<CR>
    " Toggle strikeout, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>~~ :set opfunc=pantondoc#keyboard#ToggleStrikeout<cr>g@
    vnoremap <buffer> <silent> <localleader>~~ :<C-U>call pantondoc#keyboard#ToggleStrikeout(visualmode())<CR>
    " Toggle superscript, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>^ :set opfunc=pantondoc#keyboard#ToggleSuperscript<cr>g@
    vnoremap <buffer> <silent> <localleader>^ :<C-U>call pantondoc#keyboard#ToggleSuperscript(visualmode())<CR>
    " Toggle subscript, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>_ :set opfunc=pantondoc#keyboard#ToggleSubscript<cr>g@
    vnoremap <buffer> <silent> <localleader>_ :<C-U>call pantondoc#keyboard#ToggleSubscript(visualmode())<CR>

    " Headers:
    noremap <buffer> <silent> <localleader>hn :call pantondoc#keyboard#NextHeader()<cr>
    noremap <buffer> <silent> <localleader>hb :call pantondoc#keyboard#PrevHeader()<cr>
    noremap <buffer> <silent> <localleader>hh :call pantondoc#keyboard#CurrentHeader()<cr>
    noremap <buffer> <silent> <localleader>hp :call pantondoc#keyboard#CurrentHeaderParent()<cr>
    noremap <buffer> <silent> <localleader>hsn :call pantondoc#keyboard#NextSiblingHeader()<cr>
    noremap <buffer> <silent> <localleader>hsb :call pantondoc#keyboard#PrevSiblingHeader()<cr>

    " References:
    " Add new reference link (or footnote link) after current paragraph. 
    noremap <buffer> <silent> <localleader>nr :call pantondoc#keyboard#Insert_Ref()<cr>a
    " Go to link or footnote definition for label under the cursor.
    noremap <buffer> <silent> <localleader>rg :call pantondoc#keyboard#GOTO_Ref()<CR>
    " Go back to last point in the text we jumped to a reference from.
    noremap <buffer> <silent> <localleader>rb :call pantondoc#keyboard#BACKFROM_Ref()<CR>
endfunction
"}}}1
" Auxiliary: {{{1
function! s:EscapeEnds(ends)
    return escape(a:ends, '*^~')
endfunction
" }}}1
" Styling: {{{1
" Base: {{{2
" Toggle Operators, WYSIWYG-style {{{3
function! pantondoc#keyboard#ToggleOperator(type, ends)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    if a:type ==# "v"
	execute "normal! `<".a:type."`>x"
    elseif a:type ==# "char"
	let cline = getline(".")
	let ccol = getpos(".")[2]
	let nchar = cline[ccol]
	let pchar = cline[ccol-2]
	if cline[ccol] == ""
	    " at end
	    execute "normal! `[Bv`]BEx"
	elseif match(pchar, '[[:blank:]]') > -1
	    if match(nchar, '[[:blank:]]') > -1
		" single char
		execute "normal! `[v`]egex"
	    else
		" after space
		execute "normal! `[v`]BEx"
	    endif
	elseif match(nchar, '[[:blank:]]') > -1
	    " before space
	    execute "normal! `[Bv`]BEx"
	else
	    " inside a word
	    execute "normal! `[EBv`]BEx"
	endif
    else
	return
    endif
    let match_data = matchlist(@@, '\('.s:EscapeEnds(a:ends).'\)\(.*\)\('.s:EscapeEnds(a:ends).'\)')
    if len(match_data) == 0
	let @@ = a:ends.@@.a:ends
	execute "normal P"
    else 
	let @@ = match_data[2]
	execute "normal P"
    endif
    let @@ = reg_save
    let &selection = sel_save
endfunction "}}}3
" Apply style {{{3
function! pantondoc#keyboard#Apply(type, ends)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    if a:type ==# "v"
	execute "normal! `<".a:type."`>x"
    elseif a:type ==# "char"
        execute "normal! `[v`]x"
    else
	return
    endif
    let @@ = a:ends.@@.a:ends
    execute "normal P"
    let @@ = reg_save
    let &selection = sel_save
endfunction
"}}}3
"}}}2
" Emphasis: {{{2
" Apply emphasis, straight {{{3
function! pantondoc#keyboard#Emph(type)
    return pantondoc#keyboard#Apply(a:type, "*")
endfunction
" }}}3
" WYSIWYG-style toggle {{{3
"
function! pantondoc#keyboard#ToggleEmphasis(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "*")
endfunction
" }}}3
"}}}2
" Strong: {{{2
function! pantondoc#keyboard#Strong(type)
    return pantondoc#keyboard#Apply(a:type, "**")
endfunction
function! pantondoc#keyboard#ToggleStrong(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "**")
endfunction
"}}}2
" Verbatim: {{{2
function! pantondoc#keyboard#Verbatim(type)
    return pantondoc#keyboard#Apply(a:type, "`")
endfunction
function! pantondoc#keyboard#ToggleVerbatim(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "`")
endfunction
" }}}2
" Strikeout: {{{2
function! pantondoc#keyboard#Strikeout(type)
    return pantondoc#keyboard#Apply(a:type, "~~")
endfunction
function! pantondoc#keyboard#ToggleStrikeout(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "~~")
endfunction
" }}}2
" Superscript: {{{2
function! pantondoc#keyboard#Superscript(type)
    return pantondoc#keyboard#Apply(a:type, "^")
endfunction
function! pantondoc#keyboard#ToggleSuperscript(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "^")
endfunction
" }}}2
" Subscript: {{{2
function! pantondoc#keyboard#Subscript(type)
    return pantondoc#keyboard#Apply(a:type, "~")
endfunction
function! pantondoc#keyboard#ToggleSubscript(type)
    return pantondoc#keyboard#ToggleOperator(a:type, "~")
endfunction
" }}}2
"}}}1
" References: {{{1
" handling: {{{2
function! pantondoc#keyboard#Insert_Ref()
    execute "normal m".g:pantondoc_mark
    execute "normal! ya\[o\<cr>\<esc>0P$a: "
endfunction
" }}}2
" navigation: {{{2

function! pantondoc#keyboard#GOTO_Ref()
    let reg_save = @@
    execute "normal m".g:pantondoc_mark
    execute "silent normal! ?[\<cr>vf]y"
    let @@ = substitute(@@, '\[', '\\\[', 'g')
    let @@ = substitute(@@, '\]', '\\\]', 'g')
    execute "silent normal! /".@@.":\<cr>"
    let @@ = reg_save
endfunction

function! pantondoc#keyboard#BACKFROM_Ref()
    try
        execute 'normal  `'.g:pantondoc_mark
	" clean up
	execute 'delmark '.g:pantondoc_mark
    catch /E20/ "no mark set, we must search backwards.
	let reg_save = @@
	"move right, because otherwise it would fail if the cursor is at the
	"beggining of the line
        execute "silent normal! 0l?[\<cr>vf]y"
	let @@ = substitute(@@, '\]', '\\\]', 'g')
	execute "silent normal! ?".@@."\<cr>"
	let @@ = reg_save
    endtry
endfunction

function! pantondoc#keyboard#NextRefDefinition()
endfunction

function! pantondoc#keyboard#PrevRefDefinition()
endfunction
" }}}2
" }}}1
" Headers: {{{1

" handling: {{{2
function! pantondoc#keyboard#ApplyHeader()
" TODO
endfunction
" }}}2

" navigation: {{{2
function! pantondoc#keyboard#NextHeader() "{{{3
    let wrapscan_save = &wrapscan
    let &wrapscan = 0  
    exe "silent normal $/\\(^.*\\n[-=]\\|^#\\)\<cr>"
    let &wrapscan = wrapscan_save
endfunction

function! pantondoc#keyboard#PrevHeader() "{{{3
    let wrapscan_save = &wrapscan
    let &wrapscan = 0  
    exe "silent normal 0?\\(^.*\\n[-=]\\|^#\\)\<cr>"
    let &wrapscan = wrapscan_save
endfunction

function! pantondoc#keyboard#CurrentHeader() "{{{3
    " same as PrevHeader(), except don't move if we are already at a header 
    if match(getline("."), "^#") < 0 && match(getline(line(".")+1), "^[-=]") < 0
	call pantondoc#keyboard#PrevHeader()
    endif
endfunction

function! pantondoc#keyboard#CurrentHeaderParent() "{{{3
    let wrapscan_save = &wrapscan
    let &wrapscan = 0
    call pantondoc#keyboard#CurrentHeader()
    let l = getline(".")

    if match(l, "^#") > -1
        let parent_level = len(matchstr(l, '#*')) - 1
    elseif match(getline(line(".")+1), '^-') > -1
	let parent_level = 1
    else
	let parent_level = 0
    endif

    " don't go further than level 1 headers
    if parent_level > 0
	if parent_level == 1
	    let setext_regex = "^.*\\n="
	else 
	    let setext_regex = "^.*\\n[-=]"
	endif
	    
	exe "silent normal 0?\\(".setext_regex."\\|^#\\{1,".parent_level."}\\s\\)\<cr>"
    endif
    let &wrapscan = wrapscan_save
endfunction

function! pantondoc#keyboard#NextSiblingHeader() "{{{3
    call pantondoc#keyboard#CurrentHeader()
    let l = getline(".")
    let origin_lnum = line(".")

    if match(l, "^#") > -1
        let header_level = len(matchstr(l, '#*'))
    elseif match(getline(line(".")+1), '^-') > -1
	let header_level = 2
    else
	let header_level = 1
    endif

    " where (who) our parent is
    call pantondoc#keyboard#CurrentHeaderParent()
    let parent_lnum = line(".")
    exe origin_lnum

    try
	if header_level == 1
	    exe "silent normal $/\\(^.*\\n=\\|^#\\s\\)\<cr>"
	elseif header_level == 2
	    exe "silent normal $/\\(^.*\\n-\\|^##\\s\\)\<cr>"
	else
	    exe "silent normal $/^#\\{".header_level."\}\<cr>"
	endif
    catch
	return
    endtry
    let arrival_lnum = line(".")

    " we might have overshot, check if the parent is still correct 
    call pantondoc#keyboard#CurrentHeaderParent()
    let arrival_parent_lnum = line(".")
    if arrival_parent_lnum != parent_lnum
	exe origin_lnum
    else
	exe arrival_lnum
    endif
endfunction

function! pantondoc#keyboard#PrevSiblingHeader() "{{{3
    call pantondoc#keyboard#CurrentHeader()
    let l = getline(".")
    let origin_lnum = line(".")

    if match(l, "^#") > -1
        let header_level = len(matchstr(l, '#*'))
    elseif match(getline(line(".")+1), '^-') > -1
	let header_level = 2
    else
	let header_level = 1
    endif

    " where (who) our parent is
    call pantondoc#keyboard#CurrentHeaderParent()
    let parent_lnum = line(".")
    exe origin_lnum

    try
	if header_level == 1
	    exe "silent normal 0?\\(^.*\\n=\\|^#\\s\\)\<cr>"
	elseif header_level == 2
	    exe "silent normal 0?\\(^.*\\n-\\|^##\\s\\)\<cr>"
	else
	    exe "silent normal 0?^#\\{".header_level."\}\<cr>"
	endif
    catch
	return
    endtry
    let arrival_lnum = line(".")

    " we might have overshot, check if the parent is still correct 
    call pantondoc#keyboard#CurrentHeaderParent()
    let arrival_parent_lnum = line(".")
    if arrival_parent_lnum != parent_lnum
	exe origin_lnum
    else
	exe arrival_lnum
    endif
endfunction
" "}}}2
" }}}1
