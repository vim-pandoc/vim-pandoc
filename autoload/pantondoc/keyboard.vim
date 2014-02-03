" vim: set fdm=marker:

function! pantondoc#keyboard#Init()
    noremap <buffer> <silent> <localleader>i :set opfunc=pantondoc#keyboard#EMPH<CR>g@
    vnoremap <buffer> <silent> <localleader>i :<C-U>call pantondoc#keyboard#EMPH(visualmode())<CR>
    noremap <buffer> <silent> <localleader>b :set opfunc=pantondoc#keyboard#BOLD<CR>g@
    vnoremap <buffer> <silent> <localleader>b :<C-U>call pantondoc#keyboard#BOLD(visualmode())<CR>
    noremap <buffer> <silent> <localleader>rg :call pantondoc#keyboard#GOTO_Ref()<CR>
    noremap <buffer> <silent> <localleader>rb :call pantondoc#keyboard#BACKFROM_Ref()<CR>
    "" Add new reference link (or footnote link) after current paragraph. 
    noremap <buffer> <silent> <localleader>nr :call pantondoc#keyboard#Insert_Ref()<cr>a
endfunction

" Italicize: {{{1
function! pantondoc#keyboard#Emph(type)
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
    let @@ = '*'.@@.'*'
    execute "normal P"
    let @@ = reg_save
    let &selection = sel_save
endfunction

function! pantondoc#keyboard#EMPH(type)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    if a:type ==# "v"
	execute "normal! `<".a:type."`>x"
    elseif a:type ==# "char"
        execute "normal! `[ebv`]BEx"
    else
	return
    endif
    let @@ = '*'.@@.'*'
    execute "normal P"
    let @@ = reg_save
    let &selection = sel_save
endfunction
"}}}1
" Bold: {{{1
function! pantondoc#keyboard#Bold(type)
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
    let @@ = '**'.@@.'**'
    execute "normal P"
    let @@ = reg_save
    let &selection = sel_save
endfunction

function! pantondoc#keyboard#BOLD(type)
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    if a:type ==# "v"
	execute "normal! `<b".a:type."`>ex"
    elseif a:type ==# "char"
        execute "normal! `[ebv`]BEx"
    else
	return
    endif
    let @@ = '**'.@@.'**'
    execute "normal P"
    let @@ = reg_save
    let &selection = sel_save
endfunction
" }}}1

" Inserts: {{{1
function! pantondoc#keyboard#Insert_Ref()
    execute "normal! ya\[o\<cr>\<esc>p$a: "
endfunction
" }}}1

" Navigation: {{{1

function! pantondoc#keyboard#GOTO_Ref()
    let reg_save = @@
    execute "mark ".g:pantondoc_mark
    execute "normal! ?[\<cr>vf]y"
    let @@ = substitute(@@, '\[', '\\\[', 'g')
    let @@ = substitute(@@, '\]', '\\\]', 'g')
    execute "normal! /".@@.":\<cr>"
    let @@ = reg_save
endfunction

function! pantondoc#keyboard#BACKFROM_Ref()
    execute "normal!  g'".g:pantondoc_mark
endfunction
" }}}1
