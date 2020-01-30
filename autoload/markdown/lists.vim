" vim: set fdm=marker et ts=4 sw=4 sts=4:

" functions for list navigation
"

function! markdown#lists#ListItemStart(...) abort "{{{1
    if a:0 > 0
        let line = getline(a:1)
    else
        let line = getline('.')
    endif
    if
        \ line =~# '^>\=\s*[*+-]\s\+-\@!' ||
        \ line =~# '^\s*\(\((*\d\+[.)]\+\)\|\((*\l[.)]\+\)\)\s\+' ||
        \ line =~# '^\s*(*\u[.)]\+\s\{2,}' ||
        \ line =~# '^\s*(*[#][.)]\+\s\{1,}' ||
        \ line =~# '^\s*(*@.\{-}[.)]\+\s\{1,}' ||
        \ line =~# '^\s*(*x\=l\=\(i\{,3}[vx]\=\)\{,3}c\{,3}[.)]\+'
        return 1
    endif
    return 0
endfunction

function! markdown#lists#ListStart(...) abort "{{{1
    if a:0 > 0
        let l:l = a:1
    else
        let l:l = line('.')
    endif
    let orig_pos = getpos('.')[1:]
    call cursor(l:l, 0)
    normal! {
    if getpos('.')[1:] == orig_pos && markdown#lists#ListItemStart() != 1
        return -1
    endif
    normal! w
    let pos = markdown#lists#ListItemStart()
    if pos == 1
        let c_par_start = line('.')
        normal! 2{w
        let p_par_start = line('.')
        if c_par_start != p_par_start
            let check_prev = markdown#lists#ListItemStart()
            if check_prev == 1
                let l:l = markdown#lists#ListStart()
            else
                normal! }w
                let l:l = line('.')
            endif
        else
            let l:l = c_par_start
        endif
    else
        let l:l = -1
    endif
    call cursor(orig_pos)
    return l:l
endfunction

function! markdown#lists#ListEnd(...) abort "{{{1
    if markdown#lists#ListStart() == -1
        " not in a list
        return -1
    endif
    if a:0 > 0
        let l:l = a:1
    else
        let l:l = line('.')
    endif
    let orig_pos = getpos('.')[1:]
    call cursor(l:l,0)
    if getline(l:l) =~# '^\s*$' && markdown#lists#ListItemStart(l:l+1) == 0
        " the list just ended
        return l:l-1
    endif
    normal! }
    let c_lnum = line('.')
    let c_par_end = c_lnum-1
    let next_par_start = c_lnum+1
    let pos = markdown#lists#ListItemStart(next_par_start)
    if pos == 1
        let l:l = markdown#lists#ListEnd(next_par_start)
    elseif c_lnum == line('$')
        let l:l = c_lnum
    else
        let l:l = c_par_end
    endif
    call cursor(orig_pos)
    return l:l
endfunction

function! markdown#lists#ListKind(...) abort "{{{1
    if a:0 > 0
        let line = getline(a:1)
    else
        let line = getline('.')
    endif
    if line =~# '^>\=\s*[*+-]\s\+-\@!'
        return 'ul'
    else
        return 'ol'
    endif
endfunction

function! markdown#lists#NextListItem(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let lnum = search_from + 1
    if markdown#lists#ListStart(search_from) > -1
        while lnum <= line('$')
            if markdown#lists#ListStart(lnum+1) == -1
                return markdown#lists#CurrentListItem(lnum)
            endif
            if markdown#lists#ListItemStart(lnum) == 1
                return lnum
            else
                let lnum = lnum + 1
                continue
            endif
        endwhile
    endif
    return -1
endfunction

function! markdown#lists#PrevListItem(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let lnum = search_from - 1
    while lnum >= 1
        if markdown#lists#ListStart(lnum) == -1
            return -1
        endif
        if markdown#lists#ListItemStart(lnum) == 1
            return lnum
        else
            let lnum = lnum - 1
            continue
        endif
    endwhile
    return -1
endfunction

function! markdown#lists#CurrentListItem(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    if markdown#lists#ListItemStart(search_from) == 1
        return search_from
    else
        return markdown#lists#PrevListItem(search_from)
    endif
endfunction

function! markdown#lists#ListItemLevel(line) abort "{{{1
    return len(matchstr(a:line, '^\s\+'))/4+1
endfunction

function! markdown#lists#CurrentListItemParent(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let c_listitem = markdown#lists#CurrentListItem(search_from)
    if c_listitem != -1
        let c_listitem_text = getline(c_listitem)
        let level = markdown#lists#ListItemLevel(c_listitem_text)
        let lnum = c_listitem
        while lnum >= 1
            let p_listitem = markdown#lists#PrevListItem(lnum)
            let p_level = markdown#lists#ListItemLevel(p_listitem)
            if p_level < level
                return p_listitem
            else
                let lnum = p_listitem
                continue
            endif
        endwhile
    endif
    return -1
endfunction

function! markdown#lists#ListItemSibling(direction, ...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let c_listitem_lnum = markdown#lists#CurrentListItem(search_from)
    let c_listitem_level = markdown#lists#ListItemLevel(getline(c_listitem_lnum))
    let parent_lnum = markdown#lists#CurrentListItemParent(c_listitem_lnum)

    if a:direction ==# 'b'
        let while_cond = 'lnum >= 1'
    else
        let while_cond = 'lnum <= line("$")'
    endif

    let lnum = c_listitem_lnum
    while eval(while_cond)
        if a:direction ==# 'b'
            let listitem_lnum = markdown#lists#PrevListItem(lnum)
        else
            let listitem_lnum = markdown#lists#NextListItem(lnum)
        endif
        let listitem_level = markdown#lists#ListItemLevel(getline(listitem_lnum))
        if listitem_level == c_listitem_level
            return listitem_lnum
        else
            if listitem_level > c_listitem_level
                let lnum = listitem_lnum
            else
                return -1
            endif
        endif
    endwhile
endfunction

function! markdown#lists#NextListItemSibling(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    return markdown#lists#ListItemSibling('', search_from)
endfunction

function! markdown#lists#PrevListItemSibling(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    return markdown#lists#ListItemSibling('b', search_from)
endfunction

function! markdown#lists#FirstChild(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let c_listitem_level = markdown#lists#ListItemLevel(getline(markdown#lists#CurrentListItem()))
    let n_litem_lnum = markdown#lists#NextListItem()
    let n_litem_text = getline(n_litem_lnum)
    let n_litem_level = markdown#lists#ListItemLevel(n_litem_text)
    if n_litem_level > c_listitem_level
        return n_litem_lnum
    else
        return -1
    endif
endfunction

function! markdown#lists#LastChild(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let first_child = markdown#lists#FirstChild(search_from)
    if first_child != -1
        let n_litem_lnum = markdown#lists#NextListItemSibling(first_child)
        let n_litem_parent_lnum = markdown#lists#CurrentListItemParent(n_litem_lnum)
        while 1
            let n_n_litem_lnum = markdown#lists#NextListItemSibling(n_litem_lnum)
            if n_n_litem_lnum == -1
                return n_litem_lnum
            else
                let n_litem_lnum = n_n_litem_lnum
            endif
        endwhile
    else
        return -1
    endif
    return -1
endfunction

function! markdown#lists#NthChild(count, ...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    let item_lnum = markdown#lists#FirstChild(search_from)
    if item_lnum != -1
        if a:count == 1
            return item_lnum
        else
            for idx in range(a:count-1)
                let item_lnum = markdown#lists#NextListItemSibling(item_lnum)
            endfor
        endif
        return item_lnum
    endif
endfunction
