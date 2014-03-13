# encoding=utf-8

import vim
import re
import sys
import os.path
import getopt
import shlex
from subprocess import Popen, PIPE
import tempfile
import fileinput
from pantondoc import bib

class PandocHelpParser(object):
    def __init__(self):
        self._help_data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        self.longopts = self.get_longopts()
        self.shortopts = self.get_shortopts()

    def get_longopts(self):
        return map(lambda i: i.replace("--", ""), \
                   filter(lambda i: i not in ("--version", "--help", "--to", "--write"), \
                          [ i.group() for i in re.finditer("-(-\w+)+=?", self._help_data)]))

    def get_shortopts(self):
        no_args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-v ", "-h "), \
                             [i.group() for i in re.finditer("-\w\s(?!\w+)", self._help_data)]))

        # -m doesn't comply with the format of the other short options in pandoc 1.12
        # if you need to pass an URL, use the long versions
        no_args.append("m")

        args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-t ", "-w "), \
                             [i.group() for i in re.finditer("-\w\s(?=[A-Z]+)", self._help_data)]))


        return "".join(no_args) + "".join(map(lambda i: i + ":", args))

    @staticmethod
    def _get_formats():
        data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        return " ".join(re.findall('(\w+\**[,\n])+', data)).split("\n")[:2]

    @staticmethod
    def _get_input_formats():
        return map(lambda i: i.strip(), PandocHelpParser._get_formats()[0].split(", "))

    @staticmethod
    def _get_output_formats():
        return map(lambda i: i.strip().replace("*", ""), PandocHelpParser._get_formats()[1].split(", "))

    @staticmethod
    def get_output_formats_table():
        table = {}
        for i in PandocHelpParser._get_output_formats():
            if i in ("asciidoc", "plain"):
                table[i] = "txt"
            elif i in ("beamer", "pdf"):
                table[i] = "pdf"
            elif i in ("dzslides", "html", "html5", "mediawiki", "revealjs", "s5", "slideous", "slidy"):
                table[i] = "html"
            elif i in  ("markdown", "markdown_github", "markdown_mmd", "markdown_phpextra", "markdown_strict"):
                table[i] = "md"
            elif i in ("odt", "opendocument"):
                table[i] = "odt"
            elif i == "native":
                table[i] = "hs"
            elif i == "texinfo":
                table[i] = "info"
            elif i == "latex":
                table[i] = "ltx"
            else:
                table[i] = i
        return table

    @staticmethod
    def get_input_formats_table():
        """
        gets a dict with input formats associated to vim filetypes
        """
        table = {}
        for i in PandocHelpParser._get_input_formats():
            if re.match("markdown", i):
                if vim.vars["pantondoc_use_pandoc_markdown"] != 0:
                    table[i] = "pandoc"
                else:
                    if i == "markdown_strict":
                        table[i] = "markdown"
                    else:
                        table[i] = "pandoc"
            # requires wikipeadia.vim
            elif i == "mediawiki":
                table[i] = "Wikipedia"
            elif i == "docbook":
                table[i] = "docbk"
            elif i == "native":
                table[i] = "haskell"
            else:
                table[i] = i
        return table

