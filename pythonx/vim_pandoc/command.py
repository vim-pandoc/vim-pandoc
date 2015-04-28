# encoding=utf-8

import vim
import re
import sys
import os.path
import getopt
import shlex
from subprocess import Popen, PIPE
from vim_pandoc.utils import plugin_enabled_modules
from vim_pandoc.bib.vim_completer import find_bibfiles

markdown_extensions = [
        "escaped_line_breaks",
        "blank_before_header",
        "header_attributes",
        "auto_identifiers",
        "implicit_header_references",
        "blank_before_blockquote",
        "fenced_code_blocks",
        "fenced_code_attributes",
        "line_blocks",
        "fancy_lists",
        "startnum",
        "definition_lists",
        "example_lists",
        "table_captions",
        "simple_tables",
        "multiline_tables",
        "grid_tables",
        "pipe_tables",
        "pandoc_title_block",
        "yaml_metadata_block",
        "all_symbols_escapable",
        "intraword_underscores",
        "strikeout",
        "superscript",
        "subscript",
        "inline_code_attributes",
        "tex_math_dollars",
        "raw_html",
        "markdown_in_html_blocks",
        "native_divs",
        "native_spans",
        "raw_tex",
        "latex_macros",
        "footnotes",
        "citations",
        # non-pandoc
        "lists_without_preceding_blankline",
        "hard_line_breaks",
        "ignore_line_breaks",
        "tex_math_single_backlash",
        "tex_math_double_backlash",
        "markdown_attribute",
        "mmd_title_block",
        "abbreviations",
        "autolink_bare_uris",
        "ascii_identifiers",
        "link_attributes",
        "mmd_header_identifiers",
        "compact_definition_lists"
        ]

class PandocHelpParser(object):
    def __init__(self):
        self._help_data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        self.longopts = PandocHelpParser.get_longopts()
        self.shortopts = PandocHelpParser.get_shortopts()

    @staticmethod
    def get_longopts():
        data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        return map(lambda i: i.replace("--", ""), \
                   filter(lambda i: i not in ("--version", "--help", "--to", "--write"), \
                          [ i.group() for i in re.finditer("-(-\w+)+=?", data)]))

    @staticmethod
    def get_shortopts():
        data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        no_args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-v ", "-h "), \
                             [i.group() for i in re.finditer("-\w\s(?!\w+)", data)]))

        # -m doesn't comply with the format of the other short options in pandoc 1.12
        # if you need to pass an URL, use the long versions
        no_args.append("m")

        args = map(lambda i: i.replace("-", "").strip(), \
                      filter(lambda i: i not in ("-t ", "-w "), \
                             [i.group() for i in re.finditer("-\w\s(?=[A-Z]+)", data)]))


        return "".join(no_args) + "".join(map(lambda i: i + ":", args))

    @staticmethod
    def _get_formats():
        # pandoc's output changes depending on platform
        if sys.platform == "win32":
            splitter = '\r\n'
        else:
            splitter = '\n'
        data = Popen(["pandoc", "--help"], stdout=PIPE).communicate()[0]
        return " ".join(re.findall('(\w+\**[,'+splitter+'])+', data)).split(splitter[0])[:2]

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
                table[i] = "tex"
            else:
                table[i] = i
        if "latex" in table or "beamer" in table and "pdf" not in table:
            table["pdf"] = "pdf"
        return table

    @staticmethod
    def get_input_formats_table():
        """
        gets a dict with input formats associated to vim filetypes
        """
        table = {}
        for i in PandocHelpParser._get_input_formats():
            if re.match("markdown", i):
                if vim.vars["pandoc#filetypes#pandoc_markdown"] != 0:
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

    @staticmethod
    def in_allowed_formats(identifier):
        if not identifier.startswith("markdown") and identifier in PandocHelpParser.get_output_formats_table():
            return True
        elif identifier.startswith("markdown"):
            return re.match(identifier+"(([+-]("+"|".join(markdown_extensions)+"))+)?$",identifier)
        return False

