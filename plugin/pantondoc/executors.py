# encoding=utf-8

import vim
import sys, os.path
import re
import shlex
import subprocess as sp
from pantondoc.utils import ex, plugin_path
import pantondoc.pandoc

pantondoc_executors = set()

class Executor(object):
    __slots__ = "name", "mapping", "type", "command"

    def __init__(self, ref):
        vals = ref.split()
        self.name = vals[0]
        self.mapping = vals[1]
        self.type = vals[2]
        self.command = vals[3:]

    def __str__(self):
        return " ".join([self.name, self.mapping, self.type, " ".join(self.command)])

def register_executor(executor, user=True):
    if executor.__class__ == str:
        executor = Executor(executor)
    if user and executor not in pantondoc_executors and vim.eval("g:pantondoc_executors_save_new") == '1':
        try:
            #add a reference string to /plugin/pantondoc/executors/user
            with open(plugin_path() + "/plugin/pantondoc/executors/user", "a") as ofile:
                ofile.write(str(executor) + "\n")
        except:
            pass
    pantondoc_executors.add(executor)

def register_from_cache():
    version = ".".join(pantondoc.pandoc.PandocInfo().mayor_version)
    for path in (version, "user"):
        try:
            with open(plugin_path() + "/plugin/pantondoc/executors/" + path) as ifile:
                executors = filter(lambda i: i.strip(), ifile.readlines())
                map(lambda i: register_executor(i, False), executors)
        except:
            pass

def create_executors():
    not_empty = lambda val : val not in ("", "None", None)
    for executor in filter(not_empty, pantondoc_executors):
        _executor = 'call pantondoc_executors#Execute("' + \
                    " ".join(executor.command) + '", "' \
                    + executor.type + '", "<bang>")'
        if not_empty(executor.name):
			ex("command!","-buffer", "-bang", executor.name, "exec '" + _executor + "'")
        if not_empty(executor.mapping):
            ex("map","<buffer><silent>", executor.mapping, ":" + _executor + "<cr>")

variable_substitutions = {
	# the values in b:pandoc_bibfiles, as arguments for a pandoc-compatible program
    "#PANDOC-BIBS" : lambda m: " ".join(["--bibliography "+ i for i in vim.eval('b:pantondoc_bibfiles')]) \
            if vim.eval('exists("b:pantondoc_bibfiles")') == '1' else "",
	# the values in b:pandoc_bibfiles, as a list
    "#BIBS" : lambda m: " ".join(vim.eval("b:pantondoc_bibfiles")) \
            if vim.eval('exists("b:pantondoc_bibfiles")') == '1' else "",
    # wether to use --strict for markdown files
    "#STRICT" : lambda m: "--strict" \
            if vim.eval("&ft") == "markdown" and vim.eval("g:pantondoc_use_pandoc_markdown") == '0' else "",
    "#PANDOC-LATEX-ENGINE" : lambda m: vim.eval("g:pantondoc_executors_latex_engine")
}

def execute(command, output_type="html", open_when_done=False):
    # first, we parse the command description as a list of strings
    steps = []
    for step in command.split("|"):
        step = step.strip()
        # we expand some values using vim's expand function.
        # check :help filename-modifiers
        step = re.sub("%<?((:[8~.hpret])?)*", lambda i: vim.eval('expand("' + i.group() + '")'), step)
        # we substitute some variables
        for sub in variable_substitutions:
            step = re.sub(sub, variable_substitutions[sub], step)
        steps.append(step)

    out = os.path.splitext(vim.current.buffer.name)[0] + "." + output_type

    # now, we run the pipe
    procs = {}
    procs[0] = sp.Popen(shlex.split(steps[0]), stdout=sp.PIPE)
    if len(steps) > 1:
        i = 1
        for p in steps[1:]:
            procs[i] = sp.Popen(shlex.split(p), stdin=procs[i-1].stdout, stdout=sp.PIPE)
            procs[i-1].stdout.close()
    output = procs[len(procs) - 1].communicate()[0]

    # we create a temporary buffer where the command and its output will be shown

    # we always splitbelow
    splitbelow = bool(int(vim.eval("&splitbelow")))
    if not splitbelow:
        ex("set splitbelow")

    ex("5new")
    vim.current.buffer[0] = "# Press <Esc> to close this"
    vim.current.buffer.append("▶ " + " | ".join(steps))
    try:
        for line in output.split("\n"):
            vim.current.buffer.append(line)
    except:
        pass
    ex("setlocal nomodified")
    ex("setlocal nomodifiable")
    # pressing <esc> on the buffer will delete it
    ex("map <buffer> <esc> :bd<cr>")
    # we will highlight some elements in the buffer
    ex("syn match PandocOutputMarks /^>>/")
    ex("syn match PandocCommand /^▶.*$/hs=s+1")
    ex("syn match PandocInstructions /^#.*$/")
    ex("hi! link PandocOutputMarks Operator")
    ex("hi! link PandocCommand Statement")
    ex("hi! link PandocInstructions Comment")

    # we revert splitbelow to its original value
    if not splitbelow:
        ex("set nosplitbelow")

    # finally, we open the created file
    if os.path.exists(out) and open_when_done:
        if sys.platform == "darwin":
            pandoc_open_command = "open" #OSX
        elif sys.platform.startswith("linux"):
            pandoc_open_command = "xdg-open" # freedesktop/linux
        elif sys.platform.startswith("win"):
            pandoc_open_command = 'cmd /x \"start' # Windows
        # On windows, we pass commands as an argument to `start`,
        # which is a cmd.exe builtin, so we have to quote it
        if sys.platform.startswith("win"):
            pandoc_open_command_tail = '"'
        else:
            pandoc_open_command_tail = ''

        sp.Popen([pandoc_open_command,  out + pandoc_open_command_tail], stdout=sp.PIPE, stderr=sp.PIPE)
