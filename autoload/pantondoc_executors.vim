function! pantondoc_executors#InitExecutors()
	if has("python")
		if g:pantondoc_executors_register_from_cache == 1
			python pantondoc.executors.register_from_cache()
		endif
		python pantondoc.executors.create_executors()
		command! -buffer -nargs=? PantondocRegisterExecutor call pantondoc_executors#RegisterExecutor("<args>")
	endif
endfunction

function! pantondoc_executors#RegisterExecutor(ref)
	python pantondoc.executors.register_executor(vim.eval("a:ref"))
endfunction

function! pantondoc_executors#Execute(command, type, bang)
	python pantondoc.executors.execute(vim.eval("a:command"), vim.eval("a:type"), True if vim.eval("a:bang") == "!" else False)
endfunction
