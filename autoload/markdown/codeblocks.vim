" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! markdown#codeblocks#InsideCodeblock(...) abort
    let origin_pos = getpos('.')
    if a:0 > 0
        let source_pos = a:1
    else
        let source_pos = line('.')
    endif
    call cursor(source_pos, 1)
    if synIDattr(synID(source_pos, 1, 0), 'name') =~? 'pandocdelimitedcodeblock'
        return 1
    endif
    let prev_delim = searchpair('^[~`]\{3}\s', '', '^[~`]\{3}', 'bnW')
    let next_delim = search('^[~`]\{3}', 'nW')
    call cursor(origin_pos[1], origin_pos[2])
    if prev_delim > 0
        if source_pos > prev_delim && source_pos < next_delim
            return 1
        endif
    endif
endfunction

function! markdown#codeblocks#Lang(...) abort
    let l:lang = ''
    let origin_pos = getpos('.')
    if a:0 > 0
        let source_pos = a:1
    else
        let source_pos = line('.')
    endif
    call cursor(source_pos, 1)
    if markdown#codeblocks#InsideCodeblock(source_pos) == 1
        let l:lang = matchstr(getline('.'),  '\([~`]\{3}\s\+\)\@<=[[:alpha:]]*')
        if l:lang ==# ''
            let start_delim = search('^[~`]\{3}', 'nbW')
            let l:lang = matchstr(getline(start_delim), '\([~`]\{3}\s\+\)\@<=[[:alpha:]]*')
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return l:lang
endfunction

function! markdown#codeblocks#BodyRange(...) abort
    let l:range = []
    let origin_pos = getpos('.')
    if a:0 > 0
        let source_pos = a:1
    else
        let source_pos = line('.')
    endif
    call cursor(source_pos, 1)
    if markdown#codeblocks#InsideCodeblock(source_pos) == 1
        let start_delim = searchpair('^[~`]\{3}', '', '^[~`]\{3}', 'cnbW')
        let end_delim = search('^[~`]\{3}', 'cnW')
        if start_delim != line('.')
            let l:range = [start_delim+1, end_delim-1]
        else
            " we are at the starting delimiter
            if markdown#codeblocks#InsideCodeblock(source_pos-1) == 0
                let l:range = [start_delim + 1, search('^[~`]\{3}', 'nW') -1]
            " we are at the ending delimiter
            else
                let l:range = [search('^[~`]\{3}', 'bnW') + 1, end_delim - 1]
            endif
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return l:range
endfunction
