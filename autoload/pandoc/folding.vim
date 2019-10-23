" vim: set fdm=marker et ts=4 sw=4 sts=4:
"
" Init: {{{1
function! pandoc#folding#Init() abort
    " set up defaults {{{2
    "  Show foldcolum {{{3
    if !exists('g:pandoc#folding#fdc')
        let g:pandoc#folding#fdc = 1
    endif
    " Initial foldlevel {{{3
    if !exists('g:pandoc#folding#level')
        let g:pandoc#folding#level = &foldlevel
    endif
    " How to decide fold levels {{{3
    " 'syntax': Use syntax
    " 'relative': Count how many parents the header has
    if !exists('g:pandoc#folding#mode')
        let g:pandoc#folding#mode = 'syntax'
    endif
    " Fold the YAML frontmatter {{{3
    if !exists('g:pandoc#folding#fold_yaml')
        let g:pandoc#folding#fold_yaml = 0
    endif
    " What <div> classes to fold {{{3
    if !exists('g:pandoc#folding#fold_div_classes')
        let g:pandoc#folding#fold_div_classes = ['notes']
    endif
    "}}}3
    " Fold vim markers (see help fold-marker) {{{3
    if !exists('g:pandoc#folding#fold_vim_markers')
        let g:pandoc#folding#fold_vim_markers = 1
    endif
    " Only fold vim markers inside comments {{{3
    if !exists('g:pandoc#folding#vim_markers_in_comments_only')
        let g:pandoc#folding#vim_markers_in_comments_only = 1
    endif
    " Fold fenced codeblocks? {{{3
    if !exists('g:pandoc#folding#fold_fenced_codeblocks')
        let g:pandoc#folding#fold_fenced_codeblocks = 0
    endif
    " Use custom foldtext? {{{3
    if !exists('g:pandoc#folding#use_foldtext')
        let g:pandoc#folding#use_foldtext = 1
    endif
    " Use fastfolds? {{{3
    if !exists('g:pandoc#folding#fastfolds')
        let g:pandoc#folding#fastfolds = 0
    endif
    " Use basic folding fot this buffer? {{{3
    if !exists('b:pandoc_folding_basic')
        let b:pandoc_folding_basic = 0
    endif

    " set up folding {{{2
    exe 'setlocal foldlevel='.g:pandoc#folding#level
    setlocal foldmethod=expr
    " might help with slowness while typing due to syntax checks
    if g:pandoc#folding#fastfolds
        augroup EnableFastFolds
            au!
            autocmd InsertEnter <buffer> setlocal foldmethod=manual
            autocmd InsertLeave <buffer> setlocal foldmethod=expr
        augroup end
    endif
    setlocal foldexpr=pandoc#folding#FoldExpr()
    if g:pandoc#folding#use_foldtext
        setlocal foldtext=pandoc#folding#FoldText()
    endif
    if g:pandoc#folding#fdc > 0
        let &l:foldcolumn = g:pandoc#folding#fdc
    endif
    "}}}
    " set up a command to change the folding mode on demand {{{2
    command! -buffer -nargs=1 -complete=custom,pandoc#folding#ModeCmdComplete PandocFolding call pandoc#folding#ModeCmd(<f-args>) 
    " }}}2
endfunction

function! pandoc#folding#Disable() abort
    setlocal foldcolumn&
    setlocal foldlevel&
    setlocal foldexpr&
    if g:pandoc#folding#fastfolds
        au! VimPandoc InsertEnter
        au! VimPandoc InsertLeave
    endif
    if exists(':PandocFolding')
        delcommand PandocFolding
    endif
    setlocal foldmethod& " here because before deleting the autocmds, it might interfere
endfunction

" Change folding mode on demand {{{1
function! pandoc#folding#ModeCmdComplete(...) abort
    return "syntax\nrelative\nstacked\nnone"
endfunction
function! pandoc#folding#ModeCmd(mode) abort
    if a:mode ==# 'none'
        setlocal foldmethod=manual
        normal! zE
    else
        exe 'let g:pandoc#folding#mode = "'.a:mode.'"'
        setlocal foldmethod=expr
        normal! zx
    endif
endfunction

