#!/usr/bin/env python2

import sys
import os
from subprocess import check_output
import json
from glob import glob
import re
try:
    from vim_pandoc.bib.collator import SourceCollator
except:
    from collator import SourceCollator

# Filetypes that citeproc.py will attempt to parse.
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

# Tags that citeproc.py will search in, together with scaling
# factors for relative importance. These are currently non-functional.
_significant_tags = {"id": 0.5,
                     "author": 1.0,
                     "issued": 1.0,
                     "title": 1.0,
                     "publisher": 1.0,
                     "abstract": 0.1}
class CSLItem:
    # This class implements various helper methods for CSL-JSON formatted bibliography
    # entries.
    def __init__(self, entry):
        self.data = entry
        self.as_array_buffer = {}

    def citekey(self):
        return self.data["id"]

    def buffered_as_array(self, variable_name):
        if variable_name not in self.as_array_buffer:
            self.as_array_buffer[variable_name] = as_array(variable_name)

        return self.as_array_buffer[variable_name]

    def as_array(self, variable_name):
        def plain(variable_contents):
            # Takes the contents of a 'plain' variable and splits it into an array.
            # nb. this must be able to cope with integer input as well as strings.
            return unicode(variable_contents).split('\n')

        def number(variable_contents):
            # Returns variable_contents as an array.
            return [unicode(variable_contents)]

        def name(variable_contents):
            # Parses "name" CSL Variables and returns an array of names.

            def surname(author):
                # Concat dropping particle and non-dropping particle with family name.
                return [(author.get("dropping-particle", "") +
                         " " +
                         author.get("non-dropping-particle", "") +
                         " " +
                         author.get("family", ""))]

            def given_names(author):
                # Return given variable split at spaces.
                return author.get("given", "")

            def literal_name(author):
                # It seems likely there is some particular reason for the author being
                # a literal, so don't try and do clever stuff like splitting into tokens...
                return [author.get("literal", "")]

            array_of_names = []

            for author in variable_contents:
                if "literal" in author:
                    array_of_names.extend(literal_name(author))
                else:
                    array_of_names.extend(surname(author))
                    array_of_names.extend(given_names(author))

            return array_of_names

        def date(variable_contents):
            # Currently a placeholder. Will parse 'date' CSL variables and return an array of
            # strings for matches.
            def date_parse(raw_date_array):
                # Presently, this function returns the date in yyyy-mm-dd format. In future, it
                # will provide a variety of alternative forms.
                date = [unicode(x) for x in raw_date_array]
                return ["-".join(date)]
            def date_parts(date_parts_contents):
                # Call date_parts for each element.
                response = []
                for date in date_parts_contents:
                    response.extend(date_parse(date))
                return response
            def season(season_type):
                # Not actually clear from the spec what is meant to go in here. Zotero doesn't
                # 'do' seasons, and I can't work it out from the pandoc-citeproc source. Will
                # try and make this work when I have useful internet
                season_lookup = {1: "spring",
                                 2: "summer",
                                 3: "autumn",
                                 4: "winter"}
                return []
            def circa(circa_boolean):
                return []
            def literal(date_string):
                return [date_string]

            date_function_lookup = {"date-parts": date_parts,
                                    "season": season,
                                    "circa": circa,
                                    "literal": literal,
                                    "raw": literal}

            response = []

            for element in variable_contents:
                response.extend(date_function_lookup[element](variable_contents[element]))

            return response

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
                "translator": name
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
            for token in self.as_array(variable):
                matched = matched or query.search(token)
                if matched:
                    break

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

    def relevance(self, query):
        # Returns the relevance of an item for a query
        query = re.compile(query, re.I)
        relevance = float(0.0)
        tags_matched = []
        for tag in _significant_tags:
            for token in self.as_array(tag):
                if query.search(token):
                    tags_matched.append(tag)
                    break
        if tags_matched != []:
            relevance = sum([_significant_tags[t] for t in tags_matched])
        return relevance

    def formatted(self):
        # Returns formatted Name/Date/Title string. Should be configurable somehow...
        False

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

class CiteprocCollator(SourceCollator):
    def collate(self):
        data = []

        for bib in self.find_bibfiles():
            for item in CiteprocSource(bib):
                if item.matches(re.compile(self.query, re.I)) and item not in data:
                    data.append(item)

        data.sort(key=lambda i: i.relevance(self.query), reverse=True)

        return [item.data for item in data]

