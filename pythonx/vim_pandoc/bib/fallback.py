import vim
import re
import os
import os.path
import operator
import subprocess as sp
from vim_pandoc.bib.collator import SourceCollator
from vim_pandoc.bib.util import make_title_ascii

try:
    local_bib_extensions = vim.vars["pandoc#biblio#bib_extensions"]
except:
    local_bib_extensions = []

bib_extensions = ["bib", "bibtex", "ris", "mods", "json", "enl", "wos", "medline", "copac", "xml"]

# SUGGESTIONS

bibtex_title_search = re.compile("^\s*[Tt]itle\s*=\s*{(?P<title>\S.*?)}.{,1}\n", re.MULTILINE | re.DOTALL)
bibtex_booktitle_search = re.compile("^\s*[Bb]ooktitle\s*=\s*{(?P<booktitle>\S.*?)}.{,1}\n", re.MULTILINE | re.DOTALL)

def get_bibtex_suggestions(text, query, use_bibtool=False, bib=None):
    global bibtex_title_search
    global bibtex_booktitle_search
    global bibtex_author_search
    global bibtex_editor_search
    global bibtex_crossref_search

    entries = []

    if use_bibtool:
        bibtex_id_search = re.compile(".*{\s*(?P<id>.*),")

        args = "-- select{$key title booktitle author editor \"%(query)s\"}'" % {"query": query}
        text = sp.Popen(["bibtool", args, bib], stdout=sp.PIPE, stderr=sp.PIPE).communicate()[0]
    else:
        bibtex_id_search = re.compile(".*{\s*(?P<id>" + query + ".*),")

    for entry in [i for i in re.split("\n@", text)]:
        entry_dict = {}
        i1 = bibtex_id_search.match(entry)
        if i1:
            entry_dict["word"] = i1.group("id")

            title = "..."
            # search for title
            i2 = bibtex_title_search.search(entry)
            if i2:
                title = i2.group("title")
            else:
                i3 = bibtex_booktitle_search.search(entry)
                if i3:
                    title = i3.group("booktitle")
            title = re.sub("[{}]", "", re.sub("\s+", " ", title))

            entry_dict["menu"] = make_title_ascii(title)

            entries.append(entry_dict)

    return entries


ris_title_search = re.compile("^(TI|T1|CT|BT|T2|T3)\s*-\s*(?P<title>.*)\n", re.MULTILINE)

def get_ris_suggestions(text, query):
    global ris_title_search
    global ris_author_search

    entries = []

    ris_id_search = re.compile("^ID\s*-\s*(?P<id>" +  query + ".*)\n", re.MULTILINE)

    for entry in re.split("ER\s*-\s*\n", text):
        entry_dict = {}
        i1 = ris_id_search.search(entry)
        if i1:
            entry_dict["word"] = i1.group("id")
            title = "..."
            i2 = ris_title_search.search(entry)
            if i2:
                title = i2.group("title")

            entry_dict["menu"] = make_title_ascii(title)
            entries.append(entry_dict)

    return entries

def get_json_suggestions(text, query):
    import json

    entries = []
    string_matches = [u'title', u'id']
    name_matches = [u'author', u'editor']

    try:
        data = json.loads(text)
    except:
        return entries

    if type(data) != list: return entries

    def check(string):
        return re.search(query, string, re.IGNORECASE)

    def test_entry(entry):
        if type(entry) != dict: return False
        for string in [entry.get(k) for k in string_matches]:
            if type(string) == unicode and check(string): return True
        for names in [entry.get(k) for k in name_matches]:
            if type(names) == list:
                for person in names:
                    if type(person.get(u'family')) == unicode:
                        if check(person[u'family']): return True
                    elif type(person.get(u'literal')) == unicode:
                        if check(person[u'literal']): return True

    for entry in filter(test_entry, data):
        entries.append({"word": entry.get('id'),
                        "menu": make_title_ascii(entry.get("title", "No Title"))
                        })

    return entries

class FallbackCollator(SourceCollator):
    def collate(self):
        data = []
        for bib in self.find_bibfiles():
            bib_type = os.path.basename(bib).split(".")[-1].lower()
            if bib_type not in ("ris", "json", "bib", "bibtex"):
                break

            with open(bib) as f:
                text = f.read()

            ids = []
            if bib_type == "ris":
                ids = get_ris_suggestions(text, self.query)
            elif bib_type == "json":
                ids = get_json_suggestions(text, self.query)
            elif bib_type in ("bib", "bibtex"):
                if self.extra_args["use_bibtool"] == 1 \
                        and vim.eval("executable('bibtool')") == '1':
                    ids = get_bibtex_suggestions(bib, self.query, True, bib)
                else:
                    ids = get_bibtex_suggestions(text, self.query)

            data.extend(ids)

        if len(data) > 0:
            data = sorted(data, key=operator.itemgetter("word"))
        return data
