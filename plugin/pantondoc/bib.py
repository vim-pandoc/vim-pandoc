import vim
import os
import os.path
from glob import glob
import subprocess as sp

bib_extensions = ["json", "ris", "mods", "biblatex", "bib"]

def find_bibfiles():
    if vim.current.buffer.name != None:
        file_name = ".".join(os.path.relpath(vim.current.buffer.name).split(".")[:-1])

        # first, we check for files named after the current file in the current dir
        bibfiles = [f for f in glob(file_name + ".*") if f.split(".")[-1] in bib_extensions]
    else:
        bibfiles = []

    # we search for any bibliography in the current dir
    if bibfiles == []:
        bibfiles = [f for f in glob("*.*") if f.split(".")[-1] in bib_extensions]

    # we search in pandoc's local data dir
    if bibfiles == []:
        b = ""
        if os.path.exists(os.path.expandvars("$HOME/.pandoc/")):
            b = os.path.expandvars("$HOME/.pandoc/")
        elif os.path.exists(os.path.expandvars("%APPDATA%/pandoc/")):
            b = os.path.expandvars("%APPDATA%/pandoc/")
        if b != "":
            bibfiles = [f for f in glob(b + "default.*") if f.split(".")[-1] in bib_extensions]

    # we search for bibliographies in texmf
    if bibfiles == [] and vim.eval("executable('kpsewhich')") != '0':
        texmf = sp.Popen(["kpsewhich", "-var-value", "TEXMFHOME"], stdout=sp.PIPE, stderr=sp.PIPE).\
                    communicate()[0].strip()
        if os.path.exists(texmf):
            bibfiles = [f for f in glob(texmf + "/*") if f.split(".")[-1] in bib_extensions]

    # we append the items in g:pandoc_bibfiles, if set
    if vim.eval("exists('g:pantondoc_bibfiles')") != "0":
        bibfiles.extend(vim.eval("g:pantondoc_bibfiles"))

    # we check if the items in bibfiles are readable and not directories
    bibfiles = list(filter(lambda f : os.access(f, os.R_OK) and not os.path.isdir(f), bibfiles))

    vim.command("return " + str(bibfiles))


