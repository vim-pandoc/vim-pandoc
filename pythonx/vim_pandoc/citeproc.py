#!/usr/bin/env python2

import sys
import os
from subprocess import check_output
import json
from glob import glob
import re

_bib_extensions = ["bib",\
                   "bibtex",\
                   "ris",\
                   "mods",\
                   "json",\
                   "enl",\
                   "wos",\
                   "medline",\
                   "copac",\
                   "xml"]

_significant_tags = ["id",\
                     "author",\
                     "issued",\
                     "title",\
                     "publisher",\
                     "abstract"]
class CSLItem:
    # This class implements various helper methods for CSL-JSON formatted bibliography
    # entries.
    def __init__(self, entry):
        self.data = entry

    def citekey(self):
        return self.data["id"]

    def as_array(self, variable_name):
        def plain(variable_contents):
            # Takes the contents of a 'plain' variable and splits it into an array.
            return variable_contents.split()
    
        def number(variable_contents):
            # Per 
            return [variable_contents]
    
        def name(variable_contents):
            # Currently a placeholder. Will parse 'name' CSL variables and return an array of
            # strings for matches.
            return []
    
        def date(variable_contents):
            # Currently a placeholder. Will parse 'date' CSL variables and return an array of
            # strings for matches.
            return []
    
        variable_type = {
                "abstract": plain,
                "annote": plain,
                "archive": plain,
                "archive_location": plain,
                "archive-place": plain,
                "authority": plain,
                "call-number": plain,
                "citation-label": plain,
                "citation-number": plain,
                "collection-title": plain,
                "container-title": plain,
                "container-title-short": plain,
                "dimensions": plain,
                "doi": plain,
                "event": plain,
                "event-place": plain,
                "first-reference-note-number": plain,
                "genre": plain,
                "isbn": plain,
                "issn": plain,
                "jurisdiction": plain,
                "keyword": plain,
                "locator": plain,
                "medium": plain,
                "note": plain,
                "original-publisher": plain,
                "original-publisher-place": plain,
                "original-title": plain,
                "page": plain,
                "page-first": plain,
                "pmcid": plain,
                "pmid": plain,
                "publisher": plain,
                "publisher-place": plain,
                "references": plain,
                "reviewed-title": plain,
                "scale": plain,
                "section": plain,
                "source": plain,
                "status": plain,
                "title": plain,
                "title-short": plain,
                "url": plain,
                "version": plain,
                "year-suffix": plain,
    
                "chapter-number": number,
                "collection-number": number,
                "edition": number,
                "issue": number,
                "number": number,
                "number-of-pages": number,
                "number-of-volumes": number,
                "volume": number,
    
                "accessed": date,
                "container": date,
                "event-date": date,
                "issued": date,
                "original-date": date,
                "submitted": date,
    
                "author": name,
                "collection-editor": name,
                "composer": name,
                "container-author": name,
                "director": name,
                "editor": name,
                "editorial-director": name,
                "illustrator": name,
                "interviewer": name,
                "original-author": name,
                "recipient": name,
                "reviewed-author": name,
                "translator": name,
                }

        variable_contents = self.data.get(variable_name, False)

        if variable_contents:
            return variable_type.get(variable_name, plain)(variable_contents)
        else:
            return []

    def match(self, query):
        # Matching engine. Returns 1 if match found, 0 otherwise. 
        # Expects query to be a compiled regexp.
        
        # Very simple, just searches for substrings. Could be updated
        # to provide a 'matches' value for ranking? Using numbers here
        # so as to permit this future application.

        matched = False
        for variable in _significant_tags:
            matched = matched or query.match(" ".join(self.as_array(variable)))

        if matched:
            return 1
        else:
            return 0

    def matches(self, query):
        # Provides a boolean match response to query.
        # Expects query to be a compiled regexp.
        if self.match(query) == 0:
            return False
        else:
            return True

    def formatted(self):
        # Returns formatted Name/Date/Title string. Should be configurable somehow...
        False

