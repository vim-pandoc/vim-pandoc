" vim: set fdm=marker :

" Init(): sets up defaults, creates the Pandoc command, requires python support {{{1
function! pandoc#command#Init()
    " set up defaults {{{2
    " use message buffers? {{{3
    if !exists("g:pandoc#command#use_message_buffers")
	let g:pandoc#command#use_message_buffers = 1
    endif

    " LaTeX engine to use to produce PDFs with pandoc (xelatex, pdflatex, lualatex) {{{3
    if !exists("g:pandoc#command#latex_engine")
	let g:pandoc#command#latex_engine = "xelatex"
    endif

    " create :Pandoc {{{2
    if has("python")
	" let's make sure it gets loaded
	py import vim
        command! -buffer -bang -nargs=? -complete=customlist,pandoc#command#PandocComplete 
                    \ Pandoc call pandoc#command#Pandoc("<args>", "<bang>")
    endif "}}}2
endfunction

" Pandoc(args, bang): the Pandoc command itself, requires python support {{{1
" args: arguments to pass pandoc
" bang: should we open the created file afterwards?
function! pandoc#command#Pandoc(args, bang)
    if has("python")
	py from vim_pandoc.command import pandoc
	py pandoc(vim.eval("a:args"), vim.eval("a:bang") != '')
    endif
endfunction

" PandocComplete(a, c, pos): the Pandoc command argument completion func, requires python support {{{1
function! pandoc#command#PandocComplete(a, c, pos)
    if has("python")
	py from vim_pandoc.command import PandocHelpParser
        let cmd_args = split(a:c, " ", 1)[1:]
        if len(cmd_args) == 1 && (cmd_args[0] == '' || pyeval("vim.eval('cmd_args[0]').startswith(vim.eval('a:a'))"))
            return pyeval("filter(lambda i: i.startswith(vim.eval('a:a')), sorted(PandocHelpParser.get_output_formats_table().keys()))")
        endif
        if len(cmd_args) >= 2
            let long_opts = pyeval("['--' + i for i in filter(lambda i: i.startswith(vim.eval('a:a[2:]')), PandocHelpParser.get_longopts())]")
            let short_opts = pyeval("['-' + i for i in filter(lambda i: i.startswith(vim.eval('a:a[1:]')), PandocHelpParser.get_shortopts())]")
            return filter(uniq(extend(sort(short_opts), sort(long_opts))), 'v:val != "-:"')
        endif
    endif
endfunction

" PandocAsyncCallback(should_open, returncode): Callback to execute after pandoc finished {{{1
" should_open: should we open the cretaed file?
" returncode: the returncode value pandoc gave
function! pandoc#command#PandocAsyncCallback(should_open, returncode)
    if has("python")
	py from vim_pandoc.command import pandoc
	py pandoc.on_done(vim.eval("a:should_open") == '1', vim.eval("a:returncode"))
    endif
endfunction

