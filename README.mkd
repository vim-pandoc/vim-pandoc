# vim-pandoc

[![Vint](https://github.com/vim-pandoc/vim-pandoc/workflows/Vint/badge.svg)](https://github.com/vim-pandoc/vim-pandoc/actions?workflow=Vint)

`vim-pandoc` provides facilities to integrate Vim with the [pandoc][] document
converter and work with documents written in [its markdown
variant](http://johnmacfarlane.net/pandoc/README.html#pandocs-markdown)
(although textile documents are also supported). 

`vim-pandoc`'s goals are 1) to provide advanced integration with pandoc, 2) a
comfortable document writing environment, and 3) great configurability.

[pandoc]: http://johnmacfarlane.net/pandoc/

## IMPORTANT

* **`vim-pandoc` doesn't provide syntax support**. The user needs to install
  [vim-pandoc/vim-pandoc-syntax][] alongside it (see below). The reason for
  this is we have found cleaner to keep the bug tracking of the syntax file and
  the rest of the system separate.

[vim-pandoc/vim-pandoc-syntax]: https://github.com/vim-pandoc/vim-pandoc-syntax

## Outstanding features 

* [x] Modular architecture, so the user is in control of what the plugin does.
  For example, if you decide you don't want to use our folding rules, you can
  disable them without it affecting other parts of vim-pandoc. Modules are
  simple to develop, too.
* [x] Sets up a comfortable environment for editing prose, either for soft or
  hard wraps.
* [x] Can execute pandoc asynchronously, through the `:Pandoc` command, which
  can accept any argument pandoc takes, both in regular vim and in
  [neovim](https://github.com/neovim/neovim).
* [x] `pandoc` is a filetype plugin, but it can also attach itself to
  different filetypes, like textile or restructuredText. The user is not
  limited to use pandoc with markdown.
* [x] Useful custom mappings for markdown writers (partially implemented,
  perpetually ongoing). For example, we provide WYSIWYG-style style toggles for
  emphasis, strong text, subscripts, etc. [Suggestions are
  welcome.](https://github.com/vim-pandoc/vim-pandoc/issues/2)
* [x] Advanced folding support (syntax assisted, relative ordering...).
* [x] TOC functionality, using vim's quickfix system.
* [x] Bibliographies support, like autocompletion of cite keys. We plan to
  display additional information on the bibliography items on request. 
* [x] Basic hypertext support: follow internal and external links.
* [ ] Annotations: add metadata to your files (comments, TODOs, etc.)

## Requirements

* Vim 7.4/Neovim (we make use of the new python API).
* Python 3
- Pandoc 2.x

## Installation

The plugin follows the usual bundle structure, so it's easy to install it using
[pathogen](https://github.com/tpope/vim-pathogen),
[Vundle](https://github.com/gmarik/vundle) or NeoBundle.

The most recent version is available [at
github](https://github.com/vim-pandoc/vim-pandoc). For those who need it, a
tarball is available from
[here](https://github.com/vim-pandoc/vim-pandoc/archive/master.zip).

For Vundle users, it should be enough to add

    Plugin 'vim-pandoc/vim-pandoc'

to `.vimrc`, and then run `:PluginInstall`.

It is *very strongly* recommended that all users of `vim-pandoc` install
`vim-pandoc-syntax` too:

    Plugin 'vim-pandoc/vim-pandoc-syntax' 

## Contributing

[fmoralesc](http://github.com/fmoralesc) is the project maintainer, and he tries
to solve all issues as soon as possible. Help is very much appreciated, in the
form of bug reports, fixes, code and suggestions. 

If you have a problem, it is better to open a issue in the [issue tracker at
github][]. Please state the problem clearly, and if possible, provide a
document sample to reproduce it.

[issue tracker at github]: https://github.com/vim-pandoc/vim-pandoc/issues

Join the chat at https://gitter.im/vim-pandoc/vim-pandoc
