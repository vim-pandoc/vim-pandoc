" File: indent/pandoc.vim
" Description: Indentation of pandoc buffers
" Author: Jake Zimmerman
"
" TODO:
" - Detect more LaTeX regions which should be indented
"   - Make this configurable
" - Detect syntax within language blocks, and indent them appropriately
"   - Make this configurable according to the existing configuration options
" - Add documentation to help files


if exists("b:did_indent")
  finish
endif

runtime! indent/tex.vim

let b:did_indent = 1

setlocal indentexpr=GetPandocIndent()

" Only define the function once.
if exists("*GetPandocIndent")
  finish
endif

function GetPandocIndent()
  " Use information from syntax matching rules to determine if we're in a
  " special indentation region
  let l:stack = synstack(line('.'), col('.'))
  if len(l:stack) > 0 && synIDattr(l:stack[0], 'name') == 'pandocLaTeXRegion'
    return GetTeXIndent()
  else
    return -1
  endif
endfunc

