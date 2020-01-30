" vim: set fdm=marker et ts=4 sw=4 sts=4:

" functions for header navigation and information retrieval.

function! markdown#headers#CheckValidHeader(lnum) abort "{{{1
    if a:lnum != 0
        if exists('g:vim_pandoc_syntax_exists')
            let synId = synIDattr(synID(a:lnum, 1, 1), 'name')
            if synId !~# '^pandoc' || synId ==# 'pandocDelimitedCodeBlock'
                return 0
            endif
        endif
        if match(getline(a:lnum), '^#') >= 0 || match(getline(a:lnum+1), '^[-=]') >= 0
            return 1
        endif
    endif
    return 0
endfunction

function! markdown#headers#NextHeader(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif
    call cursor(search_from[1], 2)
    let h_lnum = search('\(^.*\n[-=]\{2\}\|^#\)','nW')
    if h_lnum != 0 && markdown#headers#CheckValidHeader(h_lnum) != 1
        let h_lnum = markdown#headers#NextHeader(h_lnum)
    endif
    if h_lnum == 0
        if match(getline('.'), '^#') >= 0 || match(getline(line('.')+1), '^[-=]') >= 0
            let h_lnum = line('.')
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return h_lnum
endfunction

function! markdown#headers#PrevHeader(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif
    call cursor(search_from[1], 1)
    let h_lnum = search('\(^.*\n[-=]\{2\}\|^#\)', 'bnW')
    if h_lnum != 0 && markdown#headers#CheckValidHeader(h_lnum) != 1
        let h_lnum = markdown#headers#PrevHeader(h_lnum)
        " we might go back into the YAML frontmatter, we must recheck if we
        " are fine
        if markdown#headers#CheckValidHeader(h_lnum) != 1
            let h_lnum = 0
        endif
    endif
    if h_lnum == 0
        if match(getline('.'), '^#') >= 0 || match(getline(line('.')+1), '^[-=]') >= 0
            let h_lnum = line('.')
        endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return h_lnum
endfunction

function! markdown#headers#ForwardHeader(count) abort "{{{1
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#headers#NextHeader(lnum)
    endfor
    return lnum
endfunction

function! markdown#headers#BackwardHeader(count) abort "{{{1
    let lnum = line('.')
    for i in range(a:count)
        let lnum = markdown#headers#PrevHeader(lnum)
    endfor
    return lnum
endfunction

function! markdown#headers#CurrentHeader(...) abort "{{{1
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif
    " same as PrevHeader(), except don't search if we are already at a header
    if match(getline(search_from[1]), '^#') < 0 && match(getline(search_from[1]+1), '^[-=]') < 0
        return markdown#headers#PrevHeader(search_from[1])
    else
        return search_from[1]
    endif
endfunction

function! markdown#headers#CurrentHeaderParent(...) abort "{{{1
    let origin_pos = getpos('.')

    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    let ch_lnum = markdown#headers#CurrentHeader(search_from[1])

    call cursor(ch_lnum, 1)
    let l = getline('.')

    if match(l, '^#') > -1
        let parent_level = len(matchstr(l, '#*')) - 1
    elseif match(getline(line('.')+1), '^-') > -1
        let parent_level = 1
    else
        let parent_level = 0
    endif

    " don't go further than level 1 headers
    if parent_level > 0
        if parent_level == 1
            let setext_regex = "^.*\\n="
        else
            let setext_regex = "^.*\\n[-=]"
        endif

        let arrival_lnum = search('\('.setext_regex.'\|^#\{1,'.parent_level.'}\s\)', 'bnW')
        if markdown#headers#CheckValidHeader(arrival_lnum) != 1
            let arrival_lnum = search('\('.setext_regex.'\|^#\{1,'.parent_level.'}\s\)', 'bnW')
            if markdown#headers#CheckValidHeader(arrival_lnum) != 1
                let arrival_lnum = 0
            endif
        endif
    else
        let arrival_lnum = 0
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return arrival_lnum
endfunction

function! markdown#headers#CurrentHeaderAncestral(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif
    let p_lnum = markdown#headers#CurrentHeaderParent(search_from[1])
    " we don't have a parent, so we are an ancestral
    " or we are not under a header
    if p_lnum == 0
        return markdown#headers#CurrentHeader(search_from[1])
    endif

    while p_lnum != 0
        call cursor(p_lnum, 1)
        let a_lnum = markdown#headers#CurrentHeaderParent()
        if a_lnum != 0
            let p_lnum = a_lnum
        else
            call cursor(origin_pos[1], origin_pos[2])
            return p_lnum
        endif
    endwhile
    call cursor(origin_pos[1], origin_pos[2])
endfunction

function! markdown#headers#CurrentHeaderAncestors(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [0, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    let h_genealogy = []

    let head = markdown#headers#CurrentHeader(search_from[1])
    if head == 0
        return []
    else
        call add(h_genealogy, head)
    endif
    let p_lnum = markdown#headers#CurrentHeaderParent(search_from[1])
    " we don't have a parent, so we are an ancestral
    if p_lnum == 0
        return h_genealogy
    endif

    while p_lnum != 0
        call cursor(p_lnum, 1)
        call add(h_genealogy, p_lnum)
        let a_lnum = markdown#headers#CurrentHeaderParent()
        if a_lnum != 0
            let p_lnum = a_lnum
        else
            break
        endif
    endwhile
    call cursor(origin_pos[1], origin_pos[2])
    return h_genealogy
endfunction

