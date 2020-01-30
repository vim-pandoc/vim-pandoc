" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#hypertext#Init() abort
    if !exists('g:pandoc#hypertext#open_editable_alternates')
        let g:pandoc#hypertext#open_editable_alternates = 1
    endif
    if !exists('g:pandoc#hypertext#editable_alternates_extensions')
        let g:pandoc#hypertext#editable_alternates_extensions ='\(pdf\|htm\|odt\|doc\)'
    endif
    if !exists('g:pandoc#hypertext#create_if_no_alternates_exists')
        let g:pandoc#hypertext#create_if_no_alternates_exists = 0
    endif
    if !exists('g:pandoc#hypertext#split_open_cmd')
        let g:pandoc#hypertext#split_open_cmd = 'botright vsplit'
    endif
    if !exists('g:pandoc#hypertext#edit_open_cmd')
        let g:pandoc#hypertext#edit_open_cmd = 'edit'
    endif
    if !exists('g:pandoc#hypertext#preferred_alternate')
        let g:pandoc#hypertext#preferred_alternate = 'md'
    endif
    if !exists('g:pandoc#hypertext#use_default_mappings')
        let g:pandoc#hypertext#use_default_mappings = 1
    endif
    if !exists('g:pandoc#hypertext#autosave_on_edit_open_link')
        let g:pandoc#hypertext#autosave_on_edit_open_link = 0
    endif

    if exists('g:pandoc#hypertext#automatic_link_regex')
        let s:automatic_link_regex = g:pandoc#hypertext#automatic_link_regex
    else
        let s:automatic_link_regex = '\v\<([^>]+)\>'
    endif

    if exists('g:pandoc#hypertext#inline_link_regex')
        let s:inline_link_regex = g:pandoc#hypertext#inline_link_regex
    else
        let s:inline_link_regex = '\v!?\[[^]]+\]\(([^) \t]+).*\)'
    endif

    if exists('g:pandoc#hypertext#reference_link_regex')
        let s:reference_link_regex = g:pandoc#hypertext#reference_link_regex
    else
        let s:reference_link_regex = '\v!?\[[^]]+\]\[([^]]*)\]'
    endif

    if exists('g:pandoc#hypertext#referenced_link_regex')
        let s:referenced_link_regex = g:pandoc#hypertext#referenced_link_regex
    else
        let s:referenced_link_regex = '\v\[[^]]+\]:\s*([^\t ]+)'
    endif


    nnoremap <silent> <buffer> <Plug>(pandoc-hypertext-open-local) :<C-u>call pandoc#hypertext#OpenLocal()<cr>
    nnoremap <silent> <buffer> <Plug>(pandoc-hypertext-open-system) :<C-u>call pandoc#hypertext#OpenSystem()<cr>
    nnoremap <silent> <buffer> <Plug>(pandoc-hypertext-goto-id) :<C-u>call pandoc#hypertext#GotoID()<cr>

    if g:pandoc#hypertext#use_default_mappings == 1
        nmap <buffer> gf <Plug>(pandoc-hypertext-open-local)
        nmap <buffer> gx <Plug>(pandoc-hypertext-open-system)
        nmap <buffer> <localleader>xi <Plug>(pandoc-hypertext-goto-id)
    endif
endfunction

function! s:IsEditable(path) abort
    let exts = []
    for type_exts in values(g:pandoc_extensions_table)
        for ext in type_exts
            call add(exts, fnamemodify('*.'.ext, ':e'))
        endfor
    endfor

    if index(exts, fnamemodify(a:path, ':e')) > -1
        return 1
    endif
    return 0
endfunction

function! s:SortAlternates(a, b) abort
    let ext = fnamemodify(a:a, ':e')
    if ext ==? g:pandoc#hypertext#preferred_alternate
        " return 1 will cass the preferred on at the last
        return -1
    endif
    " return 0 will cause others before the preferred
    return 1
endfunction

function! s:FindAlternates(path) abort
    let candidates = glob(fnamemodify(a:path, ':r').'.*', 0, 1)
    if candidates !=# []
        return filter(candidates, 's:IsEditable(v:val) && v:val !=# glob(a:path)')
    endif
    return []
