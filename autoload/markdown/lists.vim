" vim: set fdm=marker et ts=4 sw=4 sts=4:

" functions for list navigation

function! markdown#lists#ListItemStart(...) "{{{1
    if a:0 > 0
        let line = getline(a:1)
    else
        let line = getline(".")
    endif
    if 
        \ line =~ '^>\=\s*[*+-]\s\+-\@!' ||
        \ line =~ '^\s*\(\((*\d\+[.)]\+\)\|\((*\l[.)]\+\)\)\s\+' ||
        \ line =~ '^\s*(*\u[.)]\+\s\{2,}' ||
        \ line =~ '^\s*(*[#][.)]\+\s\{1,}' ||
        \ line =~ '^\s*(*@.\{-}[.)]\+\s\{1,}' ||
        \ line =~ '^\s*(*x\=l\=\(i\{,3}[vx]\=\)\{,3}c\{,3}[.)]\+' 
        return 1
    endif
    return 0
endfunction

function! markdown#lists#NextListItem(...) "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line(".")
    endif
    let lnum = search_from + 1
    while lnum <= line("$")
        if markdown#lists#ListItemStart(lnum) == 1
            return lnum
        else
            let lnum = lnum + 1
            continue
        endif
    endwhile
    return -1
endfunction

function! markdown#lists#PrevListItem(...) "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line(".")
    endif
    let lnum = search_from - 1
    while lnum >= 1
        if markdown#lists#ListItemStart(lnum) == 1
            return lnum
        else
            let lnum = lnum - 1
            continue
        endif
    endwhile
    return -1
endfunction

function! markdown#lists#CurrentListItem(...) "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line(".")
    endif
    if markdown#lists#ListItemStart(search_from) == 1
        return search_from
    else
        return markdown#lists#PrevListItem(search_from)
    endif
endfunction

function! markdown#lists#CurrentListItemParent(...) "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line(".")
    endif
    let c_listitem = markdown#lists#CurrentListItem(search_from)
    if c_listitem != -1
        let c_listitem_line = getline(c_listitem)
        let level = len(matchstr(c_listitem_line, '^\s\+'))/4+1
        let lnum = c_listitem
        while lnum >= 1
            let p_listitem = markdown#lists#PrevListItem(lnum)
            let p_level = len(matchstr(getline(p_listitem), '^\s\+'))/4+1
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

function! markdown#lists#SiblingListItem(direction, ...) "{{{1
endfunction

function! markdown#lists#NextSiblingListItem(...) "{{{1
endfunction

function! markdown#lists#PrevSiblingListItem(...) "{{{1
endfunction

function! markdown#lists#FirstChild(...) "{{{1
endfunction

function! markdown#lists#LastChild(...) "{{{1
endfunction

function! markdown#lists#NthChild(count, ...) "{{{1
endfunction
