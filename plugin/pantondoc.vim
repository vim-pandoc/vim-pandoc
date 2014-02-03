" vim: set fdm=marker fdc=3: {{{1

" File: pantondoc.vim
" Description: experimental pandoc support for vim
" Author: Felipe Morales
" }}}1

" Load? {{{1
if exists("g:loaded_pantondoc") && g:loaded_pantondoc || &cp
	finish
endif
let g:loaded_pantondoc = 1
" }}}1

" Globals: {{{1

" we use this to configure to what filetypes we attach to
let pantondoc_extensions_table = {
			\"extra": ["text", "txt"],
			\"html": ["html", "htm"],
			\"json" : ["json"],
			\"latex": ["latex", "tex", "ltx"],
			\"markdown" : ["markdown", "mkd", "md", "pandoc", "pdk", "pd", "pdc"],
			\"native" : ["hs"],
			\"rst" : ["rst"],
			\"textile": ["textile"] }
let modules_that_require_704 = [
			\"command",
			\"bibliographies"]
" }}}1

" Defaults: {{{1

" we set the default values for the configuration here

" General: {{{2
"
" Enabled modules {{{3
if !exists("g:pantondoc_enabled_modules")
	let g:pantondoc_enabled_modules = [
				\"completion",
				\"folding",
				\"formatting",
				\"menu",
				\"metadata",
				\"keyboard" ]
	if (v:version >= 704)
		call extend(g:pantondoc_enabled_modules, modules_that_require_704)
	endif
else
	if (v:version < 704)
		let disabled = []
		for module in modules_that_require_704
			let idx = index(g:pantondoc_enabled_modules, module)
			if (idx >= 0)
				call add(disabled, module)
				call remove(g:pantondoc_enabled_modules, idx)
			endif
		endfor
		let msg = join(disabled, ", ")
		echomsg 'The following modules require vim >= 7.4 and have been '
			   \'disabled for now: ' . msg
	endif
endif

" Auxiliary module blacklist.
if !exists("g:pantondoc_disabled_modules")
    let g:pantondoc_disabled_modules = []
    if v:version < 704
	let g:pantondoc_disabled_modules = extend(g:pantondoc_disabled_modules, ["bibliographies", "command"])
	" commented out because it is intrusive
	"echoerr "pantondoc: 'bibliographies' and 'command' modules require vim >= 7.4 and have been disabled."
    endif
endif
"}}}
"Markups to handle {{{3
if !exists("g:pantondoc_handled_filetypes")
	let g:pantondoc_handled_filetypes = [
				\"markdown",
				\"rst",
				\"textile"]
endif
"}}}
" Use pandoc extensions to markdown for all markdown files {{{3
if !exists("g:pantondoc_use_pandoc_markdown")
	let g:pantondoc_use_pandoc_markdown = 0
endif
"}}}
" Formatting: {{{2
 
" Formatting mode {{{3
" s: use soft wraps
" h: use hard wraps
" a: auto format (only used if h is set)
if !exists("g:pantondoc_formatting_settings")
	let g:pantondoc_formatting_settings = "s"
endif
"}}}

" Equalprg: {{{2

" Use pandoc as equalprg?
if !exists("g:pantondoc_use_pandoc_equalprg")
    let g:pantondoc_use_pandoc_equalprg = 1
endif
" }}}
" Command: {{{2

" Use message buffers
if !exists("g:pantondoc_use_message_buffers")
    let g:pantondoc_use_message_buffers = 1
endif

" LaTeX engine to use to produce PDFs with pandoc (xelatex, pdflatex, lualatex) {{{3
if !exists("g:pantondoc_command_latex_engine")
	let g:pantondoc_command_latex_engine = "xelatex"
endif
"}}}
"}}}
" Bibliographies: {{{2

" Places to look for bibliographies {{{3
" b: bibs named after the current file in the working dir
" c: any bib in the working dir
" l: pandoc local dir
" t: texmf
" g: append values in g:pantondoc_bibfiles
"
if !exists("g:pantondoc_biblio_sources")
	let g:pantondoc_biblio_sources = "bcg"
endif
"}}}
" Use bibtool for queries? {{{3
if !exists("g:pantondoc_biblio_use_bibtool")
	let g:pantondoc_biblio_use_bibtool = 0
endif
"}}}
" Files to add to b:pantondoc_bibs if "g" is in g:pantondoc_biblio_sources {{{3
if !exists("g:pantondoc_bibs")
	let g:pantondoc_bibs = []
endif
" }}}
" }}}2

" Keyboard: {{{2
"
if !exists("g:pantondoc_mark")
    let g:pantondoc_mark = "r"
endif
" }}}2
"
" Folding: {{{2
if !exists("g:pantondoc_folding_fold_yaml")
    let g:pantondoc_folding_fold_yaml = 0
endif
" }}}2
" }}}1

" Autocommands: {{{1
" We must do this here instead of ftdetect because we need to be able to use
" the value of g:pantondoc_handled_filetypes and
" g:pantondoc_use_pandoc_markdown

" augroup pandoc {{{2
" this sets the fiiletype for pandoc files
augroup pandoc
    au BufNewFile,BufRead *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc
    if g:pantondoc_use_pandoc_markdown == 1
	au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
    endif
augroup END
"}}}
" augroup pantondoc {{{2
" this loads the pantondoc functionality for configured extensions 
augroup pantondoc
    let s:exts = []
    for ext in g:pantondoc_handled_filetypes
	call extend(s:exts, map(pantondoc_extensions_table[ext], '"*." . v:val'))
    endfor
    execute 'au BufRead,BufNewFile '.join(s:exts, ",").' runtime ftplugin/pantondoc.vim'
augroup END
"}}}
" }}}1
