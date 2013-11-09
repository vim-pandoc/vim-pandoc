# encoding=utf-8

import vim
import re
import sys
import os.path
import getopt
import shlex
from subprocess import Popen, PIPE

output_extensions = {
    "asciidoc": "txt",
    "beamer": "pdf",
    "docx": "docx",
    "dzslides": "html",
    "epub": "epub",
    "epub3": "epub3",
    "fb2": "fb2",
    "html"  : "html",
    "html5" : "html",
    "latex" : "ltx",
    "man": "man",
    "markdown" : "md",
    "markdown_github" : "md",
    "markdown_mmd" : "md",
    "markdown_phpextra" : "md",
    "markdown_strict" : "md",
    "mediawiki": "html",
    "native": "hs",
    "odt":  "odt",
    "opendocument": "odt",
    "opml": "opml",
    "org":  "org",
    "pdf": "pdf",
    "plain": "txt",
    "revealjs": "html",
    "rtf":  "rtf",
    "s5": "html",
    "slideous": "html",
    "slidy": "html",
    "texinfo": "info",
    "textile": "txt",
}

class PandocHelpParser(object):
    def __init__(self):
        self.help_data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        self.longopts = self.get_longopts()
        self.shortopts = self.get_shortopts()

    def get_longopts(self):
        return map(lambda i: i.replace("--", ""), \
                   filter(lambda i: i not in ("--version", "--help", "--to", "--write"), \
                          [ i.group() for i in re.finditer("-(-\w+)+", self.help_data)]))

    def get_shortopts(self):
        no_args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-v ", "-h "), \
                             [i.group() for i in re.finditer("-\w\s(?!\w+)", self.help_data)]))

        # -m doesn't comply with the format of the other short options in pandoc 1.12
        # if you need to pass an URL, use the long versions
        no_args.append("m")

        args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-t ", "-w "), \
                             [i.group() for i in re.finditer("-\w\s(?=[A-Z]+)", self.help_data)]))


        return "".join(no_args) + "".join(map(lambda i: i + ":", args))

class PandocCommand(object):
    def __init__(self):
        self.opts = PandocHelpParser()

    def __call__(self, args, should_open):
        # build arguments to pass pandoc
        buffer_bibliographies = vim.eval('b:pantondoc_bibs')
        bib_arg = " ".join(['--bibliography "' + i  + '"' for i in buffer_bibliographies]) if \
                len(buffer_bibliographies) > 0 \
                else ""

        strict_arg = "--strict" if \
                vim.current.buffer.options["ft"] == "markdown" and \
                not bool(vim.vars["pantondoc_use_pandoc_markdown"]) \
                else ""

        try:
            c_opts, c_args = getopt.gnu_getopt(args.split(), self.opts.shortopts, self.opts.longopts)
        except getopt.GetoptError:
            c_args = []
            c_opts = []

        output_format = c_args[0] if len(c_args) > 0 and c_args[0] in output_extensions.keys() else "html"
        output_format_arg = "-t " + output_format if output_format != "pdf" else ""
        output_file_path = vim.eval('expand("%:r")') + '.' + output_extensions[output_format]
        output_arg = '-o "' + output_file_path + '"'

        engine_arg = "--latex-engine=" + vim.vars["pantondoc_command_latex_engine"] if output_format in ["pdf", "beamer"] else ""

        extra_args = " ".join([opt[0] +  opt[1] for opt in c_opts])

        input_arg = '"' + vim.eval('expand("%")') + '"'

        run_command = " ".join(filter(lambda i: i != "", ["pandoc", \
                                                  bib_arg, \
                                                  strict_arg, \
                                                  output_format_arg, \
                                                  engine_arg, \
                                                  output_arg, \
                                                  extra_args, \
                                                  input_arg]))

        # execute
        try:
            out, err = Popen(shlex.split(run_command), stdout=PIPE, stderr=PIPE).communicate()
        except:
            vim.command('echoe "pantondoc: could not execute pandoc"')
            return

        if bool(vim.vars["pantondoc_use_message_buffers"]):
            vim.command("setlocal splitbelow")

            vim.command("5new")
            vim.current.buffer[0] = "# Press <Esc> to close this"
            vim.current.buffer.append("▶ " + run_command)
            try:
                for line in out.split("\n"):
                    vim.current.buffer.append("out: " + line)
                for line in err.split("\n"):
                    vim.current.buffer.append("ERROR: " + line)
            except:
                pass
            vim.command("setlocal nomodified")
            vim.command("setlocal nomodifiable")
            # pressing <esc> on the buffer will delete it
            vim.command("map <buffer> <esc> :bd<cr>")
            # we will highlight some elements in the buffer
            vim.command("syn match PandocOutputMarks /^>>/")
            vim.command("syn match PandocCommand /^▶.*$/hs=s+1")
            vim.command("syn match PandocInstructions /^#.*$/")
            vim.command("hi! link PandocOutputMarks Operator")
            vim.command("hi! link PandocCommand Statement")
            vim.command("hi! link PandocInstructions Comment")
        print("pantondoc: ran " + run_command)

        # open file if needed
        if os.path.exists(output_file_path) and should_open:
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

            Popen([pandoc_open_command,  output_file_path + pandoc_open_command_tail])

pandoc = PandocCommand()