" Main foldexpr function, includes support for common stuff. {{{1
" Delegates to filetype specific functions.
function! pandoc#folding#FoldExpr() abort
    " with multiple splits in the same buffer, the folding code can be called
    " way too many times too often, so it's best to disable it to keep good
    " performance. Only enable when using the built-in method of improving
    " performance of folds.
    if g:pandoc#folding#fastfolds == 1
        if count(map(range(1, winnr('$')), 'bufname(winbufnr(v:val))'), bufname('')) > 1
            return
        endif
    endif

    let vline = getline(v:lnum)
    " fold YAML headers
    if g:pandoc#folding#fold_yaml == 1
        if vline =~# '\(^---$\|^...$\)' && synIDattr(synID(v:lnum , 1, 1), 'name') =~? '\(delimiter\|yamldocumentstart\)'
            if vline =~# '^---$' && v:lnum == 1
                return '>1'
            elseif synIDattr(synID(v:lnum - 1, 1, 1), 'name') ==# 'yamlkey'
                return '<1'
            elseif synIDattr(synID(v:lnum - 1, 1, 1), 'name') ==# 'pandocYAMLHeader'
                return '<1'
            elseif synIDattr(synID(v:lnum - 1, 1, 1), 'name') ==# 'yamlBlockMappingKey'
                return '<1'
            else
                return '='
            endif
        endif
    endif

    " fold divs for special classes
    let div_classes_regex = '('.join(g:pandoc#folding#fold_div_classes, '|').')'
    if vline =~? '<div class=.'.div_classes_regex
        return 'a1'
    " the `endfold` attribute must be set, otherwise we can remove folds
    " incorrectly (see issue #32)
    " pandoc ignores this attribute, so this is safe.
    elseif vline =~? '</div endfold>'
        return 's1'
    endif

    " fold markers?
    if g:pandoc#folding#fold_vim_markers == 1
        if vline =~# '[{}]\{3}'
            if g:pandoc#folding#vim_markers_in_comments_only == 1
                let mark_head = '<!--.*'
            else
                let mark_head = ''
            endif
            if vline =~# mark_head.'{\{3}'
                let level = matchstr(vline, '\({\{3}\)\@<=\d')
                if level !=# ''
                    return '>'.level
                else
                    return 'a1'
                endif
            endif
            if vline =~# mark_head.'}\{3}'
                let level = matchstr(vline, '\(}\{3}\)\@<=\d')
                if level !=# ''
                    return '<'.level
                else
                    return 's1'
                endif
            endif
        endif
    endif

    " Delegate to filetype specific functions
    if &filetype =~# 'markdown' || &filetype ==# 'pandoc' || &filetype ==# 'rmd'
        " vim-pandoc-syntax sets this variable, so we can check if we can use
        " syntax assistance in our foldexpr function
        if exists('g:vim_pandoc_syntax_exists') && b:pandoc_folding_basic != 1
            return pandoc#folding#MarkdownLevelSA()
        " otherwise, we use a simple, but less featureful foldexpr
        else
            return pandoc#folding#MarkdownLevelBasic()
        endif
    elseif &filetype ==# 'textile'
        return pandoc#folding#TextileLevel()
    endif

endfunction

" Main foldtext function. Like ...FoldExpr() {{{1
function! pandoc#folding#FoldText() abort
    " first line of the fold
    let f_line = getline(v:foldstart)
    " second line of the fold
    let n_line = getline(v:foldstart + 1)
    " count of lines in the fold
    let line_count = v:foldend - v:foldstart + 1
    let line_count_text = ' / ' . line_count . ' lines / '

    if n_line =~? 'title\s*:'
        return v:folddashes . ' [y] ' . matchstr(n_line, '\(title\s*:\s*\)\@<=\S.*') . line_count_text
    endif
    if f_line =~? 'fold-begin'
        return v:folddashes . ' [c] ' . matchstr(f_line, '\(<!-- \)\@<=.*\( fold-begin -->\)\@=') . line_count_text
    endif
    if f_line =~# '<!-- .*{{{'
        return v:folddashes . ' [m] ' . matchstr(f_line, '\(<!-- \)\@<=.*\( {{{.* -->\)\@=') . line_count_text
    endif
    if f_line =~? '<div class='
        return v:folddashes . ' ['. matchstr(f_line, "\\(class=[\"']\\)\\@<=.*[\"']\\@="). '] ' . n_line[:30] . '...' . line_count_text
    endif
    if &filetype =~# 'markdown' || &filetype ==# 'pandoc' || &filetype ==# 'rmd'
        return pandoc#folding#MarkdownFoldText() . line_count_text
    elseif &filetype ==# 'textile'
        return pandoc#folding#TextileFoldText() . line_count_text
    endif
endfunction

" Markdown: {{{1
"
" Originally taken from http://stackoverflow.com/questions/3828606
"
" Syntax assisted (SA) foldexpr {{{2
function! pandoc#folding#MarkdownLevelSA() abort
    let vline = getline(v:lnum)
    let vline1 = getline(v:lnum + 1)
    if vline =~# '^#\{1,6}[^.]'
        if synIDattr(synID(v:lnum, 1, 1), 'name') =~# '^pandoc\(DelimitedCodeBlock$\)\@!'
            if g:pandoc#folding#mode ==# 'relative'
                return '>'. len(markdown#headers#CurrentHeaderAncestors(v:lnum))
            elseif g:pandoc#folding#mode ==# 'stacked'
                return '>1'
            else
                return '>'. len(matchstr(vline, '^#\{1,6}'))
            endif
        endif
    elseif vline =~# '^[^-=].\+$' && vline1 =~# '^=\+$'
        if synIDattr(synID(v:lnum, 1, 1), 'name') =~# '^pandoc\(DelimitedCodeBlock$\)\@!'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), 'name') ==# 'pandocSetexHeader'
            return '>1'
        endif
    elseif vline =~# '^[^-=].\+$' && vline1 =~# '^-\+$'
        if synIDattr(synID(v:lnum, 1, 1), 'name') =~# '^pandoc\(DelimitedCodeBlock$\)\@!'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), 'name') ==# 'pandocSetexHeader'
            if g:pandoc#folding#mode ==# 'relative'
                return  '>'. len(markdown#headers#CurrentHeaderAncestors(v:lnum))
            elseif g:pandoc#folding#mode ==# 'stacked'
                return '>1'
            else
                return '>2'
            endif
        endif
    elseif vline =~? '^<!--.*fold-begin -->'
        return 'a1'
    elseif vline =~? '^<!--.*fold-end -->'
        return 's1'
    elseif vline =~# '^\s*[`~]\{3}'
        if g:pandoc#folding#fold_fenced_codeblocks == 1
            let synId = synIDattr(synID(v:lnum, match(vline, '[`~]') + 1, 1), 'name')
            if synId ==# 'pandocDelimitedCodeBlockStart'
                return 'a1'
            elseif synId =~# '^pandoc\(DelimitedCodeBlock$\)\@!'
                return 's1'
            endif
        endif
    endif
    return '='
endfunction

" Basic foldexpr {{{2
function! pandoc#folding#MarkdownLevelBasic() abort
    if getline(v:lnum) =~# '^#\{1,6}' && getline(v:lnum-1) =~# '^\s*$'
        if g:pandoc#folding#mode ==# 'stacked'
            return '>1'
        else
            return '>'. len(matchstr(getline(v:lnum), '^#\{1,6}'))
        endif
    elseif getline(v:lnum) =~# '^[^-=].\+$' && getline(v:lnum+1) =~# '^=\+$'
        return '>1'
    elseif getline(v:lnum) =~# '^[^-=].\+$' && getline(v:lnum+1) =~# '^-\+$'
        if g:pandoc#folding#mode ==# 'stacked'
            return '>1'
        else
            return '>2'
        endif
    elseif getline(v:lnum) =~? '^<!--.*fold-begin -->'
        return 'a1'
    elseif getline(v:lnum) =~? '^<!--.*fold-end -->'
        return 's1'
    endif
    return '='
endfunction

" Markdown foldtext {{{2
function! pandoc#folding#MarkdownFoldText() abort
    let c_line = getline(v:foldstart)
    let atx_title = match(c_line, '#') > -1
    if atx_title
        return '- '. c_line
    else
        if match(getline(v:foldstart+1), '=') != -1
            let level_mark = '#'
        else
            let level_mark = '##'
        endif
        return '- '. level_mark. ' '.c_line
    endif
endfunction

" Textile: {{{1
"
function! pandoc#folding#TextileLevel() abort
    let vline = getline(v:lnum)
    if vline =~# '^h[1-6]\.'
        if g:pandoc#folding#mode ==# 'stacked'
            return '>'
        else
            return '>' . matchstr(getline(v:lnum), 'h\@1<=[1-6]\.\=')
        endif
    elseif vline =~? '^.. .*fold-begin'
        return 'a1'
    elseif vline =~? '^.. .*fold end'
        return 's1'
    endif
    return '='
endfunction

function! pandoc#folding#TextileFoldText() abort
    return '- '. substitute(v:folddashes, '-', '#', 'g'). ' ' . matchstr(getline(v:foldstart), '\(h[1-6]\. \)\@4<=.*')
endfunction

