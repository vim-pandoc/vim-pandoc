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
    " images in a directory such as 'images' or 'figures'. The options called
    " 'g:pandoc#completion#imgdirtype' and 'g:pandoc#completion#imgdirpre' are
    " used to define such image directories
    "
    let s:imgdir = ''
    if exists('g:pandoc#completion#imgdirtype')
        if g:pandoc#completion#imgdirtype == 1
            if exists('g:pandoc#completion#imgdirpre')
                let s:imgdir = g:pandoc#completion#imgdirpre
            endif
        elseif g:pandoc#completion#imgdirtype == 2
            if exists('g:pandoc#completion#imgdirpre')
                let s:imgdir = g:pandoc#completion#imgdirpre . expand('%:r')
            endif
        endif
    endif
    "
    " User can specify the sources from where reference list consisting of
    " labels such as fig:, lst:, eq: etc. will be populated. Currently two
    " sourses are supported: g:pandoc#completion#refsources = 'buffers' and
    " g:pandoc#completion#refsources = 'pandocfiles'. These correspond to all
    " open buffers ('buffers') and the pandoc files found (recursively) in the
    " current directory ('pandocfiles'), respectively. 'buffers' is the
    " default
    "
    let s:refsources = 'buffers'
    if exists('g:pandoc#completion#refsources')
        let s:refsources = g:pandoc#completion#refsources
    endif
    "
    let l:currArgs = argv()
    execute '%argd'
    if s:refsources ==# 'buffers'
        " do nothing
    elseif s:refsources ==# 'pandocfiles'
        " this will populate the bufferlist and we can then work with bufdo
        " argdo does not work very well with unsaved buffers
        let l:pandocfiles = []
        call extend(l:pandocfiles, glob('**/*.pandoc', 1, 1))
        call extend(l:pandocfiles, glob('**/*.pdk', 1, 1))
        call extend(l:pandocfiles, glob('**/*.pd', 1, 1))
        call extend(l:pandocfiles, glob('**/*.pdc', 1, 1))
        execute 'argadd ' . join(l:pandocfiles)
        if get(g:, 'pandoc#filetypes#pandoc_markdown', 1) == 1
            let l:pandocfiles = []
            call extend(l:pandocfiles, glob('**/*.markdown', 1, 1))
            call extend(l:pandocfiles, glob('**/*.mdown', 1, 1))
            call extend(l:pandocfiles, glob('**/*.mkd', 1, 1))
            call extend(l:pandocfiles, glob('**/*.mkdn', 1, 1))
            call extend(l:pandocfiles, glob('**/*.mkdwn', 1, 1))
            call extend(l:pandocfiles, glob('**/*.md', 1, 1))
            execute 'argadd ' . join(l:pandocfiles)
        endif
    endif
    execute '%argd'
    execute 'argadd ' . join(l:currArgs)
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
fun! s:FetchImageNames() abort
    "
    " Add all image extensions to l:filelist
    "
    let l:filelist = []
    call extend(l:filelist, globpath(s:imgdir, '*.png', 1, 1))
    call extend(l:filelist, globpath(s:imgdir, '*.jpg', 1, 1))
    call extend(l:filelist, globpath(s:imgdir, '*.svg', 1, 1))
    call extend(l:filelist, globpath(s:imgdir, '*.gif', 1, 1))
    call extend(l:filelist, globpath(s:imgdir, '*.eps', 1, 1))
    "
    let l:currBuff = bufnr('%')
    "
    for l:file in l:filelist
        let l:occurrences = 0
        bufdo if &l:filetype ==# 'pandoc' | if search(l:file, 'nw') | let l:occurrences += 1 | endif | endif
        if l:occurrences == 0
            call add(s:mylist, {
                        \ 'icase': 0,
                        \ 'word': l:file,
                        \ 'menu': '  [ins-Figure]',
                        \ })
        endif
    endfor
    "
    execute 'buffer ' . l:currBuff
    "
endfun

"
" Populate s:mylist with labels such as tbl:, eq:, fig: and tbl:
"
fun! s:FetchRefLabels() abort
    let l:reflist = []
    let l:currBuff = bufnr('%')
    call execute(
                \ 'bufdo if &l:filetype ==# "pandoc" | %s/\v#\zs(eq:|fig:|lst:|sec:|tbl:)(\w|-)+/' .
                \ '\=add(l:reflist, submatch(0))/gn | endif',
                \  'silent!'
                \ )
    execute 'buffer ' . l:currBuff
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
fun! s:PopulatePandoc() abort
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
                                \    line[start - 1] =~# '\a'
                                \ || line[start - 1] =~# '-'
                                \ || line[start - 1] =~# ':'
                                \ || line[start - 1] =~# '\d')
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
