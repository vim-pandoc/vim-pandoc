function! pantondoc_menu#CreateMenu()
	" .100 Modules
	amenu .100 Pantondoc.Modules.List\ Modules :echo "Enabled modules: ".join(g:pantondoc_enabled_modules, ", ")<CR>
	amenu .110 Pantondoc.Modules.-Sep1- :
	" TODO: Toggles should come here
	" .200 General configuration
	amenu .800 Pantondoc.-Sep2- :
	amenu .900 Pantondoc.Help :help pantondoc<CR>
	amenu .910 Pantondoc.? :echo "vim-pantondoc, experimental pandoc plugin, 0.1pre"<CR>
endfunction