endfunction

function! s:ExtendedCFILE() abort
    let orig_isfname = &isfname
    let &isfname = orig_isfname . ',?,&,:'
    let addr = expand('<cfile>')
    let &isfname = orig_isfname
    return addr
endfunction

function! pandoc#hypertext#PushLink(link) abort
    if !exists('w:link_stack')
        let w:link_stack = []
    endif
    let w:link_stack = add(w:link_stack, a:link)
endfunction

function! pandoc#hypertext#PopLink() abort
    if exists('w:link_stack')
        try
            let link = remove(w:link_stack,-1)
        catch
            return ['','']
        endtry
    else
        return ['','']
    endif
    return link
endfunction

" MatchstrAtCursor(pattern)
" Returns part of the line that matches pattern at cursor
" Copied from vimwiki plugin: autoload/base.vim
function! s:MatchstrAtCursor(pattern) abort "{{{1
    let col = col('.') - 1
    let line = getline('.')
    let ebeg = -1
    let cont = match(line, a:pattern, 0)
    while (ebeg >= 0 || (0 <= cont) && (cont <= col))
        let contn = matchend(line, a:pattern, cont)
        if (cont <= col) && (col < contn)
            let ebeg = match(line, a:pattern, cont)
            let elen = contn - ebeg
            break
        else
            let cont = match(line, a:pattern, contn)
        endif
    endwh
    if ebeg >= 0
        return strpart(line, ebeg, elen)
    else
        return ''
    endif
endfunc " }}}1

" GetLinkAtCursor(pat)
" get the specified type of link at cursor
function! s:GetLinkAtCursor(pat) abort "{{{1
    let matched_str = s:MatchstrAtCursor(a:pat)
    let url = substitute(matched_str, a:pat, '\1', 'g')
    let indices = [1, 4]

    if '!' ==# matched_str[:0]
        let indices = [2, 5]
    endif

    " for [hypertext][]
    if url ==# ''
        let url = strpart(matched_str, indices[0], strlen(matched_str) - indices[1])
    endif

    return url
endfunc " }}}1

function! s:GetReferenceUrl(ref) abort
    let pattern = '\v\c\s*\['.a:ref.'\]:\s*([^ ]+)'
    let linenum = search(pattern, 'nw')
    return substitute(getline(linenum), pattern, '\1', 'g')
endfunction


" GetLinkAddress
" get the link at cursor
function! pandoc#hypertext#GetLinkAddress() abort
    let link = s:GetLinkAtCursor(s:automatic_link_regex)

    " get link at cursor
    if link ==# ''
        let link = s:GetLinkAtCursor(s:inline_link_regex)

        if link ==# ''
            let link = s:GetLinkAtCursor(s:reference_link_regex)

            if link ==# ''
                let link = s:GetLinkAtCursor(s:referenced_link_regex)
            else
                " find the reference link
                let link = s:GetReferenceUrl(link)
            endif
        endif
    endif

    return link
endfunction

function! pandoc#hypertext#OpenFileWithCmd(file, cmd, push) abort
    if a:cmd ==# g:pandoc#hypertext#edit_open_cmd
        if &modified ==# 1 &&
                    \ g:pandoc#hypertext#autosave_on_edit_open_link == 1
            exe 'write'
        endif
        if a:push == 1
            call pandoc#hypertext#PushLink( ['file', expand('%:p')] )
        endif
    endif
    exe a:cmd . ' ' . a:file
endfunction

