" vim: foldmethod=marker :
"
" Init: {{{1
function! pantondoc#folding#Init()
    setlocal foldmethod=expr
    setlocal foldexpr=pantondoc#folding#FoldExpr()
    setlocal foldtext=pantondoc#folding#FoldText()
endfunction

" Main foldexpr function, includes support for common stuff. {{{1 
" Delegates to filetype specific functions.
function! pantondoc#folding#FoldExpr()
    " fold YAML headers
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
    " Delegate to filetype specific functions
    if &ft == "markdown" || &ft == "pandoc"
	" vim-pandoc-syntax sets this variable, so we can check if we can use
	" syntax assistance in our foldexpr function
	if exists("g:vim_pandoc_syntax_exists")
	    return pantondoc#folding#MarkdownLevelSA()
	" otherwise, we use a simple, but less featureful foldexpr
	else
	    return pantondoc#folding#MarkdownLevelBasic()
	endif
    elseif &ft == "textile"
	return pantondoc#folding#TextileLevel()
    endif

endfunction

" Main foldtext function. Like ...FoldExpr() {{{1
function! pantondoc#folding#FoldText()
    let line_count = v:foldend - v:foldstart + 1
    let line_count_text = " / " . line_count . " lines / "
    if getline(v:foldstart+1) =~ "title:"
	return v:folddashes . " [yaml] " . substitute(getline(v:foldstart+1), "title: ", "", "") . line_count_text
    endif
    if getline(v:foldstart) =~ "fold-begin"
	return v:folddashes . " [custom] " . matchstr(getline(v:foldstart), '\(<!-- \)\@<=.*\( fold-begin -->\)\@=') . line_count_text
    endif
    return v:folddashes . " ".  getline(v:foldstart) . line_count_text
    " TODO:
"    if &ft == "markdown" || &ft == "pandoc"
"	return pantondoc#folding#MarkdownFoldText()
"    elseif &ft == "textile"
"	return pantondoc#folding#TextileFoldText()
"    endif
endfunction

" Markdown: {{{1
"
" Originally taken from http://stackoverflow.com/questions/3828606
"
" Syntax assisted (SA) foldexpr {{{2
function! pantondoc#folding#MarkdownLevelSA()
    " never fold within delimited codeblocks
    if synIDattr(synID(v:lnum + 1, 1, 1), "name") != "pandocDelimitedCodeBlock"
	" atx and setex headers
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
	elseif synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
	    if getline(v:lnum) =~ '^[^-=].\+$' && getline(v:lnum+1) =~ '^=\+$'
		return ">1"
	    elseif getline(v:lnum) =~ '^[^-=].\+$' && getline(v:lnum+1) =~ '^-\+$'
		return ">2"
	    endif
	" support for arbitrary folds through special comments
	elseif getline(v:lnum) =~ '^<!--.*fold-begin -->'
	    return "a1"
	elseif getline(v:lnum) =~ '^<!--.*fold-end -->'
	    return "s1"
	endif
    endif
    return "="
endfunction

" Basic foldexpr {{{2
function! pantondoc#folding#MarkdownLevelBasic()
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
    elseif getline(v:lnum) =~ '^<!--.*fold-begin -->'
	return "a1"
    elseif getline(v:lnum) =~ '^<!--.*fold-end -->'
	return "s1"
    endif
    return "="
endfunction

" Markdown foldtext {{{2
function! pantondoc#folding#MarkdownFoldText()
endfunction

" Textile: {{{1
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
    endif
    return "="
endfunction

function! pantondoc#folding#TextileFoldText()
endfunction

