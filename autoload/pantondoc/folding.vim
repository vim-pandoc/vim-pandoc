" vim: foldmethod=marker :
"
" Init: {{{1
function! pantondoc#folding#Init()
    if !exists("b:vim_pantondoc_use_basic_folding")
        let b:vim_pantondoc_use_basic_folding = 0
    endif
    setlocal foldmethod=expr
    " might help with slowness while typing due to syntax checks
    augroup EnableFastFolds
	au!
	autocmd InsertEnter <buffer> setlocal foldmethod=manual
	autocmd InsertLeave <buffer> setlocal foldmethod=expr
    augroup end   
    setlocal foldexpr=pantondoc#folding#FoldExpr()
    setlocal foldtext=pantondoc#folding#FoldText()
endfunction

" Main foldexpr function, includes support for common stuff. {{{1 
" Delegates to filetype specific functions.
function! pantondoc#folding#FoldExpr()

    let vline = getline(v:lnum)
    " fold YAML headers
    if g:pantondoc_folding_fold_yaml == 1
	if vline =~ '\(^---$\|^...$\)' && synIDattr(synID(v:lnum , 1, 1), "name") == "Delimiter"
	    if vline =~ '^---$' && v:lnum == 1
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

    " fold divs for special classes
    if vline =~ '<div class='
	return "a1"
    elseif vline =~ '</div>'
	return "s1"
    endif

    " Delegate to filetype specific functions
    if &ft == "markdown" || &ft == "pandoc"
	" vim-pandoc-syntax sets this variable, so we can check if we can use
	" syntax assistance in our foldexpr function
	if exists("g:vim_pandoc_syntax_exists") && b:vim_pantondoc_use_basic_folding != 1
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
    " first line of the fold
    let f_line = getline(v:foldstart)
    " second line of the fold
    let n_line = getline(v:foldstart + 1)
    " count of lines in the fold
    let line_count = v:foldend - v:foldstart + 1
    let line_count_text = " / " . line_count . " lines / "

    if n_line =~ 'title\s*:'
	return v:folddashes . " [yaml] " . matchstr(n_line, '\(title\s*:\s*\)\@<=\S.*') . line_count_text
    endif
    if f_line =~ "fold-begin"
	return v:folddashes . " [custom] " . matchstr(f_line, '\(<!-- \)\@<=.*\( fold-begin -->\)\@=') . line_count_text
    endif
    if f_line =~ "<div class="
	return v:folddashes . " [". matchstr(f_line, "\\(class=[\"']\\)\\@<=.*[\"']\\@="). "] " . n_line[:30] . "..." . line_count_text
    endif
    if &ft == "markdown" || &ft == "pandoc"
	return pantondoc#folding#MarkdownFoldText() . line_count_text
    elseif &ft == "textile"
	return pantondoc#folding#TextileFoldText() . line_count_text
    endif
endfunction

" Markdown: {{{1
"
" Originally taken from http://stackoverflow.com/questions/3828606
"
" Syntax assisted (SA) foldexpr {{{2
function! pantondoc#folding#MarkdownLevelSA()
    let vline = getline(v:lnum)
    let vline1 = getline(v:lnum + 1)
    if vline =~ '^#\{1,6}'
        if synIDattr(synID(v:lnum, 1, 1), "name") !~? '\(pandocDelimitedCodeBlock\|comment\)'
            return ">". len(matchstr(vline, '^#\{1,6}'))
        endif
    elseif vline =~ '^[^-=].\+$' && vline1 =~ '^=\+$'
        if synIDattr(synID(v:lnum, 1, 1), "name") !~? '\(pandocDelimitedCodeBlock\|comment\)'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
            return ">1"
        endif
    elseif vline =~ '^[^-=].\+$' && vline1 =~ '^-\+$'
        if synIDattr(synID(v:lnum, 1, 1), "name") !~? '\(pandocDelimitedCodeBlock\|comment\)'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
            return ">2"
        endif
    elseif vline =~ '^<!--.*fold-begin -->'
	return "a1"
    elseif vline =~ '^<!--.*fold-end -->'
	return "s1"
    endif
    return "="
endfunction

" Basic foldexpr {{{2
function! pantondoc#folding#MarkdownLevelBasic()
    if getline(v:lnum) =~ '^#\{1,6}'
	return ">". len(matchstr(getline(v:lnum), '^#\{1,6}'))
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
    return v:folddashes . " # " . matchstr(getline(v:foldstart), '\(#\{1,6} \)\@7<=.*')
endfunction

" Textile: {{{1
"
function! pantondoc#folding#TextileLevel()
    let vline = getline(v:lnum)
    if vline =~ '^h[1-6]\.'
	return ">" . matchstr(getline(v:lnum), 'h\@1<=[1-6]\.\=')
    elseif vline =~ '^.. .*fold-begin'
	return "a1"
    elseif vline =~ '^.. .*fold end'
	return "s1"
    endif
    return "="
endfunction

function! pantondoc#folding#TextileFoldText()
    return v:folddashes . " # " . matchstr(getline(v:foldstart), '\(h[1-6]\. \)\@4<=.*')
endfunction