function! pandoc#hypertext#OpenLocal(...) abort
    if exists('a:1')
        let addr = a:1
    else
        let addr = s:ExtendedCFILE()
    endif

    if exists('a:2')
        let cmd = a:2
    else
        let cmd = g:pandoc#hypertext#split_open_cmd
    endif

    if g:pandoc#hypertext#open_editable_alternates == 1
        let ext = fnamemodify(addr, ':e')
        if ext =~ g:pandoc#hypertext#editable_alternates_extensions
            let alt_addrs = s:FindAlternates(addr)
            if alt_addrs !=# []
                let pos = 0
                if len(alt_addrs) > 1
                    let alt_file = fnamemodify(addr, ':r') . '.' . g:pandoc#hypertext#preferred_alternate
                    let pos = index(alt_addrs, glob(alt_file))

                    if pos == -1
                        let pos = 0
                    endif
                endif
                let addr = alt_addrs[pos]
            else
                " check weather to create the alternate file
                if g:pandoc#hypertext#create_if_no_alternates_exists == 1
                    let dir = fnamemodify(addr, ':p:h')

                    if !isdirectory(dir)
                        call system('mkdir -p '.dir)
                    endif

                    let addr = fnamemodify(addr, ':r') . '.' . g:pandoc#hypertext#preferred_alternate
                    call pandoc#hypertext#OpenFileWithCmd(addr, cmd, 1)
                else
                    call pandoc#hypertext#OpenSystem(addr)
                endif

                return
            endif
        endif
    endif

    if glob(addr) !=# '' || g:pandoc#hypertext#create_if_no_alternates_exists == 1
        call pandoc#hypertext#OpenFileWithCmd(addr, cmd, 1)
    endif
endfunction

function! pandoc#hypertext#OpenSystem(...) abort
    if exists('a:1')
        let addr = a:1
    else
        let addr = s:ExtendedCFILE()
    endif

    if has('unix') && executable('xdg-open')
        call system('xdg-open '. shellescape(expand(addr,':p')))
    elseif has('win32') || has('win64')
        call system('cmd /c "start '. addr .'"')
    elseif has('macunix')
        call system('open '. addr)
    endif
endfunction


function! pandoc#hypertext#OpenLink(cmd) abort
    let url = pandoc#hypertext#GetLinkAddress()
    let ext = fnamemodify(url, ':e')
    let hashnum = match(url, '#')
    let sname = synIDattr(synID(line('.'), col('.'), 0), 'name')
    let curpos = getcurpos()
    let pos = getpos('.')
    let curfile = expand('%:p')

    if hashnum != -1 && hashnum != 0
        let id = url[hashnum + 1:]
        let url = url[:hashnum - 1]
        let ext = fnamemodify(url, ':e')
    endif

    if '#' ==# url[:0]
        call pandoc#hypertext#GotoID(url[1:], sname, curpos, pos)
    elseif ext =~ g:pandoc#hypertext#editable_alternates_extensions || s:IsEditable(url)
        call pandoc#hypertext#OpenLocal(url, a:cmd)
        if hashnum != -1
            call pandoc#hypertext#GotoID(id, sname, curpos, pos)
            call pandoc#hypertext#PushLink( ['file', curfile] )
        endif
    else
        call pandoc#hypertext#OpenSystem(url)
    endif
endfunction

function! pandoc#hypertext#BackFromLink() abort
    let [type, link] = pandoc#hypertext#PopLink()
    if type ==# 'position'
        call setpos('.', link)
    elseif type ==# 'file'
        call pandoc#hypertext#OpenFileWithCmd(link, g:pandoc#hypertext#edit_open_cmd, 0)
    endif
endfunction

function! pandoc#hypertext#BackFromFile() abort
    if exists('w:link_stack')
        let types = map(reverse(copy(w:link_stack)), 'v:val[0]')
        let i = index(types, 'file')
        if i != -1
            let w:link_stack = w:link_stack[0:-i-1]
            call pandoc#hypertext#BackFromLink()
        endif
    endif
endfunction

function! pandoc#hypertext#GotoID(...) abort
    if a:2 !=# 'pandocHeaderID'
        if exists('a:1')
            let id = a:1
        else
            let id = expand('<cfile>')
        endif

        try
            " call pandoc#hypertext#PushLink( ['position',getcurpos()] )
            call pandoc#hypertext#PushLink( ['position',a:3] )
        catch /E117/
            " call pandoc#hypertext#PushLink( ['position',getpos('.')] )
            call pandoc#hypertext#PushLink( ['position', a:4] )
        endtry
        " header indentifier
        let header_pos = markdown#headers#GetAllIDs()
        let line = get(header_pos, id)

        if line > 0
            call cursor(line, 1)
        else
            call pandoc#hypertext#BackFromLink()
        endif
    endif
endfunction
