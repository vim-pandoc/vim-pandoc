function! pantondoc_command#InitCommand()
    if has("python")
	py import pantondoc_command
        command! -buffer -bang -nargs=? Pandoc call pantondoc_command#Pandoc("<args>", "<bang>")
    endif
endfunction

function! pantondoc_command#Pandoc(args, bang)
    if has("python")
	py pantondoc_command.command(vim.eval("a:args"), vim.eval("a:bang") != '')
    endif
endfunction
