" sets up folding according to filetype 
function! pantondoc#folding#Init()
    setlocal foldmethod=expr
    if &ft == "markdown" || &ft == "pandoc"
	if exists("g:vim_pandoc_syntax_exists")
	    setlocal foldexpr=pantondoc#folding#MarkdownLevelSA()
	else
	    setlocal foldexpr=pantondoc#folding#MarkdownLevelBasic()
	endif
    elseif &ft == "textile"
	setlocal foldexpr=pantondoc#folding#TextileLevel()
    endif
endfunction

" Markdown:
"
" Originally taken from http://stackoverflow.com/questions/3828606
"
" Syntax assisted foldexpr
function! pantondoc#folding#MarkdownLevelSA()
    if g:pantondoc_folding_fold_yaml == 1
	if getline(v:lnum) =~ '^---$' && synIDattr(synID(v:lnum , 1, 1), "name") == "Delimiter"
	    if v:lnum == 1
		return ">1"
	    elseif synIDattr(synID(v:lnum - 1, 1, 1), "name") == "yamlkey" 
		return "<1"
	    elseif synIDattr(synID(v:lnum - 1, 1, 1), "name") == "pandocYAMLHeader" 
		return "<1"
	    else 
		return "="
	    endif
	endif
    endif
    if getline(v:lnum) =~ '^# .*$'
	if synIDattr(synID(v:lnum + 1, 1, 1), "name") != "pandocDelimitedCodeBlock"
	    return ">1"
	else
	    return "="
	endif
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
	if synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
	    return ">1"
	endif
    elseif getline(v:lnum) =~ '^[^-=].\+$' && getline(v:lnum+1) =~ '^-\+$'
	if synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
	    return ">2"
	else
	    return "="
	endif
    " support for arbitrary folds through special comments
    elseif getline(v:lnum) =~ '^<!--.*fold-begin -->'
	return "a1"
    elseif getline(v:lnum) =~ '^<!--.*fold-end -->'
	return "s1"
    else
	return "="
    endif
endfunction

function! pantondoc#folding#MarkdownLevelBasic()
    " temporary
    call pantondoc#folding#MarkdownLevelSA()
endfunction

" Textile: 
"
function! pantondoc#folding#TextileLevel()
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
    elseif getline(v:lnum) =~ '^---$' && synIDattr(synID(v:lnum , 1, 1), "name") == "Delimiter"
	if v:lnum == 1
	    return ">1"
	else
	    return "<1"
	endif
    else
	return "="
    endif
endfunction
