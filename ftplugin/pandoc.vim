" vim: set fdm=marker et ts=4 sw=4 sts=4:

" File: ftplugin/pandoc.vim
" Description: vim-pandoc-handled buffer settings
" Author: Felipe Morales

" Source the plugin already here as Neovim has changed their loading order,
" and without it, the variables being checked below is not present.
"
" GH: https://github.com/neovim/neovim/issues/19008
" GH: https://github.com/vim-pandoc/vim-pandoc/issues/433
runtime! plugin/pandoc.vim

if (exists('b:did_ftplugin'))
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpoptions
set cpoptions&vim

" Start a new auto command group for all this plugin's hooks
augroup VimPandoc
    autocmd!
augroup END

" Modules: {{{1
" we initialize stuff depending on the values of g:pandoc#modules#enabled and
" g:pandoc#modules#disabled so this ftplugin is simply a loader.
"
let s:enabled_modules = []
for module in g:pandoc#modules#enabled
    if index(g:pandoc#modules#disabled, module) == -1
        let s:enabled_modules = add(s:enabled_modules, module)
    endif
endfor

for module in s:enabled_modules
    exe 'call pandoc#' . module . '#Init()'
endfor

if exists('loaded_matchit')
    setlocal matchpairs-=<:>
    let b:match_words = &l:matchpairs .
      \ ',' . '\%(^\|[ (/]\)\@<="' . ':' . '"\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=''' . ':' . '''\%($\|[ )/.\,;\:?!\-]\)'
let b:match_words .=
      \ ',' . '\%(^\|[ (/]\)\@<=\*' . ':' . '\*\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=\*\*' . ':' . '\*\*\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=\*\*\*' . ':' . '\*\*\*\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=_' . ':' . '_\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=__' . ':' . '__\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=___' . ':' . '___\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|[ (/]\)\@<=`[^`]' . ':' . '[^`]\@<=`\%($\|[ )/.\,;\:?!\-]\)' .
      \ ',' . '\%(^\|\s\)\@<=```' . ':' . '```\%($\|\s\)'
let b:match_words .=
      \ ',' . '\%(^\|[ (]\)\@<=\$[^$]' . ':' . '[^$]\@<=\$\%($\|[ ).\,;\:?!\-]\)' .
      \ ',' . '\%(^\|\s\)\@<=\$\$' . ':' . '\$\$\%($\|\s\)' .
      \ ',' . '\%(^\s*\)\@<=\\begin{\(\w\+\*\?\)}' . ':' . '\%(^\s*\)\@<=\\end{\1}'
endif

setlocal formatlistpat=\\C^\\s*[\\[({]\\\?\\([0-9]\\+\\\|[iIvVxXlLcCdDmM]\\+\\\|[a-zA-Z]\\)[\\]:.)}]\\s\\+\\\|^\\s*[-+o*]\\s\\+
setlocal formatoptions+=n

let b:undo_ftplugin = 'setlocal formatoptions< formatlistpat< matchpairs<'
                \ . '| unlet! b:match_words'
if exists('g:pandoc#formatting#equalprg') && !empty(g:pandoc#formatting#equalprg)
    let b:undo_ftplugin .= '| setlocal equalprg<'
endif

let &cpoptions = s:cpo_save
unlet s:cpo_save
