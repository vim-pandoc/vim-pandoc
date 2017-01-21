function! pandoc#indent#Init()
    runtime! indent/tex.vim
    setlocal indentexpr=pandoc#indent#GetIndent()
endfunction

function! pandoc#indent#GetIndent()
    let l:stack = synstack(line('.'), col('.'))
    if len(l:stack) > 0 && synIDattr(l:stack[0], 'name') == 'pandocLaTeXRegion'
	return GetTeXIndent()
    else
	return -1
    endif
endfunction
