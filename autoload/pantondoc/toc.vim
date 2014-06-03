function! pantondoc#toc#Init()
    command! -buffer TOC call pantondoc#toc#Show()
endfunction

" show a table of contents using the quickfix window.
" based on plasticboy/vim-markdown implementation by cirosantilli
function! pantondoc#toc#Show()
    let bufname=expand("%")

    " prepare the location-list buffer
    call pantondoc#toc#Update()

    if g:pandoc#toc#position == "right"
	let toc_pos = "vertical"
    elseif g:pandoc#toc#position == "left"
	let toc_pos = "topleft vertical"
    elseif g:pandoc#toc#position == "top"
	let toc_pos = "topleft"
    elseif g:pandoc#toc#position == "bottom"
	let toc_pos = "botright"
    else
	let toc_pos == "vertical"
    endif
    exe toc_pos . " lopen"
   
    call pantondoc#toc#ReDisplay(bufname)
    " move to the top
    normal! gg
endfunction

function! pantondoc#toc#Update()
    try 
        silent lvimgrep /\(^\S.*\(\n[=-]\+\)\@=\|^#\+\|\%^%\)/ %
    catch /E480/
	return
    endtry
endfunction

function! pantondoc#toc#ReDisplay(bufname)
    let &winwidth=(&columns/3)
    execute "setlocal statusline=pantondoc#TOC:".escape(a:bufname, ' ')

    " change the contents of the location-list buffer
    set modifiable
    silent %s/\v^([^|]*\|){2,2} #//
    for l in range(1, line("$"))
	" this is the location-list data for the current item
	let d = getloclist(0)[l-1]
	" titleblock
	if match(d.text, "^%") > -1
	    let l:level = 0
	" atx headers
	elseif match(d.text, "^#") > -1
	    let l:level = len(matchstr(d.text, '#*', 'g'))-1
	    let d.text = '· '.d.text[l:level+2:]
	" setex headers
	else
	    let l:next_line = getbufline(bufname(d.bufnr), d.lnum+1)
	    if match(l:next_line, "=") > -1
		let l:level = 0
	    elseif match(l:next_line, "-") > -1
		let l:level = 1
	    endif
	    let d.text = '· '.d.text
	endif
	call setline(l, repeat(' ', 2*l:level-1). d.text)
    endfor
    set nomodified
    set nomodifiable

    " re-highlight the quickfix buffer
    syn match pandocTocHeader /^.*\n/
    syn match pandocTocBullet /·/ contained containedin=pandocTocHeader
    syn match pandocTocTitle /^%.*\n/
    hi link pandocTocHeader Title
    hi link pandocTocTitle Directory
    hi link pandocTocBullet Delimiter

    setlocal linebreak

    map <buffer> q <esc>:lclose<CR>
endfunction
