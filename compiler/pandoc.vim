if exists("current_compiler")
  finish
endif

let current_compiler = "pandoc"

CompilerSet errorformat="%f",\ line\ %l:\ %m
CompilerSet makeprg=pandoc
