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

    " Navigation:
    " Go to link or footnote definition for label under the cursor.
    noremap <buffer> <silent> <localleader>rg :call pantondoc#keyboard#GOTO_Ref()<CR>
    " Go back to last point in the text we jumped to a reference from.
    noremap <buffer> <silent> <localleader>rb :call pantondoc#keyboard#BACKFROM_Ref()<CR>
    
    " Inserts:
    " Add new reference link (or footnote link) after current paragraph. 
    noremap <buffer> <silent> <localleader>nr :call pantondoc#keyboard#Insert_Ref()<cr>a
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
" Inserts: {{{1
function! pantondoc#keyboard#Insert_Ref()
    execute "normal m".g:pantondoc_mark
    execute "normal! ya\[o\<cr>\<esc>p$a: "
endfunction
" }}}1
" Navigation: {{{1

" References: {{{2

function! pantondoc#keyboard#GOTO_Ref()
    let reg_save = @@
    execute "normal m".g:pantondoc_mark
    execute "silent normal! ?[\<cr>vf]y"
    let @@ = substitute(@@, '\[', '\\\[', 'g')
    let @@ = substitute(@@, '\]', '\\\]', 'g')
    execute "normal! /".@@.":\<cr>"
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
        execute "silent normal! ^\<right>?[\<cr>vf]y"
	let @@ = substitute(@@, '\]', '\\\]', 'g')
	execute "silent normal! ?".@@."\<cr>"
	let @@ = reg_save
    endtry
endfunction
" }}}2
"
" Headers: {{{2
" TODO
" "}}}2
" }}}1