function! markdown#headers#SiblingHeader(direction, ...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [1, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    call cursor(search_from[1], search_from[2])

    let parent_lnum = markdown#headers#CurrentHeaderParent()

    let ch_lnum = markdown#headers#CurrentHeader()

    if a:direction ==# 'b'
        call cursor(ch_lnum, 1)
    endif

    let l = getline(ch_lnum)
    if match(l, '^#') > -1
        let header_level = len(matchstr(l, '#*'))
    elseif match(l, '^-') > -1
        let header_level = 2
    else
        let header_level = 1
    endif

    if header_level == 1
        let arrival_lnum = search('\(^.*\n=\|^#\s\)', a:direction.'nW')
    elseif header_level == 2
        let arrival_lnum = search('\(^.*\n-\|^##\s\)', a:direction.'nW')
    else
        let arrival_lnum = search('^#\{'.header_level.'}', a:direction.'nW')
    endif

    " we might have overshot, check if the parent is still correct
    let arrival_parent_lnum = markdown#headers#CurrentHeaderParent(arrival_lnum)
    if arrival_parent_lnum != parent_lnum
        let arrival_lnum = 0
    endif

    call cursor(origin_pos[1], origin_pos[2])
    return arrival_lnum
endfunction

function! markdown#headers#NextSiblingHeader(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    return markdown#headers#SiblingHeader('', search_from)
endfunction


function! markdown#headers#PrevSiblingHeader(...) abort "{{{1
    if a:0 > 0
        let search_from = a:1
    else
        let search_from = line('.')
    endif
    return markdown#headers#SiblingHeader('b', search_from)
endfunction

function! markdown#headers#FirstChild(...) abort "{{{1
    if a:0 > 0
        let search_from = [1, a:1, 1, 0]
    else
        let search_from = getpos('.')
    endif

    let ch_lnum = markdown#headers#CurrentHeader(search_from[1])
    let l = getline(ch_lnum)

    if match(l, '^#') > -1
        let children_level = len(matchstr(l, '#*')) + 1
    elseif match(getline(line('.')+1), '^-') > -1
        let children_level = 3
    else
        let children_level = 2
    endif

    call cursor(search_from[1], search_from[2])
    let next_lnum = markdown#headers#NextHeader()

    if children_level == 2
        let arrival_lnum = search('\(^.*\n-\|^##\s\)', 'nW')
    else
        let arrival_lnum = search('^#\{'.children_level.'}', 'nW')
    endif

    if arrival_lnum != next_lnum
        let arrival_lnum = 0
    endif
    return arrival_lnum
endfunction

function! markdown#headers#LastChild(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [1, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    call cursor(search_from[1], search_from[2])
    let fc_lnum = markdown#headers#FirstChild()
    if fc_lnum != 0
        call cursor(fc_lnum, 1)

        let n_lnum = markdown#headers#NextSiblingHeader()
        if n_lnum != 0

            while n_lnum
                call cursor(n_lnum, 1)
                let a_lnum = markdown#headers#NextSiblingHeader()
                if a_lnum != 0
                    let n_lnum = a_lnum
                else
                    break
                endif
            endwhile
        else
            let n_lnum = fc_lnum
        endif
    else
        let n_lnum = 0
    endif

    call cursor(origin_pos[1], origin_pos[2])
    return n_lnum
endfunction

function! markdown#headers#NthChild(count, ...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [1, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    let fc_lnum = markdown#headers#FirstChild(search_from[1])
    call cursor(fc_lnum, 1)
    if a:count > 1
        for child in range(a:count-1)
            let arrival_lnum = markdown#headers#NextSiblingHeader()
            if arrival_lnum == 0
                break
            endif
            call cursor(arrival_lnum, 1)
        endfor
    else
        let arrival_lnum = fc_lnum
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return arrival_lnum
endfunction

function! markdown#headers#ID(...) abort "{{{1
    let origin_pos = getpos('.')
    if a:0 > 0
        let search_from = [1, a:1, 1, 0]
    else
        let search_from = origin_pos
    endif

    let cheader_lnum = markdown#headers#CurrentHeader(search_from[1])
    let cheader = getline(cheader_lnum)
    call cursor(origin_pos[1], origin_pos[2])

    return markdown#headers#GetAutomaticID(cheader)
endfunction

" GetAutomaticID(header)
" see http://johnmacfarlane.net/pandoc/README.html#extension-auto_identifiers
function! markdown#headers#GetAutomaticID(header) abort " {{{1
    let header_metadata = matchstr(a:header, '{.*}')
    if header_metadata !=# ''
        let header_id = matchstr(header_metadata, '#[[:alnum:]-]*')[1:]
    endif
    if !exists('header_id') || header_id ==# ''
        let text = substitute(a:header, '\[\(.\{-}\)\]\[.*\]', '\1', '') " remove links
        let text = substitute(text, '\s{.*}', '', '') " remove attributes
        let text = substitute(text, '[!"#\$%\&''()\*+,/:;<=>?@\[\\\]\^`{|}\~]', '', 'g') " remove formatting and punctuation, except -_. (hyphen, underscore, period)
        let text = substitute(text, '.\{-}[[:alpha:]\u20AC-\uFFFF]\@=', '', '') " remove everything before the first letter
        let text = substitute(text, '\s', '-', 'g') " replace spaces with dashes
        let text = tolower(text) " turn lowercase

        if match(text, "[[:alpha:]\u20AC-\uFFFF]") > -1
            let header_id = text
        else
            let header_id = 'section'
        endif
    endif

    return header_id
endfunction

" GetAllIDs()
" get all the header indentifiers and it's position, both specified and automatic generated
function! markdown#headers#GetAllIDs() abort " {{{1
    let header_pos = {}
    " update the location list
    call pandoc#toc#Update()

    let headers = getloclist(0)

    for header in headers
        let header_pos[markdown#headers#GetAutomaticID(header.text)] = header.lnum
    endfor

    return header_pos
endfunction

