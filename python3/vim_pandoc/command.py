# encoding=utf-8

import vim
import re
import sys
import os.path
import argparse
import shlex
from subprocess import Popen, PIPE
from itertools import chain
from vim_pandoc.utils import plugin_enabled_modules, ensure_string
from vim_pandoc.bib.vim_completer import find_bibfiles
from vim_pandoc.helpparser import PandocInfo

class PandocCommand(object):
    def __init__(self):
        self.pandoc_info = PandocInfo(vim.vars["pandoc#command#path"])
        self.formats_table = {}
        self.build_formats_table()
        self._output_file_path = None
        self._run_command = None
        self._out = None

    def build_formats_table(self):
        for i in self.pandoc_info.output_formats:
            if i in ("asciidoc", "plain"):
                self.formats_table[i] = "txt"
            elif i in ("beamer", "pdf"):
                self.formats_table[i] = "pdf"
            elif i in ("dzslides", "html", "html5", "mediawiki", "revealjs", "s5", "slideous", "slidy"):
                self.formats_table[i] = "html"
            elif i in  ("markdown", "gfm", "markdown_github", "markdown_mmd", "markdown_phpextra", "markdown_strict"):
                self.formats_table[i] = "md"
            elif i in ("odt", "opendocument"):
                self.formats_table[i] = "odt"
            elif i == "native":
                self.formats_table[i] = "hs"
            elif i == "texinfo":
                self.formats_table[i] = "info"
            elif i == "latex":
                self.formats_table[i] = "tex"
            else:
                self.formats_table[i] = i
        if "latex" in self.formats_table or "beamer" in self.formats_table and "pdf" not in self.formats_table:
            self.formats_table["pdf"] = "pdf"

    def __call__(self, args, should_open):
        largs = shlex.split(args)
        if largs == [] or largs[0].startswith('-'):
            largs = ['html'] + largs # make sure we pass an output format
        p = self.pandoc_info.build_argument_parser()
        c_vars = vars(p.parse_args(largs))

        # Infer arguments from vim environment

        # a) bibliographies
        if 'bibliographies' in plugin_enabled_modules():
            local_bibs = vim.eval('b:pandoc_biblio_bibs')
            found_bibs = find_bibfiles()
            if local_bibs or found_bibs and not c_vars['bibliography']:
                c_vars['bibliography'] = []
            if local_bibs:
                c_vars['bibliography'].extend(local_bibs)
            if found_bibs:
                c_vars['bibliography'].extend(found_bibs)

        # Now, we must determine what are our input and output files

        # a) First, let's see what is the desired output format...
        output_format = c_vars['output_format'] \
            if self.pandoc_info.is_valid_output_format(c_vars['output_format']) \
            or c_vars['output_format'] == 'pdf' \
            else "html"
        # overwrite --to with this value
        # 'pdf' is not a valid output format, we pass it to -o instead)
        if output_format != 'pdf':
            c_vars['to'] = output_format
        else:
            c_vars['to'] = 'latex'

        if output_format == 'pdf':
            # pdf engine
            if self.pandoc_info.version >= '2':
                engine_option = 'pdf_engine'
            else:
                engine_option = 'latex_engine'
            if not c_vars[engine_option]:
                try: # try a buffer local engine
                    engine_var = ensure_string(vim.current.buffer.vars['pandoc_command_latex_engine'])
                except: # use te global value
                    engine_var = ensure_string(vim.vars['pandoc#command#latex_engine'])
                c_vars[engine_option] = str(engine_var)

        if not c_vars['output']:
            self._output_file_path = vim.eval('expand("%:r")') + '.' \
                + self.formats_table[re.split("[-+]", output_format)[0]]
            c_vars['output'] = self._output_file_path
        else:
            self._output_file_path = os.path.expanduser(c_vars['output'][0])

        input_arg = '"' + vim.eval('expand("%")') + '"'

        # Now, we reconstruct the pandoc call
        arglist = []
        arglist.append(ensure_string(vim.vars['pandoc#compiler#command']))
        arglist.append(ensure_string(vim.vars['pandoc#compiler#arguments']))
        # Only consider enabled flags and arguments with values
        extra_arg_vars_keys = [k for k in c_vars.keys() if c_vars[k] and k != 'output_format']
        for var in extra_arg_vars_keys:
            real_var = var.replace("_", "-")
            val = c_vars[var]
            if type(val) == list and len(val) > 1: # multiple values, repeat keys
                for vv in val:
                    if type(vv) == list and type(vv[0]) == list:
                        vv = vv[0][0]
                    elif type(vv) == list:
                        vv = vv[0]
                    elif type(val) == bool:
                        vv = None
                    if vv:
                        vv = os.path.expanduser(vv)
                        arglist.append("--" + real_var + '="' + str(vv) + '"')
                    else:
                        arglist.append("--" + real_var)
            else:
                if type(val) == list and type(val[0]) == list:
                    val = val[0][0]
                elif type(val) == list:
                    val = val[0]
                elif type(val) == bool:
                    val = None
                if val:
                    val = os.path.expanduser(val)
                    arglist.append('--' + real_var + '="' + str(val) + '"')
                else:
                    arglist.append('--' + real_var)
        arglist.append(input_arg)

        self._run_command = " ".join(arglist)
        # execute
        self.execute(should_open)

    def execute(self, should_open):
        with open("pandoc.out", 'w') as tmp:

            # for nvim
            if vim.eval("has('nvim')") == '1':
                try:
                    should_open_s = str(int(should_open))
                except:
                    should_open_s = '0'

                if int(vim.eval("bufloaded('pandoc-execute')")):
                    wnr = vim.eval("bufwinnr('pandoc-execute')")
                    vim.command(wnr + "wincmd c")

                vim.command("botright 7new pandoc-execute")
                vim.command("setlocal buftype=nofile")
                vim.command("setlocal bufhidden=wipe")
                vim.command("setlocal nobuflisted")
                vim.command("map <buffer> q <Esc>:close<Enter>")
                vim.command("call termopen(" + \
                            "['"+ "','".join(shlex.split(self._run_command)) + "'], " + \
                            " extend({'should_open': '" + should_open_s + "'}," +\
                            " {'on_exit': 'pandoc#command#JobHandler'," + \
                            "'on_stdout': 'pandoc#command#JobHandler'," + \
                            "'on_stderr': 'pandoc#command#JobHandler'}))")
                vim.command("file pandoc-execute")
                vim.command("normal G")
                vim.command("wincmd p")

            # for vim versions with clientserver support
            elif vim.eval("has('clientserver')") == '1' and \
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

            else:
                try: # fallback to synchronous execution
                    com = Popen(shlex.split(self._run_command), stdout=tmp, stderr=tmp)
                    com.wait()
                except:
                    vim.command('echoe "vim-pandoc: could not execute pandoc"')
                    return

                self.on_done(should_open, com.returncode)

    def on_done(self, should_open, returncode):
        if self._run_command and self._output_file_path:
            vim.command("echohl Statement")
            vim.command("echom strftime('%Y%m%d %T') . ' vim-pandoc:ran " + self._run_command + "'")
            vim.command("echohl None")

            if vim.eval("g:pandoc#command#use_message_buffers") == '1' \
                    and returncode not in  ('0', 0):
                vim.command("let split = &splitbelow")
                vim.command("set splitbelow")

                vim.command("5new pandoc\ output")
                vim.command("let &splitbelow = split")
                vim.command("setlocal wrap")
                vim.command("setlocal linebreak")
                vim.current.buffer[0] = "# Press q to close this"
                vim.current.buffer.append("> " + self._run_command)
                vim.command("normal! G")
                if vim.eval('filereadable("pandoc.out")') == '1':
                    vim.command("silent r pandoc.out")
                vim.command("setlocal buftype=nofile")
                vim.command("setlocal nobuflisted")
                # pressing q on the buffer will delete it
                vim.command("map <buffer> q :bwipeout<cr>")
                # we will highlight some elements in the buffer
                vim.command("syn match PandocOutputMarks /^>>/")
                vim.command("syn match PandocCommand /^>.*$/hs=s+1")
                vim.command("syn match PandocInstructions /^#.*$/")
                vim.command("hi! link PandocOutputMarks Operator")
                vim.command("hi! link PandocCommand Debug")
                vim.command("hi! link PandocInstructions Comment")

            # under windows, pandoc.out is not closed by async.py in time sometimes,
            # so we wait a bit
            if sys.platform.startswith("win"):
                from time import sleep
                sleep(1)
            if os.path.exists("pandoc.out"):
                os.remove("pandoc.out")

            # open file if needed

            # nvim's python host doesn't change the directory the same way vim does
            try:
                if vim.eval('has("nvim")') == '1':
                    os.chdir(vim.eval('getcwd()'))
            except:
                pass

            if vim.eval("g:pandoc#command#prefer_pdf") == "1":
                maybe_pdf = os.path.splitext(self._output_file_path)[0] + ".pdf"
                if os.path.splitext(self._output_file_path)[1] in [".tex", "*.latex"] \
                    and os.path.exists(maybe_pdf):
                        self._output_file_path = maybe_pdf

            if os.path.exists(os.path.abspath(self._output_file_path)) and should_open:
                # if g:pandoc#command#custom_open is defined and is a valid funcref
                if vim.eval("g:pandoc#command#custom_open") != "" \
                   and vim.eval("exists('*"+vim.eval("g:pandoc#command#custom_open")+"')") == '1':

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
