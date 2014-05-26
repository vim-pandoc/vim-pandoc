" vim: set fdm=marker :

function! markdown#headers#NextHeader() "{{{1
    let origin_pos = getpos(".")
    call cursor(origin_pos[1], 2)
    let h_lnum = search('\(^.*\n[-=]\|^#\)','nW')
    if h_lnum == 0 
	if match(getline("."), "^#") >= 0 || match(getline(line(".")+1), "^[-=]") >= 0
	    let h_lnum = line(".")
	endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return h_lnum
endfunction

function! markdown#headers#PrevHeader() "{{{1
    let origin_pos = getpos(".")
    call cursor(origin_pos[1], 1)
    let h_lnum = search('\(^.*\n[-=]\|^#\)', 'bnW')
    if h_lnum == 0 
	if match(getline("."), "^#") >= 0 || match(getline(line(".")+1), "^[-=]") >= 0
	    let h_lnum = line(".")
	endif
    endif
    call cursor(origin_pos[1], origin_pos[2])
    return h_lnum
endfunction

function! markdown#headers#CurrentHeader() "{{{1
    " same as PrevHeader(), except don't search if we are already at a header 
    if match(getline("."), "^#") < 0 && match(getline(line(".")+1), "^[-=]") < 0
	return markdown#headers#PrevHeader()
    else
	return line(".")
    endif
endfunction

function! markdown#headers#CurrentHeaderParent() "{{{1
    let pos = getpos(".")

    let ch_lnum = markdown#headers#CurrentHeader()

    call cursor(ch_lnum, 1)
    let l = getline(".")

    if match(l, "^#") > -1
        let parent_level = len(matchstr(l, '#*')) - 1
    elseif match(getline(line(".")+1), '^-') > -1
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
	
	let arrival_lnum = search('\('.setext_regex.'\|^#\{1,'.parent_level.'}\s\)', "bnW")
    else
	let arrival_lnum = 0
    endif
    call cursor(pos[1], pos[2])
    return arrival_lnum
endfunction

function! markdown#headers#CurrentHeaderAncestral() "{{{1
    let pos = getpos(".")
    let p_lnum = markdown#headers#CurrentHeaderParent()
    " we don't have a parent, so we are an ancestral
    if p_lnum == 0
	call cursor(pos[1], pos[2])
	return markdown#headers#CurrentHeader()
    endif

    while p_lnum != 0
	call cursor(p_lnum, 1)
	let a_lnum = markdown#headers#CurrentHeaderParent()
	if a_lnum != 0
	   let p_lnum = a_lnum
       else
	   call cursor(pos[1], pos[2])
	   return p_lnum
       endif
    endwhile
    call cursor(pos[1], pos[2])
endfunction

function! markdown#headers#CurrentHeaderAncestors() "{{{1
    let pos = getpos(".")
    
    let h_genealogy = []
    call add(h_genealogy, markdown#headers#CurrentHeader())
    let p_lnum = markdown#headers#CurrentHeaderParent()
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
    call cursor(pos[1], pos[2])
    return h_genealogy
endfunction

function! markdown#headers#SiblingHeader(direction) "{{{1
    let origin_pos = getpos(".")
    
    let parent_lnum = markdown#headers#CurrentHeaderParent()

    let ch_lnum = markdown#headers#CurrentHeader()
    let l = getline(ch_lnum)

    if match(l, "^#") > -1
        let header_level = len(matchstr(l, '#*'))
    elseif match(l, '^-') > -1
	let header_level = 2
    else
	let header_level = 1
    endif

    if a:direction == 'b'
	call cursor(ch_lnum, 1)
    endif

    if header_level == 1
	let arrival_lnum = search('\(^.*\n=\|^#\s\)', a:direction.'nW')
    elseif header_level == 2
	let arrival_lnum = search('\(^.*\n-\|^##\s\)', a:direction.'nW')
    else
	let arrival_lnum = search('^#\{'.header_level.'}', a:direction.'nW')
    endif

    " we might have overshot, check if the parent is still correct 
    call cursor(arrival_lnum, 1)
    let arrival_parent_lnum = markdown#headers#CurrentHeaderParent()
    if arrival_parent_lnum != parent_lnum
	let arrival_lnum = 0
    endif

    call cursor(origin_pos[1], origin_pos[2])
    return arrival_lnum
endfunction

function! markdown#headers#NextSiblingHeader() "{{{1
    return markdown#headers#SiblingHeader('')
endfunction

function! markdown#headers#PrevSiblingHeader() "{{{1
    return markdown#headers#SiblingHeader('b')
endfunction

function! markdown#headers#FirstChild() "{{{1
    let ch_lnum = markdown#headers#CurrentHeader()
    let l = getline(ch_lnum)

    if match(l, "^#") > -1
        let children_level = len(matchstr(l, '#*')) + 1
    elseif match(getline(line(".")+1), '^-') > -1
	let children_level = 3
    else
	let children_level = 2
    endif

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

function! markdown#headers#LastChild() "{{{1
    let origin_pos = getpos(".")
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

function! markdown#headers#NthChild(count) "{{{1
    let origin_pos = getpos(".")
    let fc_lnum = markdown#headers#FirstChild()
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