class CiteprocQuery:
    def __init__(self, raw_query):
        query_array = raw_query
        self.queries = [re.compile(query, re.I) for query in query_array]

    def matches(self, entry):
        matched = True
        for query in self.queries:
            matched = matched and entry.matches(query)
        return matched

    def match(self, entry):
        # Returns a number scaled between 0 and 1. Exact value isn't particularly
        # important, so using floats.
        match_factor = float(0)
        scale_factor = float(1)/len(self.queries)
        for query in self.queries:
            match_factor += entry.match(query)

        match_factor *= scale_factor
        return match_factor

class CiteprocSource:
    def __init__(self, bib):
        try:
            raw_bib = json.loads(check_output(["pandoc-citeproc", "-j", bib]))
        except:
            raw_bib = []
        self.data = [CSLItem(entry) for entry in raw_bib]

    def __iter__(self):
        for a in self.data:
            yield a

class SourceCollator():
    def __init__(self, query=None):
        self.path = os.path.abspath(os.curdir)
        if query != None:
            self.query = CiteprocQuery(query)

    def find_bibfiles(self, file_name = "", sources = "bl", local_bib_extensions = ["bib", "bibtex", "ris"], bibliography_directories = []):
        bib_extensions = ["bib",
                          "bibtex",
                          "ris",
                          "json", 
                          "enl", 
                          "wos", 
                          "medline", 
                          "copac", 
                          "xml"]

        def b_search():
            # Search for bibiographies with the same name as the current file in the
            # current dir.
    
            if file_name in (None, ""): return []
    
            file_name_prefix = os.path.splitext(file_name)[0]
            search_paths = [file_name_prefix + "." + f for f in local_bib_extensions]
    
            bibfiles = [os.path.abspath(f) for f in search_paths if os.path.exists(f)]
            return bibfiles
    
        def c_search():
            # Search for any other bibliographies in the current dir. N.B. this does
            # not currently stop bibliographies picked up in b_search() from being found.
            # Is this an issue?
    
            relative_bibfiles = [glob("*." + f) for f in local_bib_extensions]
            bibfiles = [os.path.abspath(f) for f in relative_bibfiles]
            return bibfiles
    
        def l_search():
            # Search for bibliographies in the pandoc data dirs.
    
            if os.path.exists(os.path.expandvars("$HOME/.pandoc/")):
                b = os.path.expandvars("$HOME/.pandoc/")
            elif os.path.exists(os.path.expandvars("%APPDATA%/pandoc/")):
                b = os.path.expandvars("%APPDATA%/pandoc/")
            else:
                return []
            
            search_paths = [b + "default." + f for f in bib_extensions]
            bibfiles = [os.path.abspath(f) for f in search_paths if os.path.exists(f)]
            return bibfiles
    
        def t_search():
            # Search for bibliographies in the texmf data dirs.
    
            #if vim.eval("executable('kpsewhich')") == '0': return []
    
            texmf = check_output(["kpsewhich", "-var-value", "TEXMFHOME"])
            
            if os.path.exists(texmf):
                search_paths = [texmf + "/*." + f for f in bib_extensions]
                relative_bibfiles = [glob(f) for f in search_paths]
                bibfiles = [os.path.abspath(f) for f in relative_bibfiles]
                return bibfiles
    
            return []
    
        def g_search():
            # Search for bibliographies in the directories defined in pandoc#biblio#bibs
    
            return [f for f in bibliography_directories]

        search_methods = {"b": b_search,
                          "c": c_search,
                          "l": l_search,
                          "t": t_search,
                          "g": g_search}
    
    
        bibfiles = []
        for f in sources:
            bibfiles.extend(search_methods.get(f, list)())
    
        return bibfiles

    def collate(self):
        data = []
        for bib in self.find_bibfiles():
            for item in CiteprocSource(bib):
                if self.query.matches(item) and item.data not in data:
                    data.append(item.data)

        return data


if __name__ == "__main__":
    collator = SourceCollator(sys.argv[1:])
    print(json.dumps(list(collator.collate())))
