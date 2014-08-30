" vim: set fdm=marker et ts=4 sw=4 sts=4:
"
" functions to handle sections not handled by headers.vim
"
function! markdown#sections#CurrentEndSection(...)
    if a:0 > 0
        return markdown#sections#NextEndSection(1, a:1)
    else
        return markdown#sections#NextEndSection(1)
    endif
endfunction

function! markdown#sections#NextEndSection(stop_at_current, ...)
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif
    call cursor(search_from[1], 2)
    let next_sect_start = markdown#headers#NextHeader(search_from[1])
    if synIDattr(synID(line('.')+1, 1, 0), "name") !~# 
                \'pandoc\(SetexHeader\|AtxStart\)'
        let lnum = next_sect_start - 1
    else
        if a:stop_at_current == 1
            let lnum = search_from[1]
        else
            let lnum = markdown#headers#NextHeader(next_sect_start) - 1
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return lnum
endfunction

function! markdown#sections#PrevEndSection(...)
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif
    call cursor(search_from[1], 2)
    if search_from[1] != markdown#headers#CurrentHeader(search_from[1])
        let lnum = markdown#headers#PrevHeader(search_from[1]) - 1
    else
        let lnum = search_from[1] - 1
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return lnum
endfunction
