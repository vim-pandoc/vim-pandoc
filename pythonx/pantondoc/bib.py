import vim
import re
import os
import os.path
import operator
from glob import glob
import subprocess as sp

bib_extensions = ["json", "ris", "mods", "biblatex", "bib"]

def find_bibfiles():
    sources = vim.vars["pantondoc_biblio_sources"]
    bibfiles = []
    if "b" in sources and vim.current.buffer.name not in (None, ""):
        file_name, ext = os.path.splitext(vim.current.buffer.name)
        # we check for files named after the current file in the current dir
        bibfiles.extend([os.path.abspath(f) for f in glob(file_name + ".*") if os.path.splitext(f)[1] in bib_extensions])

    # we search for any bibliography in the current dir
    if "c" in sources:
        bibfiles.extend([os.path.abspath(f) for f in glob("*.*") if f.split(".")[-1] in bib_extensions])

    # we search in pandoc's local data dir
    if "l" in sources:
        b = ""
        if os.path.exists(os.path.expandvars("$HOME/.pandoc/")):
            b = os.path.expandvars("$HOME/.pandoc/")
        elif os.path.exists(os.path.expandvars("%APPDATA%/pandoc/")):
            b = os.path.expandvars("%APPDATA%/pandoc/")
        if b != "":
            bibfiles.extend([os.path.abspath(f) for f in glob(b + "default.*") if f.split(".")[-1] in bib_extensions])

    # we search for bibliographies in texmf
    if "t" in sources and vim.eval("executable('kpsewhich')") != '0':
        texmf = sp.Popen(["kpsewhich", "-var-value", "TEXMFHOME"], stdout=sp.PIPE, stderr=sp.PIPE).\
                    communicate()[0].strip()
        if os.path.exists(texmf):
            bibfiles.extend([os.path.abspath(f) for f in glob(texmf + "/*") if f.split(".")[-1] in bib_extensions])

    # we append the items in g:pandoc_bibfiles, if set
    if "g" in sources:
        bibfiles.extend(vim.vars["pantondoc_bibs"])

    # we check if the items in bibfiles are readable and not directories
    if bibfiles != []:
        bibfiles = list(set(filter(lambda f : os.access(f, os.R_OK) and not os.path.isdir(f), bibfiles)))

    return bibfiles

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

            entry_dict["menu"] = title

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

            entry_dict["menu"] = title
            entries.append(entry_dict)

    return entries

def get_mods_suggestions(text, query):
    import xml.etree.ElementTree as etree
    entries = []

    bib_data = etree.fromstring(text)
    if bib_data.tag == "mods":
        entry_dict = {}
        entry_id = bib_data.get("ID")
        if re.match(query, str(entry_id)):
            entry_dict["word"] = entry_id
            title = " ".join([s.strip() for s in bib_data.find("titleInfo").find("title").text.split("\n")])
            entry_dict["menu"] = str(title)
            entries.append(entry_dict)
    elif bib_data.tag == "modsCollection":
        for mod in bib_data.findall("mods"):
            entry_dict = {}
            entry_id = mod.get("ID")
            if re.match(query, str(entry_id)):
                entry_dict["word"] = entry_id
                title = " ".join([s.strip() for s in bib_data.find("titleInfo").find("title").text.split("\n")])
                entry_dict["menu"] = str(title)
                entries.append(entry_dict)

    return entries

def get_json_suggestions(text, query):
    import json

    entries = []

    data = json.loads(text)

    for entry in data:
        entry_dict = {}
        # we make a simple check to see if the item contains bibliographic data
        if all([entry.has_key(k) for k in ["author", "title", "id"]]):
            label = str(entry["id"])
            if re.search(query,  label):
                entry_dict["word"] = label
                title = entry["title"]
                entry_dict["menu"] = str(title)
                entries.append(entry_dict)

    return entries

def get_suggestions():
    bibs = vim.eval("b:pantondoc_bibs")
    if len(bibs) < 1:
       bibs = find_bibfiles()
    query = vim.eval("a:partkey")

    matches = []

    for bib in bibs:
        bib_type = os.path.basename(bib).split(".")[-1].lower()
        with open(bib) as f:
            text = f.read()

        ids = []
        if bib_type == "mods":
            ids = get_mods_suggestions(text, query)
        elif bib_type == "ris":
            ids = get_ris_suggestions(text, query)
        elif bib_type == "json":
            ids = get_json_suggestions(text, query)
        else:
            if bool(vim.vars["pantondoc_biblio_use_bibtool"]) and bool(vim.eval("executable('bibtool')")):
                ids = get_bibtex_suggestions(bib, query, True, bib)
            else:
                ids = get_bibtex_suggestions(text, query)

        matches.extend(ids)

    if len(matches) > 0:
        matches = sorted(matches, key=operator.itemgetter("word"))
    return matches

