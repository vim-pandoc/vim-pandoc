" creates the Pandoc command, requires python support
function! pantondoc_command#InitCommand()
    if has("python")
        command! -buffer -bang -nargs=? -complete=customlist,pantondoc_command#PandocComplete Pandoc call pantondoc_command#Pandoc("<args>", "<bang>")
    endif
endfunction

" the Pandoc command itself, requires python support
function! pantondoc_command#Pandoc(args, bang)
    if has("python")
	py from pantondoc.command import pandoc
	py pandoc(vim.eval("a:args"), vim.eval("a:bang") != '')
    endif
endfunction

" the Pandoc command argument completion func, requires python support
function! pantondoc_command#PandocComplete(a, c, pos)
    if has("python")
	py from pantondoc.command import output_extensions
	return pyeval("filter(lambda i: i.startswith(vim.eval('a:a')), sorted(output_extensions.keys()))")
    endif
endfunction
