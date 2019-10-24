if exists('current_compiler')
  finish
endif

let current_compiler = (exists('g:pandoc#compiler#command') ? g:pandoc#compiler#command : 'pandoc')
let compiler_args = (exists('g:pandoc#compiler#arguments') ? escape(' '.g:pandoc#compiler#arguments, '\ ') : '')

CompilerSet errorformat="%f",\ line\ %l:\ %m
execute 'CompilerSet makeprg='.current_compiler.compiler_args
