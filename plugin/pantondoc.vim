" vim: set fdm=marker fdc=3: {{{1

" File: pantondoc.vim
" Description: pandoc support for vim
" Author: Felipe Morales
" }}}1

" Load? {{{1
if exists("g:pandoc#loaded") && g:pandoc#loaded || &cp
	finish
endif
let g:pandoc#loaded = 1
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
" }}}1

" Defaults: {{{1

" we set the default values for the configuration here

" General: {{{2
"
" Modules: {{{3
" Enabled modules {{{4
if !exists("g:pandoc#modules#enabled")
	let g:pandoc#modules#enabled = [
				\"bibliographies",
				\"completion",
				\"command",
				\"folding",
				\"formatting",
				\"menu",
				\"metadata",
				\"keyboard" ,
				\"toc"	]
endif

" Auxiliary module blacklist. {{{4
if !exists("g:pandoc#modules#disabled")
    let g:pandoc#modules#disabled = []
endif
if v:version < 704
    for incompatible_module in ["bibliographies", "command"]
	" user might have disabled them himself, check that
	if index(g:pandoc#modules#disabled, incompatible_module) == -1
	    let g:pandoc#modules#disabled = add(g:pandoc#modules#disabled, incompatible_module)
	    let s:module_disabled = 1
	endif
    endfor
    " only message the user if we have extended g:pandoc#modules#disabled
    " automatically
    if s:module_disabled == 1 
	echomsg "pantondoc: 'bibliographies' and 'command' modules require vim >= 7.4 and have been disabled."
    endif
endif
"}}}
" Filetypes: {{{3
"Markups to handle {{{4
if !exists("g:pandoc#filetypes#handled")
	let g:pandoc#filetypes#handled = [
				\"markdown",
				\"rst",
				\"textile"]
endif
"}}}
" Use pandoc extensions to markdown for all markdown files {{{4
if !exists("g:pandoc#filetypes#pandoc_markdown")
	let g:pandoc#filetypes#pandoc_markdown = 1
endif
"}}}
" Formatting: {{{2
 
" Formatting mode {{{3
" s: use soft wraps
" h: use hard wraps
" a: auto format (only used if h is set)
if !exists("g:pandoc#formatting#mode")
	let g:pandoc#formatting#mode = "s"
endif
"}}}
" = {{{3
" Use pandoc as equalprg?
if !exists("g:pandoc#formatting#pandoc_equalprg")
    let g:pandoc#formatting#pandoc_equalprg = 1
endif
" }}}
" Command: {{{2

" Use message buffers {{{3
if !exists("g:pandoc#command#use_message_buffers")
    let g:pandoc#command#use_message_buffers = 1
endif

" LaTeX engine to use to produce PDFs with pandoc (xelatex, pdflatex, lualatex) {{{3
if !exists("g:pandoc#command#latex_engine")
	let g:pandoc#command#latex_engine = "xelatex"
endif
"}}}
"}}}
" Bibliographies: {{{2

" Places to look for bibliographies {{{3
" b: bibs named after the current file in the working dir
" c: any bib in the working dir
" l: pandoc local dir
" t: texmf
" g: append values in g:pandoc#biblio#bibs
"
if !exists("g:pandoc#biblio#sources")
	let g:pandoc#biblio#sources = "bcg"
endif
"}}}
" Use bibtool for queries? {{{3
if !exists("g:pandoc#biblio#use_bibtool")
	let g:pandoc#biblio#use_bibtool = 0
endif
"}}}
" Files to add to b:pandoc_biblio_bibs if "g" is in g:pandoc#biblio#sources {{{3
if !exists("g:pandoc#biblio#bibs")
	let g:pandoc#biblio#bibs = []
endif
" }}}
" }}}2
" Keyboard: {{{2
"
" We use a mark for some functions, the user can change it so it doesn't {{{3
" interfere with his settings
if !exists("g:pandoc#keyboard#mark")
    let g:pandoc#keyboard#mark = "r"
endif

" What style to use when applying header styles {{{3
" a: atx headers
" s: setex headers for 1st and 2nd levels
" 2: add hashes at both ends
if !exists("g:pandoc#keyboard#header_style")
    let g:pandoc#keyboard#header_style = "a"
endif
" }}}2
" Folding: {{{2
" How to decide fold levels {{{3
" 'syntax': Use syntax
" 'relative': Count how many parents the header has
if !exists("g:pandoc#folding#mode")
    let g:pandoc#folding#mode = 'syntax'
endif
" Fold the YAML frontmatter {{{3
if !exists("g:pandoc#folding#fold_yaml")
    let g:pandoc#folding#fold_yaml = 0
endif
" What <div> classes to fold {{{3
if !exists("g:pandoc#folding#fold_div_classes")
    let g:pandoc#folding#fold_div_classes = ["notes"]
endif
" }}}2
" TOC: {{{2
if !exists("g:pandoc#toc#position")
    let g:pandoc#toc#position = "right" 
endif
" }}}2
" }}}1

" Autocommands: {{{1
" We must do this here instead of ftdetect because we need to be able to use
" the value of g:pandoc#filetypes#handled and
" g:pandoc#filetypes#pandoc_markdown

" augroup pandoc {{{2
" this sets the fiiletype for pandoc files
augroup pandoc
    au BufNewFile,BufRead *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc
    if g:pandoc#filetypes#pandoc_markdown == 1
	au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
    endif
augroup END
"}}}
" augroup pantondoc {{{2
" this loads the pantondoc functionality for configured extensions 
augroup pantondoc
    let s:exts = []
    for ext in g:pandoc#filetypes#handled
	call extend(s:exts, map(pantondoc_extensions_table[ext], '"*." . v:val'))
    endfor
    execute 'au BufRead,BufNewFile '.join(s:exts, ",").' runtime ftplugin/pantondoc.vim'
augroup END
"}}}
" }}}1
