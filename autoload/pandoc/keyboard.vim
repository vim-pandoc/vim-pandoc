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
    " Use default mappings? {{{3
    if !exists("g:pandoc#keyboard#use_default_mappings")
        let g:pandoc#keyboard#use_default_mappings = 1
    endif

    " Mappings: {{{2
    " Display_Motion: {{{3
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
   
    " Styling: {{{3
    for style in ["emphasis", "strong", "verbatim", "strikeout", "superscript", "subscript"]
        let u_style = substitute(style, '\<.', '\u&', '') " capitalize first char: emphasis -> Emphasis
        exe 'noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :set opfunc=pandoc#keyboard#Toggle'.u_style.'<cr>g@'
        exe 'vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-'.style.') :<C-U>call pandoc#keyboard#Toggle'.u_style.'(visualmode())<CR>'
    endfor
    " Sections: {{{3
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-apply-header) :<C-U>call pandoc#keyboard#ApplyHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-remove-header) :call pandoc#keyboard#RemoveHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-header) :call pandoc#keyboard#NextHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-header) :call pandoc#keyboard#PrevHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ff-header) :<C-U>call pandoc#keyboard#ForwardHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-rw-header) :<C-U>call pandoc#keyboard#BackwardHeader(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ff-sect-end) :<C-U>call pandoc#keyboard#NextSectionEnd(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-rw-sect-end) :<C-U>call pandoc#keyboard#PrevSectionEnd(v:count1)<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-header) :call pandoc#keyboard#CurrentHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-header-parent) :call pandoc#keyboard#CurrentHeaderParent()<cr>
    vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-section-inclusive) :<C-U>call pandoc#keyboard#SelectSection('inclusive')<cr>
    vnoremap <buffer> <silent> <Plug>(pandoc-keyboard-select-section-exclusive) :<C-U>call pandoc#keyboard#SelectSection('exclusive')<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-header-sibling) :call pandoc#keyboard#NextSiblingHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-header-sibling) :call pandoc#keyboard#PrevSiblingHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-first-header-child) :call pandoc#keyboard#FirstChildHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-last-header-child) :call pandoc#keyboard#LastChildHeader()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-nth-header-child) :<C-U>call pandoc#keyboard#GotoNthChildHeader(v:count1)<cr>
    " References: {{{3
    " Add new reference link (or footnote link) after current paragraph.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-insert) :call pandoc#keyboard#Insert_Ref()<cr>a
    " Go to link or footnote definition for label under the cursor.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-goto) :call pandoc#keyboard#GOTO_Ref()<CR>
    " Go back to last point in the text we jumped to a reference from.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-backfrom) :call pandoc#keyboard#BACKFROM_Ref()<CR>
    " }}}
    " Lists: {{{3
    " navigation: {{{4
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-li) :call pandoc#keyboard#NextListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-li) :call pandoc#keyboard#PrevListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-li) :call pandoc#keyboard#CurrentListItem()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-cur-li-parent) :call pandoc#keyboard#CurrentListItemParent()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-next-li-sibling) :call pandoc#keyboard#NextListItemSibling()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-prev-li-sibling) :call pandoc#keyboard#PrevListItemSibling()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-first-li-child) :call pandoc#keyboard#FirstListItemChild()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-last-li-child) :call pandoc#keyboard#LastListItemChild()<cr>
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-nth-li-child) :<C-U>call pandoc#keyboard#GotoNthListItemChild(v:count1)<cr>
    "}}}2
    " Default mappings: {{{2
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
        nmap <buffer> <localleader># <Plug>(pandoc-keyboard-apply-header)
        nmap <buffer> <localleader>hd <Plug>(pandoc-keyboard-remove-header)
        nmap <buffer> <localleader>hn <Plug>(pandoc-keyboard-next-header)
        nmap <buffer> <localleader>hb <Plug>(pandoc-keyboard-prev-header)
        nmap <buffer> <localleader>hh <Plug>(pandoc-keyboard-cur-header)
        nmap <buffer> <localleader>hp <Plug>(pandoc-keyboard-cur-header-parent)
        nmap <buffer> <localleader>hsn <Plug>(pandoc-keyboard-next-header-sibling)
        nmap <buffer> <localleader>hsb <Plug>(pandoc-keyboard-prev-header-sibling)
        nmap <buffer> <localleader>hcf <Plug>(pandoc-keyboard-first-header-child)
        nmap <buffer> <localleader>hcl <Plug>(pandoc-keyboard-last-header-child)
        nmap <buffer> <localleader>hcn <Plug>(pandoc-keyboard-nth-header-child)
        nmap <buffer> ]] <Plug>(pandoc-keyboard-ff-header)
        nmap <buffer> [[ <Plug>(pandoc-keyboard-rw-header)
        nmap <buffer> ][ <Plug>(pandoc-keyboard-ff-sect-end)
        nmap <buffer> [] <Plug>(pandoc-keyboard-rw-sect-end)
        vmap <buffer> aS <Plug>(pandoc-keyboard-select-section-inclusive)
        omap <buffer> aS :normal VaS<cr>
        vmap <buffer> iS <Plug>(pandoc-keyboard-select-section-exclusive)
        omap <buffer> iS :normal ViS<cr>
        nmap <buffer> <localleader>nr <Plug>(pandoc-keyboard-ref-insert)
        nmap <buffer> <localleader>rg <Plug>(pandoc-keyboard-ref-goto)
        nmap <buffer> <localleader>rb <Plug>(pandoc-keyboard-ref-backfrom)
        nmap <buffer> <localleader>ln <Plug>(pandoc-keyboard-next-li)
        nmap <buffer> <localleader>lp <Plug>(pandoc-keyboard-prev-li)
        nmap <buffer> <localleader>ll <Plug>(pandoc-keyboard-cur-li)
        nmap <buffer> <localleader>llp <Plug>(pandoc-keyboard-cur-li-parent)
        nmap <buffer> <localleader>lsn <Plug>(pandoc-keyboard-next-li-sibling)
        nmap <buffer> <localleader>lsp <Plug>(pandoc-keyboard-prev-li-sibling)
        nmap <buffer> <localleader>lcf <Plug>(pandoc-keyboard-first-li-child)
        nmap <buffer> <localleader>lcl <Plug>(pandoc-keyboard-last-li-child)
        nmap <buffer> <localleader>lcn <Plug>(pandoc-keyboard-nth-li-child)
    endif
    " }}}2
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
    normal ^
endfunction
" }}}1
" Styling: {{{1
" Base: {{{2
" Toggle Operators, WYSIWYG-style {{{3
function! pandoc#keyboard#ToggleOperator(type, ends)
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
function! pandoc#keyboard#Apply(type, ends)
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
    let reg_save = getreg('*')
    normal "*ya[
    call search('\n\(\n\|\_$\)\@=')
    execute "normal! o\<cr>\<esc>0".'"*P'."$a: "
    call setreg('*', reg_save)
endfunction
" }}}2
" navigation: {{{2

function! pandoc#keyboard#GOTO_Ref()
    let reg_save = getreg('*')
    execute "normal m".g:pandoc#keyboard#mark
    execute "silent normal! ?[\<cr>vf]".'"*y'
    call setreg('*', substitute(getreg('*'), '\[', '\\\[', 'g'))
    call setreg('*', substitute(getreg('*'), '\]', '\\\]', 'g'))
    execute "silent normal! /".getreg('*').":\<cr>"
    call setreg('*', reg_save)
endfunction

function! pandoc#keyboard#BACKFROM_Ref()
    try
        execute 'normal  `'.g:pandoc#keyboard#mark
        " clean up
        execute 'delmark '.g:pandoc#keyboard#mark
    catch /E20/ "no mark set, we must search backwards.
        let reg_save = getreg('*')
        "move right, because otherwise it would fail if the cursor is at the
        "beggining of the line
        execute "silent normal! 0l?[\<cr>vf]".'"*y'
        call setreg('*', substitute(getreg('*'), '\]', '\\\]', 'g'))
        execute "silent normal! ?".getreg('*')."\<cr>"
        call setreg('*', reg_save)
    endtry
endfunction

function! pandoc#keyboard#NextRefDefinition()
endfunction

function! pandoc#keyboard#PrevRefDefinition()
endfunction
" }}}2
" }}}1
" Sections: {{{1

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

function! pandoc#keyboard#ForwardHeader(count) "{{{3
    call s:MovetoLine(markdown#headers#ForwardHeader(a:count))
endfunction

function! pandoc#keyboard#BackwardHeader(count) "{{{3
    call s:MovetoLine(markdown#headers#BackwardHeader(a:count))
endfunction

function! pandoc#keyboard#NextSectionEnd(count) "{{{3
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#sections#NextEndSection(0, lnum)
    endfor
    call s:MovetoLine(lnum)
endfunction

function! pandoc#keyboard#PrevSectionEnd(count) "{{{3
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#sections#PrevEndSection(lnum)
    endfor
    call s:MovetoLine(lnum)
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

function! pandoc#keyboard#FirstChildHeader() "{{{3
    call s:MovetoLine(markdown#headers#FirstChild())
endfunction

function! pandoc#keyboard#LastChildHeader() "{{{3
    call s:MovetoLine(markdown#headers#LastChild())
endfunction

function! pandoc#keyboard#GotoNthChildHeader(count) "{{{3
    call s:MovetoLine(markdown#headers#NthChild(a:count))
endfunction
" "}}}2
" text objects: {{{2
function! pandoc#keyboard#SelectSection(mode) "{{{3
    let range = markdown#sections#SectionRange(a:mode)
    let start= range[0]
    let end = range[1] - 1
    exe "normal! ".start."GV".end."G\<cr>"
endfunction
"}}}2
" }}}1
" Lists: {{{1
" navigation:{{{2
function! pandoc#keyboard#NextListItem() "{{{3
    call s:MovetoLine(markdown#lists#NextListItem())
endfunction

function! pandoc#keyboard#PrevListItem() "{{{3
    call s:MovetoLine(markdown#lists#PrevListItem())
endfunction

function! pandoc#keyboard#CurrentListItem() "{{{3
    call s:MovetoLine(markdown#lists#CurrentListItem())
endfunction

function! pandoc#keyboard#CurrentListItemParent() "{{{3
    call s:MovetoLine(markdown#lists#CurrentListItemParent())
endfunction

function! pandoc#keyboard#NextListItemSibling() "{{{3
    call s:MovetoLine(markdown#lists#NextListItemSibling())
endfunction

function! pandoc#keyboard#PrevListItemSibling() "{{{3
    call s:MovetoLine(markdown#lists#PrevListItemSibling())    
endfunction

function! pandoc#keyboard#FirstListItemChild() "{{{3
    call s:MovetoLine(markdown#lists#FirstChild())
endfunction

function! pandoc#keyboard#LastListItemChild() "{{{3
    call s:MovetoLine(markdown#lists#LastChild())
endfunction

function! pandoc#keyboard#GotoNthListItemChild(count) "{{{3
    call s:MovetoLine(markdown#lists#NthChild(a:count))
endfunction
" }}}1