class PandocCommand(object):
    def __init__(self):
        self.opts = PandocHelpParser()
        self._output_file_path = None
        self._run_command = None
        self._out = None

    def __call__(self, args, should_open):
        # build arguments to pass pandoc

        if 'bibliographies' in plugin_enabled_modules():
            buffer_bibliographies = vim.eval('b:pandoc_biblio_bibs')
            if len(buffer_bibliographies) < 1:
                buffer_bibliographies = find_bibfiles()
            bib_arg = " ".join(['--bibliography "' + i  + '"' for i in buffer_bibliographies]) if \
                    len(buffer_bibliographies) > 0 \
                    else ""
        else:
            bib_arg = ""

        strict_arg = "-r markdown_strict" if \
                vim.current.buffer.options["ft"] == "markdown" and \
                not bool(vim.vars["pandoc#filetypes#pandoc_markdown"]) \
                else ""

        c_opts, c_args = getopt.gnu_getopt(shlex.split(args), self.opts.shortopts, self.opts.longopts)
        def wrap_args(i):
            if re.search('=', i[1]):
                return (i[0], re.sub('$', '"', re.sub('(.*)=', '\\1="', i[1])))
            else:
                return (i[0], i[1])
        c_opts = [wrap_args(i) for i in c_opts]

        output_format = c_args.pop(0) if len(c_args) > 0 and self.opts.in_allowed_formats(c_args[0]) else "html"
        output_format_arg = "-t " + output_format if output_format != "pdf" else ""
        
        def no_extensions(fmt):
            return re.split("[-+]", fmt)[0]

        self._output_file_path = vim.eval('expand("%:r")') + '.' + self.opts.get_output_formats_table()[no_extensions(output_format)]
        output_arg = '-o "' + self._output_file_path + '"'

        engine_arg = "--latex-engine=" + vim.vars["pandoc#command#latex_engine"] if output_format in ["pdf", "beamer"] else ""

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

        extra_input_args = '"' + '" "'.join(c_args) + '"' if len(c_args) > 0 else ""

        input_arg = '"' + vim.eval('expand("%")') + '"'

        self._run_command = " ".join(filter(lambda i: i != "", ["pandoc", \
                                                                bib_arg, \
                                                                strict_arg, \
                                                                output_format_arg, \
                                                                engine_arg, \
                                                                output_arg, \
                                                                extra_args, \
                                                                extra_input_args, \
                                                                input_arg]))

        # execute
        self.execute(should_open)

    def execute(self, should_open):
        with open("pandoc.out", 'w') as tmp:
            if vim.eval("has('clientserver')") == '1' and \
               vim.eval("v:servername") != "" and \
               vim.eval("executable('python')") == '1':
                async_runner = '"' + os.path.join(os.path.dirname(__file__), "async.py") + '"'
                servername_arg = "--servername=" + vim.eval("v:servername")
                open_arg  = "--open" if should_open else "--noopen"
                async_command = " ".join(["python", async_runner, servername_arg, open_arg, self._run_command])
                try:
                    Popen(shlex.split(async_command), stdout=tmp, stderr=tmp)
                except:
                    vim.command('echoe "vim-pandoc: could not execute pandoc asynchronously"')
            elif vim.eval("has('nvim')") == '1':
                vim.command("call jobstart("+ \
                        str(['pandoc'] + shlex.split(self._run_command)[1:]) + \
                                ", extend({'should_open': '" + str(int(should_open)) + \
                                "'}, {'on_exit': 'pandoc#command#JobHandler'}))")
                #vim.command('call jobstart(["pandoc", ' + str(shlex.split(self._run_command)[1:]) + '])')
            else:
                try:
                    com = Popen(shlex.split(self._run_command), stdout=tmp, stderr=tmp)
                    com.wait()
                except:
                    vim.command('echoe "vim-pandoc: could not execute pandoc"')
                    return

                self.on_done(should_open, com.returncode)

    def on_done(self, should_open, returncode):
        if self._run_command and self._output_file_path:
            vim.command("echohl Statement")
            vim.command("echom 'vim-pandoc:ran:" + self._run_command + "'")
            vim.command("echohl None")

            if vim.eval("g:pandoc#command#use_message_buffers") == '1' and returncode not in  ('0', 0):
                vim.command("let split = &splitbelow")
                vim.command("set splitbelow")

                vim.command("5new pandoc\ output")
                vim.command("let &splitbelow = split")
                vim.command("setlocal wrap")
                vim.command("setlocal linebreak")
                vim.current.buffer[0] = "# Press q to close this"
                vim.current.buffer.append("▶ " + self._run_command)
                vim.command("normal! G")
                if vim.eval('filereadable("pandoc.out")') == '1':
                    vim.command("silent r pandoc.out")
                vim.command("setlocal buftype=nofile")
                vim.command("setlocal nobuflisted")
                # pressing q on the buffer will delete it
                vim.command("map <buffer> q :bd<cr>")
                # we will highlight some elements in the buffer
                vim.command("syn match PandocOutputMarks /^>>/")
                vim.command("syn match PandocCommand /^▶.*$/hs=s+1")
                vim.command("syn match PandocInstructions /^#.*$/")
                vim.command("hi! link PandocOutputMarks Operator")
                vim.command("hi! link PandocCommand Statement")
                vim.command("hi! link PandocInstructions Comment")

            # under windows, pandoc.out is not closed by async.py in time sometimes,
            # so we wait a bit
            if sys.platform.startswith("win"):
                from time import sleep
                sleep(1)
            if os.path.exists("pandoc.out"):
                os.remove("pandoc.out")

            # open file if needed
            if os.path.exists(self._output_file_path) and should_open:
                # if g:pandoc#command#custom_open is defined and is a valid funcref
                if vim.eval("g:pandoc#command#custom_open") != "" \
                        and vim.eval("exists('*"+vim.eval("g:pandoc#command#custom_open")+"')") == 1:

                    custom_command = vim.eval(vim.eval("g:pandoc#command#custom_open") \
                                              + "('"+self._output_file_path+"')")
                    Popen(shlex.split(custom_command))

                # otherwise use platform defaults:
                else:
                    if sys.platform == "darwin" or sys.platform.startswith("linux"):
                        if sys.platform == "darwin":
                            open_command = "open" #OSX
                        elif sys.platform.startswith("linux"):
                            open_command = "xdg-open" # freedesktop/linux

                        with open(os.devnull, 'wb') as fnull:
                            Popen([open_command,  self._output_file_path], stderr=fnull)

                    elif sys.platform.startswith("win"):
                        Popen('cmd /c "start ' + self._output_file_path + '"')

            # we reset this
            self._output_file_path = None
            self._run_command = None
            vim.command("redraw")
            if returncode in ("0", 0):
                vim.command("echohl Statement")
                vim.command("echom 'vim-pandoc:ran successfully.'")
                vim.command("echohl None")


pandoc = PandocCommand()
