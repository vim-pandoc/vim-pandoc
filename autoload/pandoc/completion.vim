" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#completion#Init() abort "{{{1
    " set up defaults:
    if !exists('g:pandoc#completion#bib#mode')
        let g:pandoc#completion#bib#mode = 'fallback'
        " Note: in the future citeproc will be the default.
        "if executable('pandoc-citeproc')
        "    let g:pandoc#completion#bib#mode = 'citeproc'
        "else
        "    let g:pandoc#completion#bib#mode = 'fallback'
        "endif
    endif
    if !exists('g:pandoc#completion#bib#use_preview')
        if g:pandoc#completion#bib#mode ==# 'citeproc'
            let g:pandoc#completion#bib#use_preview = 1
        else
            let g:pandoc#completion#bib#use_preview = 0
        endif
    endif
    "
    " If your images are in the same directory as the markdown file, they are included
    " by default in the completion menu. However, many authors like to keep their
    " images in a directory called 'figures' or 'fig'. The options called
    " 'g:pandoc#completion#figdirtype' and 'g:pandoc#completion#figdirpre' are
    " used to define such image directories
    "
    let s:figdir = ''
    if exists('g:pandoc#completion#figdirtype')
        if g:pandoc#completion#figdirtype == 1
            if exists('g:pandoc#completion#figdirpre')
                let s:figdir = g:pandoc#completion#figdirpre
            endif
        elseif g:pandoc#completion#figdirtype == 2
            if exists('g:pandoc#completion#figdirpre')
                let s:figdir = g:pandoc#completion#figdirpre . expand('%:r')
            endif
        endif
    endif
    "
    " set the correct omnifunc completion
    "
    if has('python3')
        setlocal omnifunc=pandoc#completion#Complete
    endif

    if g:pandoc#completion#bib#use_preview == 1
        " handle completeopt, so the preview is enabled
        if stridx(&completeopt, 'preview') > -1
            let b:pandoc_old_cot = &completeopt
            let &completeopt = &completeopt.',preview'
            au! VimPandoc BufEnter,WinEnter <buffer> let &completeopt = b:pandoc_old_cot.'.preview'
            au! VimPandoc BufLeave,WinLeave <buffer> let &completeopt = b:pandoc_old_cot
        endif
        " close the preview window when the completion has been inserted
        au! VimPandoc CompleteDone <buffer> pclose
    endif
endfunction

"
" Write a function that fills s:mylist with unused image file paths
"
fun! s:FetchImageNames()
    "
    " Add all image extensions to l:filelist
    "
    let l:filelist = []
    call extend(l:filelist, globpath(s:figdir, '*.png', 1, 1))
    call extend(l:filelist, globpath(s:figdir, '*.jpg', 1, 1))
    call extend(l:filelist, globpath(s:figdir, '*.svg', 1, 1))
    call extend(l:filelist, globpath(s:figdir, '*.gif', 1, 1))
    call extend(l:filelist, globpath(s:figdir, '*.eps', 1, 1))
    "
    for l:file in l:filelist
        if ! search(l:file, 'nw')
            call add(s:mylist, {
                        \ 'icase': 0,
                        \ 'word': l:file,
                        \ 'menu': '  [ins-Figure]',
                        \ })
        endif
    endfor
endfun

"
" Populate s:mylist with labels such as tbl:, eq:, fig: and tbl:
"
fun! s:FetchRefLabels()
    let l:reflist = []
    call execute(
                \ '%s/\v#\zs(eq:|fig:|lst:|sec:|tbl:)(\w|-)+/' .
                \ '\=add(l:reflist, submatch(0))/gn',
                \  'silent!'
                \ )
    "
    " Lets add the list items to s:mylist
    "
    for l:item in l:reflist
        if l:item[0:3] ==# 'fig:'
            let l:menu = '  [Figure]'
        elseif l:item[0:2] ==# 'eq:'
            let l:menu = '  [Equation]'
        elseif l:item[0:3] ==# 'tbl:'
            let l:menu = '  [Table]'
        elseif l:item[0:3] ==# 'lst:'
            let l:menu = '  [Listing]'
        elseif l:item[0:3] ==# 'sec:'
            let l:menu = '  [Section]'
        else
            let l:menu = '  [Unknown]'
        endif
        call add(s:mylist, {
                    \ 'icase': 1,
                    \ 'word': l:item,
                    \ 'menu': l:menu,
                    \ })
    endfor
endfun

"
" Putting it all together
"
fun! s:PopulatePandoc()
    "
    " This is the main function that populates the omni-completion menu
    "
    " Save the cursor position
    "
    let l:save_cursor = getcurpos()
    "
    let s:mylist = []
    "
    " Populate s:mylist with names (relative path) of image files
    "
    call s:FetchImageNames()
    "
    " Add to s:mylist ref labels for figures, tables, equations etc.
    "
    call s:FetchRefLabels()
    "
    " Make a new list where first letter of some words in s:mylist is upper
    " case. This is useful for cases where [@Fig:somefigname] like references
    " are inserted in the markdown file, e.g., at the beginning of a sentence.
    "
    let s:mycaplist = deepcopy(s:mylist)
    for l:item in s:mycaplist
        "
        " l:item is a reference (not copy) to each dictionary in s:mycaplist
        "
        let l:word = l:item['word']
        let l:menu = l:item['menu']
        if l:menu ==# '  [ins-Figure]'
            continue
        endif
        let l:item['word'] = toupper(l:word[0]) . l:word[1:]
    endfor
    "
    " Restore the cursor position
    "
    call setpos('.', l:save_cursor)
endfun

function! pandoc#completion#Complete(findstart, base) abort "{{{1
    if has('python3')
        if index(g:pandoc#modules#enabled, 'bibliographies') >= 0
            if a:findstart
                "
                " Populate the s:mylist and s:mycaplist with plausible
                " completion candidates
                "
                call s:PopulatePandoc()
                "
                let l:line = getline('.')
                if l:line[:col('.')-1] =~# '@'
                    let l:pos = searchpos('@', 'Wncb')
                    if l:pos != [0,0]
                        return l:pos[1]
                    endif
                else
                    "
                    " This for the images to be inserted into the markdown
                    " file. i_CTRL-X_CTRL-O is required for this
                    "
                    let start = col('.') - 1
                    while start > 0 && (
                                \    line[start - 1] =~ '\a'
                                \ || line[start - 1] =~ '-'
                                \ || line[start - 1] =~ ':'
                                \ || line[start - 1] =~ '\d')
                        let start -= 1
                    endwhile
                    return start
                endif
            else
                "
                " First citation entries in completion menu
                "
                let suggestions = pandoc#bibliographies#GetSuggestions(a:base)
                "
                " Then include labels for fig:, eq:, lst: etc, and also names
                " of images to be inserted in markdown file
                "
                let l:finallist = s:mylist
                if match(a:base[0], '\u') != -1
                    let l:finallist = s:mycaplist
                endif
                for m in l:finallist
                    if m['word'] =~ '^' . a:base
                        call add(suggestions, m)
                    endif
                endfor
                return suggestions
            endif
        endif
    endif
    return -3
endfunction
