" vim: set fdm=marker fdc=3: {{{1

" File: pantondoc.vim
" Description: experimental pandoc support for vim
" Author: Felipe Morales
" Version: alpha1 }}}1

" Load? {{{1
if exists("g:loaded_pantondoc") && g:loaded_pantondoc
	|| &cp
	finish
endif
let g:loaded_pantondoc = 1
" }}}1

" Globals: {{{1

let pantondoc_extensions_table = {
			\"markdown" : ["markdown", "mkd", "md", "pandoc", "pdk", "pd"],
			\"native" : ["hs"],
			\"rst" : ["rst"],
			\"json" : ["json"],
			\"textile": ["textile"],
			\"html": ["html", "htm"],
			\"latex": ["latex", "tex", "ltx"],
			\"extra": ["text", "txt"] }
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

" Autocommands: {{{1
" We must do this here instead of ftdetect because we need to be able to use
" the value of g:pantondoc_handled_filetypes and
" g:pantondoc_use_pandoc_markdown
 
augroup pantondoc
	let s:exts = []
	for ext in g:pantondoc_handled_filetypes
		call extend(s:exts, map(pantondoc_extensions_table[ext], '"*." . v:val'))
	endfor
	execute 'au BufRead,BufNewFile '.join(s:exts, ",").' runtime ftplugin/pantondoc.vim'
augroup END

augroup pandoc
	au BufNewFile,BufRead *.pandoc,*.pdk,*.pd set filetype=pandoc
	if g:pantondoc_use_pandoc_markdown == 1
		au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
	endif
augroup END
" }}}1

" Import pantondoc lib {{{1
" if we have python, we will want to load the pantondoc lib asap
if has("python")
python<<EOF
import vim, sys
sys.path.append(vim.eval("expand('<sfile>:p:h')"))
import pantondoc
EOF
endif
" }}}1
