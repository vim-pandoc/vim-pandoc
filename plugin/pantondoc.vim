" vim: set fdm=marker fdc=3: {{{1

" File: pantondoc.vim
" Description: experimental pandoc support for vim
" Author: Felipe Morales
" Version: alpha1 }}}1

" Load? {{{1
if exists("g:loaded_pantondoc") && g:loaded_pantondoc
	|| &cp
	|| has("python") == 0
	finish
endif
let g:loaded_pantondoc = 1
" }}}1

" Defaults: {{{1

" General: {{{2
"
" Enabled modules {{{3
if !exists("g:pantondoc_enabled_modules")
	let g:pantondoc_enabled_modules = ["formatting", "folding", "executors", "motions", "bibligraphies", "completion", "metadata", "menu", "externals", "tables"]
endif

"Markups to handle {{{3
if !exists("g:pantondoc_handled_filetypes")
	let g:pantondoc_handled_filetypes = ["markdown", "rst", "textile", "extra"]
endif

" Use pandoc extensions to markdown for all markdown files {{{3
if !exists("g:pantondoc_use_pandoc_markdown")
	let g:pantondoc_use_pandoc_markdown = 0
endif

" Formatting: {{{2
 
" Formatting mode {{{3
" s: use soft wraps
" h: use hard wraps
" a: auto format (only used if h is set)
if !exists("g:pantondoc_formatting_settings")
	let g:pantondoc_formatting_settings = "h"
endif

" Executors: {{{2

" Must pandoc/markdown2pdf executors be created from the cache? {{{3
if !exists("g:pantondoc_executors_register_from_cache")
	let g:pantondoc_executors_register_from_cache  = 1
endif

" Save user executors {{{3
if !exists("g:pantondoc_executors_save_new")
	let g:pantondoc_executors_save_new = 1
endif

" LaTeX engine to use to produce PDFs with pandoc (xelatex, pdflatex, lualatex) {{{3
if !exists("g:pantondoc_executors_latex_engine")
	let g:pantondoc_executors_latex_engine = "xelatex"
endif
" }}}1

" Import pantondoc lib {{{1
python<<EOF
import vim, sys
sys.path.append(vim.eval("expand('<sfile>:p:h')"))
import pantondoc
EOF
" }}}1

" Commands: {{{1

command! -nargs=? PantondocRegisterExecutor call pantondoc_executors#RegisterExecutor("<args>")
" }}}1

" Autocommands: {{{1
" We must do this here instead of ftdetect because we need to be able to use
" the value of g:pantondoc_handled_filetypes and
" g:pantondoc_use_pandoc_markdown
 
augroup pantondoc
python<<EOF
from pantondoc.utils import ex
exts = ",".join(["*." + ext for ext in pantondoc.pandoc.get_input_extensions()])
ex('au BufRead,BufNewFile', exts ,'runtime ftplugin/pantondoc.vim')
EOF
augroup END

augroup pandoc
	au BufNewFile,BufRead *.pandoc,*.pdk,*.pd set filetype=pandoc
	if g:pantondoc_use_pandoc_markdown == 1
		au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
	endif
augroup END
" }}}1
