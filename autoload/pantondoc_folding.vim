" sets up folding according to filetype 
function! pantondoc_folding#InitFolding()
	setlocal foldmethod=expr
	if &ft == "markdown" 
		setlocal foldexpr=pantondoc_folding#MarkdownLevel()
	" for some reason, || didn't work
	elseif &ft == "pandoc"
		setlocal foldexpr=pantondoc_folding#MarkdownLevel()
	elseif &ft == "textile"
		setlocal foldexpr=pantondoc_folding#TextileLevel()
	endif
endfunction

" Taken from
" http://stackoverflow.com/questions/3828606/vim-markdown-folding/4677454#4677454
"
function! pantondoc_folding#MarkdownLevel()
    if getline(v:lnum) =~ '^# .*$'
        return ">1"
	elseif getline(v:lnum) =~ '^## .*$'
        return ">2"
	elseif getline(v:lnum) =~ '^### .*$'
        return ">3"
	elseif getline(v:lnum) =~ '^#### .*$'
        return ">4"
	elseif getline(v:lnum) =~ '^##### .*$'
        return ">5"
	elseif getline(v:lnum) =~ '^###### .*$'
        return ">6"
	elseif getline(v:lnum) =~ '^[^-=].\+$' && getline(v:lnum+1) =~ '^=\+$'
		return ">1"
	elseif getline(v:lnum) =~ '^[^-=].\+$' && getline(v:lnum+1) =~ '^-\+$'
		return ">2"
	" support for arbitrary folds through special comments
	elseif getline(v:lnum) =~ '^<!--.*fold-begin -->'
		return "a1"
	elseif getline(v:lnum) =~ '^<!--.*fold-end -->'
		return "s1"
	else
		return "="
	endif
endfunction

function! pantondoc_folding#TextileLevel()
	if getline(v:lnum) =~ '^h1\..*$'
		return ">1"
	elseif getline(v:lnum) =~ '^h2\..*$'
		return ">2"
	elseif getline(v:lnum) =~ '^h3\..*$'
		return ">3"
	elseif getline(v:lnum) =~ '^h4\..*$'
		return ">4"
	elseif getline(v:lnum) =~ '^h5\..*$'
		return ">5"
	elseif getline(v:lnum) =~ '^h6\..*$'
		return ">6"
	elseif getline(v:lnum) =~ '^.. .*fold-begin'
		return "a1"
	elseif getline(v:lnum) =~ '^.. .*fold end'
		return "s1"
	else
		return "="
	endif
endfunction
