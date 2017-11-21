import vim

from vim_pandoc.bib.util import make_title_ascii, dict_to_info
from vim_pandoc.bib.collator import SourceCollator
from vim_pandoc.bib.citeproc import CiteprocCollator
from vim_pandoc.bib.fallback import FallbackCollator

def find_bibfiles():
    """
    Returns list of available bibliographies, using the generic collator.
    """
    args = { "fname" : vim.current.buffer.name,
        "sources" : vim.eval("g:pandoc#biblio#sources"),
        "extra_sources" : (vim.eval("g:pandoc#biblio#bibs"), vim.eval("b:pandoc_biblio_bibs")) }
    collator = SourceCollator(**args)
    return collator.find_bibfiles()

class VimCompleter(object):
    def parse_suggestions(self, data):
        """
        Turns the output of the collators get_suggestions() methods into a dict
        like what vim completion functions use.

        """
        vim_suggestions = []
        for item in data:
            item_base = {"word": item['id'], "menu": make_title_ascii(item['title'])}
            if bool(int(vim.eval('g:pandoc#completion#bib#use_preview'))):
                item_base['info'] = dict_to_info(item)
            vim_suggestions.append(item_base)
        return vim_suggestions

    def get_suggestions(self, query):
        """
        Returns a dict with the suggestions available for the given query.
        """
        query = query.strip() # spaces around the query shouldn't be significant

        mode = vim.eval("g:pandoc#completion#bib#mode")
        args = { "fname" : vim.current.buffer.name,
                 "query": query,
                 "sources" : vim.eval("g:pandoc#biblio#sources"),
                 "extra_sources" : (vim.eval("g:pandoc#biblio#bibs"), vim.eval("b:pandoc_biblio_bibs")) }

        if mode == "citeproc":
            collator = CiteprocCollator(**args)
            return self.parse_suggestions(collator.collate())
        elif mode == "fallback":
            collator = FallbackCollator(use_bibtool=bool(int(vim.eval("g:pandoc#biblio#use_bibtool"))), **args)
            # fallback methods output the correct data, so we don't need to parse.
            # NOTE: this will change in the future, so the completion backend
            # is frontend-agnostic.
            return collator.collate()

