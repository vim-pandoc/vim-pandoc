function! pantondoc#menu#Init()
    call pantondoc#menu#CreateMenu()
endfunction

function! pantondoc#menu#CreateMenu()
    if index(g:pantondoc_enabled_modules, "command") >= 0
	amenu .600 Pantondoc.Pandoc.&Pdf :Pandoc pdf<CR>
	amenu .601 Pantondoc.Pandoc.Pdf\ \(Open\) :Pandoc! pdf<CR>
	amenu .602 Pantondoc.Pandoc.&Beamer :Pandoc beamer<CR>
	amenu .603 Pantondoc.Pandoc.Beamer\ \(Open\) :Pandoc! beamer<CR>
	amenu .604 Pantondoc.Pandoc.&ODT :Pandoc odt<CR>
	amenu .605 Pantondoc.Pandoc.ODT\ \(Open\) :Pandoc! odt<CR>
	amenu .604 Pantondoc.Pandoc.&HTML :Pandoc html -s<CR>
	amenu .605 Pantondoc.Pandoc.HTML\ \(Open\) :Pandoc! html -s<CR>
	amenu .699 Pantondoc.-Sep1- :
    endif
    " TODO: config menu, needs configuration toggle functions first
    amenu .900 Pantondoc.Help :help pantondoc<CR>
    amenu .910 Pantondoc.? :echo "vim-pantondoc, experimental pandoc plugin, alpha-mark2"<CR>
endfunction

