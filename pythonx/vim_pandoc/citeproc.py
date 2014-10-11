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

class CiteprocSource():
    def __init__(self, bib):
        self.data = json.loads(check_output(["pandoc-citeproc", "-j", bib]))

class SourceCollator():
    def __init__(self, query=None):
        self.path = os.path.abspath(os.curdir)
        if query != None:
            self.query = '|'.join(query)

    def find_bibfiles(self):
        return [f for f in glob(os.path.join(self.path, "*.*")) if f.split(".")[-1] in _bib_extensions]

    def collate(self):
        data = []
        for bib in self.find_bibfiles():
            bib_data = CiteprocSource(bib).data
            for item in bib_data:
                for i in filter(lambda i: i in _significant_tags, item.keys()):
                    if type(item[i]) in (str, unicode):
                        if self.query != '' and re.search(self.query, item[i], re.IGNORECASE) and \
                                item not in data:
                            data.append(item)
                    elif type(item[i]) == list:
                        for x in item[i]:
                            for y in x:
                                if self.query != '' and re.search(self.query, x[y], re.IGNORECASE) and \
                                        item not in data:
                                    data.append(item)
        return data


if __name__ == "__main__":
    collator = SourceCollator(sys.argv[1:])
    print(json.dumps(list(collator.collate())))
