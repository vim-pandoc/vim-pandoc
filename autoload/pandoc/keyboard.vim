" vim: set fdm=marker et ts=4 sw=4 sts=4:

" Init: {{{1
function! pandoc#keyboard#Init()
    " set up defaults {{{2
    " Use display motions when using soft wrapping {{{3
    if !exists("g:pandoc#keyboard#display_motions")
        let g:pandoc#keyboard#display_motions = 1
    endif

    " We use a mark for some functions, the user can change it {{{3
    " so it doesn't interfere with his settings
    if !exists("g:pandoc#keyboard#mark")
        let g:pandoc#keyboard#mark = "r"
    endif

    " What style to use when applying header styles {{{3
    " a: atx headers
    " s: setex headers for 1st and 2nd levels
    " 2: add hashes at both ends
    if !exists("g:pandoc#keyboard#header_style")
        let g:pandoc#keyboard#header_style = "a"
    endif

    " Display_Motion: {{{2
    if g:pandoc#keyboard#display_motions == 1
        " these are not useful when using the hard wraps mode.
        if exists("g:pandoc#formatting#mode") && stridx(g:pandoc#formatting#mode, "s") > -1
            " Remappings that make j and k behave properly with soft wrapping.
            nnoremap <buffer> j gj
            nnoremap <buffer> k gk
            vnoremap <buffer> j gj
            vnoremap <buffer> k gk
        endif
    endif
   
    " Styling: {{{2
    " Toggle emphasis, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>i :set opfunc=pandoc#keyboard#ToggleEmphasis<cr>g@
    vnoremap <buffer> <silent> <localleader>i :<C-U>call pandoc#keyboard#ToggleEmphasis(visualmode())<CR>
    " Toggle strong, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>b :set opfunc=pandoc#keyboard#ToggleStrong<cr>g@
    vnoremap <buffer> <silent> <localleader>b :<C-U>call pandoc#keyboard#ToggleStrong(visualmode())<CR>
    " Toggle verbatim, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>` :set opfunc=pandoc#keyboard#ToggleVerbatim<cr>g@
    vnoremap <buffer> <silent> <localleader>` :<C-U>call pandoc#keyboard#ToggleVerbatim(visualmode())<CR>
    " Toggle strikeout, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>~~ :set opfunc=pandoc#keyboard#ToggleStrikeout<cr>g@
    vnoremap <buffer> <silent> <localleader>~~ :<C-U>call pandoc#keyboard#ToggleStrikeout(visualmode())<CR>
    " Toggle superscript, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>^ :set opfunc=pandoc#keyboard#ToggleSuperscript<cr>g@
    vnoremap <buffer> <silent> <localleader>^ :<C-U>call pandoc#keyboard#ToggleSuperscript(visualmode())<CR>
    " Toggle subscript, WYSIWYG word processor style
    noremap <buffer> <silent> <localleader>_ :set opfunc=pandoc#keyboard#ToggleSubscript<cr>g@
    vnoremap <buffer> <silent> <localleader>_ :<C-U>call pandoc#keyboard#ToggleSubscript(visualmode())<CR>

    " Headers: {{{2
    noremap <buffer> <silent> <localleader># :<C-U>call pandoc#keyboard#ApplyHeader(v:count1)<cr>
    noremap <buffer> <silent> <localleader>hd :call pandoc#keyboard#RemoveHeader()<cr>
    noremap <buffer> <silent> <localleader>hn :call pandoc#keyboard#NextHeader()<cr>
    noremap <buffer> <silent> <localleader>hb :call pandoc#keyboard#PrevHeader()<cr>
    noremap <buffer> <silent> <localleader>hh :call pandoc#keyboard#CurrentHeader()<cr>
    noremap <buffer> <silent> <localleader>hp :call pandoc#keyboard#CurrentHeaderParent()<cr>
    noremap <buffer> <silent> <localleader>hsn :call pandoc#keyboard#NextSiblingHeader()<cr>
    noremap <buffer> <silent> <localleader>hsb :call pandoc#keyboard#PrevSiblingHeader()<cr>
    noremap <buffer> <silent> <localleader>hcf :call pandoc#keyboard#FirstChild()<cr>
    noremap <buffer> <silent> <localleader>hcl :call pandoc#keyboard#LastChild()<cr>
    noremap <buffer> <silent> <localleader>hcn :<C-U>call pandoc#keyboard#GotoNthChild(v:count1)<cr>

    " References: {{{2
    " Add new reference link (or footnote link) after current paragraph.
    noremap <buffer> <silent> <localleader>nr :call pandoc#keyboard#Insert_Ref()<cr>a
    " Go to link or footnote definition for label under the cursor.
    noremap <buffer> <silent> <localleader>rg :call pandoc#keyboard#GOTO_Ref()<CR>
    " Go back to last point in the text we jumped to a reference from.
    noremap <buffer> <silent> <localleader>rb :call pandoc#keyboard#BACKFROM_Ref()<CR>
    " }}}
endfunction
"}}}1
" Auxiliary: {{{1
function! s:EscapeEnds(ends)
    return escape(a:ends, '*^~')
endfunction

function! s:MovetoLine(line)
    if a:line > 0
        call cursor(a:line, 1)
    endif
endfunction
" }}}1
" Styling: {{{1
" Base: {{{2
" Toggle Operators, WYSIWYG-style {{{3
function! pandoc#keyboard#ToggleOperator(type, ends)
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
function! pandoc#keyboard#Apply(type, ends)
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
function! pandoc#keyboard#Emph(type)
    return pandoc#keyboard#Apply(a:type, "*")
endfunction
" }}}3
" WYSIWYG-style toggle {{{3
"
function! pandoc#keyboard#ToggleEmphasis(type)
    return pandoc#keyboard#ToggleOperator(a:type, "*")
endfunction
" }}}3
"}}}2
" Strong: {{{2
function! pandoc#keyboard#Strong(type)
    return pandoc#keyboard#Apply(a:type, "**")
endfunction
function! pandoc#keyboard#ToggleStrong(type)
    return pandoc#keyboard#ToggleOperator(a:type, "**")
endfunction
"}}}2
" Verbatim: {{{2
function! pandoc#keyboard#Verbatim(type)
    return pandoc#keyboard#Apply(a:type, "`")
endfunction
function! pandoc#keyboard#ToggleVerbatim(type)
    return pandoc#keyboard#ToggleOperator(a:type, "`")
endfunction
" }}}2
" Strikeout: {{{2
function! pandoc#keyboard#Strikeout(type)
    return pandoc#keyboard#Apply(a:type, "~~")
endfunction
function! pandoc#keyboard#ToggleStrikeout(type)
    return pandoc#keyboard#ToggleOperator(a:type, "~~")
endfunction
" }}}2
" Superscript: {{{2
function! pandoc#keyboard#Superscript(type)
    return pandoc#keyboard#Apply(a:type, "^")
endfunction
function! pandoc#keyboard#ToggleSuperscript(type)
    return pandoc#keyboard#ToggleOperator(a:type, "^")
endfunction
" }}}2
" Subscript: {{{2
function! pandoc#keyboard#Subscript(type)
    return pandoc#keyboard#Apply(a:type, "~")
endfunction
function! pandoc#keyboard#ToggleSubscript(type)
    return pandoc#keyboard#ToggleOperator(a:type, "~")
endfunction
" }}}2
"}}}1
" References: {{{1
" handling: {{{2
function! pandoc#keyboard#Insert_Ref()
    execute "normal m".g:pandoc#keyboard#mark
    let reg_save = @@
    normal ya[
    call search('\n\(\n\|\_$\)\@=')
    execute "normal! o\<cr>\<esc>0P$a: "
    let @@ = reg_save
endfunction
" }}}2
" navigation: {{{2

function! pandoc#keyboard#GOTO_Ref()
    let reg_save = @@
    execute "normal m".g:pandoc#keyboard#mark
    execute "silent normal! ?[\<cr>vf]y"
    let @@ = substitute(@@, '\[', '\\\[', 'g')
    let @@ = substitute(@@, '\]', '\\\]', 'g')
    execute "silent normal! /".@@.":\<cr>"
    let @@ = reg_save
endfunction

function! pandoc#keyboard#BACKFROM_Ref()
    try
        execute 'normal  `'.g:pandoc#keyboard#mark
        " clean up
        execute 'delmark '.g:pandoc#keyboard#mark
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

function! pandoc#keyboard#NextRefDefinition()
endfunction

function! pandoc#keyboard#PrevRefDefinition()
endfunction
" }}}2
" }}}1
" Headers: {{{1

" handling: {{{2
function! pandoc#keyboard#ApplyHeader(level) "{{{3
    call pandoc#keyboard#RemoveHeader()
    if a:level == 0
        return
    endif

    let line_text = getline(".")
    if a:level < 3 && (g:pandoc#keyboard#header_style =~ "s") == 1
       let text = line_text
    else
       if (g:pandoc#keyboard#header_style =~ "2") == 1
           let tail = ' ' . repeat("#", a:level)
       else
           let tail = ''
       endif
       let text = repeat("#", a:level) . ' ' . line_text . tail
    endif
    call setline(line("."), text)
   
    if (g:pandoc#keyboard#header_style =~ "s") == 1
        if a:level == 1
            call append(line("."), repeat("=", len(text)))
        elseif a:level == 2
            call append(line("."), repeat("-", len(text)))
        endif
    endif
endfunction

function! pandoc#keyboard#RemoveHeader() "{{{3
    let lnum = line(".")
    let line_text = getline(".")
    if match(line_text, "^#") > -1
        let line_text = substitute(line_text, "^#* *", '', '')
        if match(line_text, " #*$") > -1
            let line_text = substitute(line_text, " #*$", '', '')
        endif
    elseif match(getline(line(".")+1), "^[-=]") > -1
        exe line(".")+1.'delete "_'
    endif
    exe lnum
    call setline(line("."), line_text)
endfunction
" }}}2
" navigation: {{{2
function! pandoc#keyboard#NextHeader() "{{{3
    call s:MovetoLine(markdown#headers#NextHeader())
endfunction

function! pandoc#keyboard#PrevHeader() "{{{3
    call s:MovetoLine(markdown#headers#PrevHeader())
endfunction

function! pandoc#keyboard#CurrentHeader() "{{{3
    call s:MovetoLine(markdown#headers#CurrentHeader())
endfunction

function! pandoc#keyboard#CurrentHeaderParent() "{{{3
    call s:MovetoLine(markdown#headers#CurrentHeaderParent())
endfunction

function! pandoc#keyboard#NextSiblingHeader() "{{{3
    call s:MovetoLine(markdown#headers#NextSiblingHeader())
endfunction

function! pandoc#keyboard#PrevSiblingHeader() "{{{3
    call s:MovetoLine(markdown#headers#PrevSiblingHeader())
endfunction

function! pandoc#keyboard#FirstChild() "{{{3
    call s:MovetoLine(markdown#headers#FirstChild())
endfunction

function! pandoc#keyboard#LastChild() "{{{3
    call s:MovetoLine(markdown#headers#LastChild())
endfunction

function! pandoc#keyboard#GotoNthChild(count) "{{{3
    call s:MovetoLine(markdown#headers#NthChild(a:count))
endfunction
" "}}}2
" }}}1