class PandocCommand(object):
    def __init__(self):
        self.opts = PandocHelpParser()
        self._output_file_path = None
        self._run_command = None
        self._out = None

    def __call__(self, args, should_open):
        # build arguments to pass pandoc

        buffer_bibliographies = vim.eval('b:pantondoc_bibs')
        if len(buffer_bibliographies) < 1:
            buffer_bibliographies = bib.find_bibfiles()
        bib_arg = " ".join(['--bibliography "' + i  + '"' for i in buffer_bibliographies]) if \
                len(buffer_bibliographies) > 0 \
                else ""

        strict_arg = "-r markdown_strict" if \
                vim.current.buffer.options["ft"] == "markdown" and \
                not bool(vim.vars["pantondoc_use_pandoc_markdown"]) \
                else ""

        c_opts, c_args = getopt.gnu_getopt(args.split(), self.opts.shortopts, self.opts.longopts)

        output_format = c_args[0] if len(c_args) > 0 and c_args[0] in PandocHelpParser.get_output_formats_table().keys() else "html"
        output_format_arg = "-t " + output_format if output_format != "pdf" else ""
        self._output_file_path = vim.eval('expand("%:r")') + '.' + PandocHelpParser.get_output_formats_table()[output_format]
        output_arg = '-o "' + self._output_file_path + '"'

        engine_arg = "--latex-engine=" + vim.vars["pantondoc_command_latex_engine"] if output_format in ["pdf", "beamer"] else ""

        extra = []
        for opt in c_opts:
            eq = '=' if opt[1] and re.match('^--', opt[0]) else ''
            # if it begins with ~, it will expand, otherwise, it will just copy
            val = os.path.expanduser(opt[1])
            if os.path.isabs(val) and os.path.exists(val):
                extra.append(opt[0] + (eq or ' ') + '"' + val + '"')
            else:
                extra.append(opt[0] + eq + opt[1])

        extra_args = " ".join(extra)

        input_arg = '"' + vim.eval('expand("%")') + '"'

        self._run_command = " ".join(filter(lambda i: i != "", ["pandoc", \
                                                                bib_arg, \
                                                                strict_arg, \
                                                                output_format_arg, \
                                                                engine_arg, \
                                                                output_arg, \
                                                                extra_args, \
                                                                input_arg]))

        # execute
        self.execute(should_open)

    def execute(self, should_open):
        with open("pandoc.out", 'w') as tmp:
            if vim.bindeval("has('clientserver')"):
                async_runner = os.path.join(os.path.dirname(__file__), "async.py")
                servername_arg = "--servername=" + vim.bindeval("v:servername")
                open_arg  = "--open" if should_open else "--noopen"
                async_command = " ".join([async_runner, servername_arg, open_arg, self._run_command])
                try:
                    pid = Popen(shlex.split(async_command), stdout=tmp, stderr=tmp)
                except:
                    vim.command('echoe "pantondoc: could not execute pandoc asynchronously"')
            else:
                try:
                    com = Popen(shlex.split(self._run_command), stdout=tmp, stderr=tmp)
                    com.wait()
                except:
                    vim.command('echoe "pantondoc: could not execute pandoc"')
                    return

                self.on_done(should_open, com.returncode)

    def on_done(self, should_open, returncode):
        if self._run_command and self._output_file_path:
            if vim.bindeval("g:pantondoc_use_message_buffers") and returncode != '0':
                vim.command("let split = &splitbelow")
                vim.command("set splitbelow")

                vim.command("5new pandoc\ output")
                vim.command("let &splitbelow = split")
                vim.command("setlocal wrap")
                vim.command("setlocal linebreak")
                vim.current.buffer[0] = "# Press <Esc> to close this"
                vim.current.buffer.append("▶ " + self._run_command)
                vim.command("normal! G")
                if vim.bindeval('filereadable("pandoc.out")'):
                    vim.command("silent r pandoc.out")
                vim.command("setlocal buftype=nofile")
                vim.command("setlocal nobuflisted")
                # pressing <esc> on the buffer will delete it
                vim.command("map <buffer> <esc> :bd<cr>")
                # we will highlight some elements in the buffer
                vim.command("syn match PandocOutputMarks /^>>/")
                vim.command("syn match PandocCommand /^▶.*$/hs=s+1")
                vim.command("syn match PandocInstructions /^#.*$/")
                vim.command("hi! link PandocOutputMarks Operator")
                vim.command("hi! link PandocCommand Statement")
                vim.command("hi! link PandocInstructions Comment")

            if os.path.exists("pandoc.out"):
                os.remove("pandoc.out")
            vim.command("echohl Statement")
            vim.command("echom 'pantondoc:execute:" + self._run_command + "'")
            vim.command("echohl None")

            # open file if needed
            if os.path.exists(self._output_file_path) and should_open:
                if sys.platform == "darwin":
                    pandoc_open_command = "open" #OSX
                elif sys.platform.startswith("linux"):
                    pandoc_open_command = "xdg-open" # freedesktop/linux
                elif sys.platform.startswith("win"):
                    pandoc_open_command = 'cmd /c \"start' # Windows
                # On windows, we pass commands as an argument to `start`,
                # which is a cmd.exe builtin, so we have to quote it
                if sys.platform.startswith("win"):
                    pandoc_open_command_tail = '"'
                else:
                    pandoc_open_command_tail = ''

                with open(os.devnull, 'wb') as fnull:
                    pid = Popen([pandoc_open_command,  self._output_file_path + pandoc_open_command_tail], stderr=fnull)

            # we reset this
            self._output_file_path = None
            self._run_command = None

pandoc = PandocCommand()
