" vim: set fdm=marker et ts=4 sw=4 sts=4:
"
" functions to handle sections not handled by headers.vim
"
function! markdown#sections#CurrentEndSection(...) abort
    if a:0 > 0
        return markdown#sections#NextEndSection(1, a:1)
    else
        return markdown#sections#NextEndSection(1)
    endif
endfunction

function! markdown#sections#NextEndSection(stop_at_current, ...) abort
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif
    call cursor(search_from[1], 2)
    let next_sect_start = markdown#headers#NextHeader(search_from[1])
    if synIDattr(synID(line('.')+1, 1, 0), 'name') !~#
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

function! markdown#sections#PrevEndSection(...) abort
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

function! markdown#sections#SectionRange(mode, ...) abort
    let c_header = markdown#headers#CurrentHeader()
    if c_header == 0
        let start = 1
    else
        if a:mode ==# 'inclusive'
            let start = c_header
        elseif a:mode ==# 'exclusive'
            let start = c_header + 1
        endif
    endif
    let n_sibling_header = markdown#headers#NextSiblingHeader()
    if n_sibling_header == 0
        let n_header = markdown#headers#NextHeader()
        if n_header == 0 || n_header == line('.')
            let end = line('$')
        else
            let end = n_header - 1
        endif
    else
        let end = n_sibling_header - 1
    endif
    return [start, end]
endfunction
