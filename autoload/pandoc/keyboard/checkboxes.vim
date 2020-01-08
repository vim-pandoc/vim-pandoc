" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#keyboard#checkboxes#Init() abort "{{{1

	 " Toggle existing checkbox or insert checkbox.
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-toggle-cb) :call pandoc#keyboard#checkboxes#Toggle()<cr>
	 " Remove existing checkbox
    noremap <buffer> <silent> <Plug>(pandoc-keyboard-delete-cb) :call pandoc#keyboard#checkboxes#Delete()<cr>
    if g:pandoc#keyboard#use_default_mappings == 1 && index(g:pandoc#keyboard#blacklist_submodule_mappings, 'checkboxes') == -1
        nmap <buffer> <localleader>cb <Plug>(pandoc-keyboard-toggle-cb)
        vmap <buffer> <localleader>cb <Plug>(pandoc-keyboard-toggle-cb)
        nmap <buffer> <localleader>cd <Plug>(pandoc-keyboard-delete-cb)
        vmap <buffer> <localleader>cd <Plug>(pandoc-keyboard-delete-cb)
    endif
endfunction

" Functions: {{{1

function! pandoc#keyboard#checkboxes#Toggle() abort "{{{2
	let l:line=getline('.')
	let l:curs=winsaveview()

	" match '- [ ]' and replace with '- [x]'
	if l:line=~?'^\s*\(-\|\*\)\s*\[ \] .*'
		:call setline(line('.'), substitute(l:line, '\[ \]', '\[x\]', ''))

	" match '- [x]' and replace with '- [ ]'
	elseif l:line=~?'^\s*\(-\|\*\)\s*\[x\] .*'
		:call setline(line('.'), substitute(l:line, '\[x\]', '\[ \]', ''))

	" match list item that does not have a [ at the beginning
	elseif l:line=~?'^\s*\(-\|\*\)\s*[^\[].*'
		:call setline(line('.'), substitute(l:line, '^\s*\(-\|\*\)', '\0 \[ \]', ''))
	endif
	call winrestview(l:curs)
endfunction

function! pandoc#keyboard#checkboxes#Delete() abort "{{{2
	let l:line=getline('.')
	let l:curs=winsaveview()

	if l:line=~?'^\s*\(-\|\*\)\s*\[[^\]]\] .*'
		:call setline(line('.'), substitute(l:line, '^\s*\(-\|\*\)\s*\zs\(\[[^\]]\]\) \ze', '', ''))
	endif
	call winrestview(l:curs)
endfunction
