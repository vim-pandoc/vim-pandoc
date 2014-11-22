" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#references#Init() "{{{1
    " Defaults: {{{2
     " We use a mark for some functions, the user can change it
    " so it doesn't interfere with his settings
    if !exists("g:pandoc#keyboard#references#mark")
        let g:pandoc#keyboard#references#mark = "r"
    endif
    "}}}2
    " Add new reference link (or footnote link) after current paragraph.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-insert) :call pandoc#keyboard#references#Insert_Ref()<cr>a
    " Go to link or footnote definition for label under the cursor.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-goto) :call pandoc#keyboard#references#GOTO_Ref()<CR>
    " Go back to last point in the text we jumped to a reference from.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-ref-backfrom) :call pandoc#keyboard#references#BACKFROM_Ref()<CR>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, "references") == -1
        nmap <buffer> <localleader>nr <Plug>(pandoc-keyboard-ref-insert)
        nmap <buffer> <localleader>rg <Plug>(pandoc-keyboard-ref-goto)
        nmap <buffer> <localleader>rb <Plug>(pandoc-keyboard-ref-backfrom)
    endif
endfunction

" Functions: {{{1
" handling: {{{2
function! pandoc#keyboard#references#Insert_Ref()
    execute "normal m".g:pandoc#keyboard#references#mark
    let reg_save = getreg('*')
    normal "*ya[
    call search('\n\(\n\|\_$\)\@=')
    execute "normal! o\<cr>\<esc>0".'"*P'."$a: "
    call setreg('*', reg_save)
endfunction
" }}}2
" navigation: {{{2

function! pandoc#keyboard#references#GOTO_Ref()
    let reg_save = getreg('*')
    execute "normal m".g:pandoc#keyboard#references#mark
    execute "silent normal! ?[\<cr>vf]".'"*y'
    call setreg('*', substitute(getreg('*'), '\[', '\\\[', 'g'))
    call setreg('*', substitute(getreg('*'), '\]', '\\\]', 'g'))
    execute "silent normal! /".getreg('*').":\<cr>"
    call setreg('*', reg_save)
endfunction

function! pandoc#keyboard#references#BACKFROM_Ref()
    try
        execute 'normal  `'.g:pandoc#keyboard#references#mark
        " clean up
        execute 'delmark '.g:pandoc#keyboard#references#mark
    catch /E20/ "no mark set, we must search backwards.
        let reg_save = getreg('*')
        "move right, because otherwise it would fail if the cursor is at the
        "beggining of the line
        execute "silent normal! 0l?[\<cr>vf]".'"*y'
        call setreg('*', substitute(getreg('*'), '\]', '\\\]', 'g'))
        execute "silent normal! ?".getreg('*')."\<cr>"
        call setreg('*', reg_save)
    endtry
endfunction

function! pandoc#keyboard#references#NextRefDefinition()
endfunction

function! pandoc#keyboard#references#PrevRefDefinition()
endfunction
" }}}2
" }}}1

