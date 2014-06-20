function! pandoc#menu#Init()
    call pandoc#menu#CreateMenu()
endfunction

function! pandoc#menu#CreateMenu()
    if index(g:pandoc#modules#enabled, "command") >= 0
	amenu .600 Pandoc.Pandoc.&Pdf :Pandoc pdf<CR>
	amenu .601 Pandoc.Pandoc.Pdf\ \(Open\) :Pandoc! pdf<CR>
	amenu .602 Pandoc.Pandoc.&Beamer :Pandoc beamer<CR>
	amenu .603 Pandoc.Pandoc.Beamer\ \(Open\) :Pandoc! beamer<CR>
	amenu .604 Pandoc.Pandoc.&ODT :Pandoc odt<CR>
	amenu .605 Pandoc.Pandoc.ODT\ \(Open\) :Pandoc! odt<CR>
	amenu .604 Pandoc.Pandoc.&HTML :Pandoc html -s<CR>
	amenu .605 Pandoc.Pandoc.HTML\ \(Open\) :Pandoc! html -s<CR>
	amenu .699 Pandoc.-Sep1- :
    endif
    " TODO: config menu, needs configuration toggle functions first
    amenu .900 Pandoc.Help :help pandoc<CR>
    amenu .910 Pandoc.? :echo "vim-pandoc"<CR>
endfunction

