" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! markdown#tex#InsideTeXBlock(...)
    let origin_pos = getpos(".")
    if a:0 > 0
        let source_pos = a:1
    else
        let source_pos = line(".")
    endif
    call cursor(source_pos, 1)
    if synIDattr(synID(source_pos, 1, 0), "name") =~? "^tex"
        return 1
    endif
    let prev_delim = searchpair('^$\{2}', '', '^$\{2}', 'bnW')
    let next_delim = search('^$\{2}', 'nW')
    call cursor(origin_pos[1], origin_pos[2])
    if prev_delim > 0
        if source_pos > prev_delim && source_pos < next_delim
            return 1
        endif
    endif
endfunction

function! markdown#tex#BodyRange(...)
    let l:range = []
    let origin_pos = getpos(".")
    if a:0 > 0
        let source_pos = a:1
    else
        let source_pos = line(".")
    endif
    call cursor(source_pos, 1)
    if markdown#tex#InsideTeXBlock(source_pos) == 1
        let start_delim = searchpair('^$\{2}', '', '^$\{2}', 'cnbW')
        let end_delim = search('^$\{2}', 'cnW')
        if start_delim != line(".")
            let l:range = [start_delim+1, end_delim-1]
        else
            " we are at the starting delimiter
            if markdown#tex#InsideTeXBlock(source_pos-1) == 0
                let l:range = [start_delim + 1, search('^$\{2}', 'nW') -1]
            " we are at the ending delimiter
            else
                let l:range = [search('^$\{2}', 'bnW') + 1, end_delim - 1]
            endif
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return l:range
endfunction
