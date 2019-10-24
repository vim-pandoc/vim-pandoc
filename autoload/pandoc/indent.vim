function! pandoc#indent#Init() abort
    runtime! indent/tex.vim
    if exists('#LatexBox_Completion#CompleteDone')
	au! LatexBox_Completion CompleteDone
    endif
    setlocal indentexpr=pandoc#indent#GetIndent()
endfunction

function! pandoc#indent#GetIndent() abort
    let l:stack = synstack(line('.'), col('.'))
    if len(l:stack) > 0 && synIDattr(l:stack[0], 'name') ==# 'pandocLaTeXRegion'
	return GetTeXIndent()
    else
	return -1
    endif
endfunction
