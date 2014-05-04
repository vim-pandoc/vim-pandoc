function! pantondoc#toc#Init()
    command! -buffer TOC call pantondoc#toc#Show()
endfunction

" show a table of contents using the quickfix window.
" based on plasticboy/vim-markdown implementation by cirosantilli
function! pantondoc#toc#Show()
    let bufname=expand("%")

    " prepare the quickfix buffer
    silent vimgrep /\(.*\(\n[=-]\+\)\@=\|^#\+ \|\%^%\)/ %
    vertical copen
    let &winwidth=(&columns/3)
    execute "setlocal statusline=pantondoc#TOC:".bufname
    
    " change the contents of the quickfix buffer
    set modifiable
    %s/\v^([^|]*\|){2,2} #//
    for l in range(1, line("$"))
	" this is the quickfix data for the current item
	let d = getqflist()[l-1]
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

    map <buffer> q <esc>:cclose<CR>
    " move to the top
    normal! gg
endfunction
