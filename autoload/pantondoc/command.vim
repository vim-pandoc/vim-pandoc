" creates the Pandoc command, requires python support
function! pantondoc#command#Init()
    if has("python")
	" let's make sure it gets loaded
	py import vim
        command! -buffer -bang -nargs=? -complete=customlist,pantondoc#command#PandocComplete Pandoc call pantondoc#command#Pandoc("<args>", "<bang>")
    endif
endfunction

" the Pandoc command itself, requires python support
function! pantondoc#command#Pandoc(args, bang)
    if has("python")
	py from pantondoc.command import pandoc
	py pandoc(vim.eval("a:args"), vim.eval("a:bang") != '')
    endif
endfunction

" the Pandoc command argument completion func, requires python support
function! pantondoc#command#PandocComplete(a, c, pos)
    if has("python")
	py from pantondoc.command import PandocHelpParser
	return pyeval("filter(lambda i: i.startswith(vim.eval('a:a')), sorted(PandocHelpParser.get_output_formats_table().keys()))")
    endif
endfunction

function! pantondoc#command#PandocAsyncCallback(should_open, returncode)
    if has("python")
	py from pantondoc.command import pandoc
	py pandoc.on_done(vim.eval("a:should_open") == '1', vim.eval("a:returncode"))
    endif
endfunction

