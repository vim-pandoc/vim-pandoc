import os
import vim
from glob import glob
from itertools import chain
from subprocess import check_output

bib_extensions = ["bib",
                    "bibtex",
                    "ris",
                    "json",
                    "enl",
                    "wos",
                    "medline",
                    "copac",
                    "xml"]


class SourceCollator():
    def __init__(self, fname=None, query=None, sources="bcg", extra_sources=([], []), **extra_args):
        # nvim's python host doesn't change the directory the same way vim does
        if vim.eval('has("nvim")') == '1':
            os.chdir(vim.eval('expand("%:p:h")'))
        self.fname = fname
        self.query = query
        self.sources = sources
        self.extra_sources = extra_sources
        self.extra_args = extra_args

    def find_bibfiles(self):
        def curdir_by_name_search():
            """
            Search for bibiographies with the same name as the current file in the
            current dir.
            """

            if self.fname in (None, ""): return []

            file_name_prefix = os.path.splitext(self.fname)[0]
            search_paths = [file_name_prefix + "." + f for f in bib_extensions]

            bibfiles = [os.path.abspath(f) for f in search_paths if os.path.exists(f)]
            return bibfiles

        def curdir_all_search():
            """
            Search for any other bibliographies in the current dir.
            Note: This does not stop bibliographies picked up in b_search() from being found.
            """

            relative_bibfiles = []
            for ext in bib_extensions:
                relative_bibfiles.extend(glob("*."+ext))
            bibfiles = [os.path.abspath(f) for f in relative_bibfiles]
            return bibfiles

        def pandoc_local_search():
            """
            Search for bibliographies in the pandoc data dirs.
            """

            if os.path.exists(os.path.expandvars("$HOME/.pandoc/")):
                b = os.path.expandvars("$HOME/.pandoc/")
            elif os.path.exists(os.path.expandvars("%APPDATA%/pandoc/")):
                b = os.path.expandvars("%APPDATA%/pandoc/")
            else:
                return []

            search_paths = [b + "default." + f for f in bib_extensions]
            bibfiles = [os.path.abspath(f) for f in search_paths if os.path.exists(f)]
            return bibfiles

        def texmf_search():
            """
            Search for bibliographies in the texmf data dirs.
            """

            texmf = check_output(["kpsewhich", "-var-value", "TEXMFHOME"]).rstrip()

            if os.path.exists(texmf):
                search_paths = (texmf.decode() + "/**/*." + f for f in bib_extensions)
                relative_bibfiles = (glob(f, recursive=True) for f in search_paths)
                bibfiles = [os.path.abspath(f) for f in chain.from_iterable(relative_bibfiles)]
                return bibfiles

            return []

        def explicit_global_search():
            """
            Add bibliographies defined in pandoc#biblio#bibs,
            passed to the collator through the extra_sources argument
            """

            return self.extra_sources[0]

        search_methods = {"b": curdir_by_name_search,
                          "c": curdir_all_search,
                          "l": pandoc_local_search,
                          "t": texmf_search,
                          "g": explicit_global_search}


        bibfiles = []
        for f in self.sources:
            bibfiles.extend(search_methods.get(f, list)())
        # add buffer-local bibliographies, defined in b:pandoc_biblio_bibs,
        # passed to the collator through the extra_sources argument
        bibfiles.extend(self.extra_sources[1])

        # check if the items in bibfiles are readable and not directories
        # also, ensure items are unique
        if bibfiles != []:
            bibfiles = list(set(filter(lambda f : os.access(f, os.R_OK) and not os.path.isdir(f), bibfiles)))

        return bibfiles

    def collate(self):
        """
        Retrieves the data from the sources.
        Should be overriden by sub-classes.
        """
        pass

