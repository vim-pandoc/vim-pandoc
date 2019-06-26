if exists("current_compiler") | finish | endif
let current_compiler = "latexrun"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=latexrun\ --color\ never\ %
CompilerSet errorformat=%f:%l:\ %t%*[^:]:\ %m,%p^

let &cpo = s:cpo_save
unlet s:cpo_save
