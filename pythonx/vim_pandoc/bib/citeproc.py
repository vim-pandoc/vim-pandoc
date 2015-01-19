#!/usr/bin/env python2
# vim: set fdm=marker:

# imports {{{1
from subprocess import check_output
import json
import re
try:
    from vim_pandoc.bib.collator import SourceCollator
    from vim_pandoc.bib.util import flatten
except:
    from collator import SourceCollator
    from util import flatten

# _bib_extensions {{{1
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

# _significant_tags {{{1
# Tags that citeproc.py will search in, together with scaling
# factors for relative importance. These are currently non-functional.
_significant_tags = {"id": 0.5,
                     "author": 1.0,
                     "issued": 1.0,
                     "title": 1.0,
                     "publisher": 1.0,
                     "abstract": 0.1}

# _variable_type {{{1
# Map of tags -> types.
_variable_type = {
        "abstract": "plain",
        "annote": "plain",
        "archive": "plain",
        "archive_location": "plain",
        "archive-place": "plain",
        "authority": "plain",
        "call-number": "plain",
        "citation-label": "plain",
        "citation-number": "plain",
        "collection-title": "plain",
        "container-title": "plain",
        "container-title-short": "plain",
        "dimensions": "plain",
        "doi": "plain",
        "event": "plain",
        "event-place": "plain",
        "first-reference-note-number": "plain",
        "genre": "plain",
        "isbn": "plain",
        "issn": "plain",
        "jurisdiction": "plain",
        "keyword": "plain",
        "locator": "plain",
        "medium": "plain",
        "note": "plain",
        "original-publisher": "plain",
        "original-publisher-place": "plain",
        "original-title": "plain",
        "page": "plain",
        "page-first": "plain",
        "pmcid": "plain",
        "pmid": "plain",
        "publisher": "plain",
        "publisher-place": "plain",
        "references": "plain",
        "reviewed-title": "plain",
        "scale": "plain",
        "section": "plain",
        "source": "plain",
        "status": "plain",
        "title": "plain",
        "title-short": "plain",
        "url": "plain",
        "version": "plain",
        "year-suffix": "plain",

        "chapter-number": "number",
        "collection-number": "number",
        "edition": "number",
        "issue": "number",
        "number": "number",
        "number-of-pages": "number",
        "number-of-volumes": "number",
        "volume": "number",

        "accessed": "date",
        "container": "date",
        "event-date": "date",
        "issued": "date",
        "original-date": "date",
        "submitted": "date",

        "author": "name",
        "collection-editor": "name",
        "composer": "name",
        "container-author": "name",
        "director": "name",
        "editor": "name",
        "editorial-director": "name",
        "illustrator": "name",
        "interviewer": "name",
        "original-author": "name",
        "recipient": "name",
        "reviewed-author": "name",
        "translator": "name"
        }

class CSLItem: #{{{1
    # This class implements various helper methods for CSL-JSON formatted bibliography
    # entries.
    def __init__(self, entry): #{{{2
        self.data = entry

    def as_array(self, variable_name): #{{{2
        def plain(variable_contents): #{{{3
            # Takes the contents of a 'plain' variable and splits it into an array.
            return unicode(variable_contents).split('\n')

        def number(variable_contents): #{{{3
            return [unicode(variable_contents)]

        def name(variable_contents): #{{{3
            # Parses "name" CSL Variables and returns an array of names.

            def surname(author):
                # Concat dropping particle and non-dropping particle with family name.
                return [" ".join((author.get("dropping-particle", ""),
                                  author.get("non-dropping-particle", ""),
                                  author.get("family", ""))).strip()]

            def given_names(author):
                return [author.get("given", "").strip()]

            def literal_name(author):
                # It seems likely there is some particular reason for the author being
                # a literal, so don't try and do clever stuff like splitting into tokens...
                return [author.get("literal", "").strip()]

            names = []

            for author in variable_contents:
                name = ""
                if "literal" in author:
                    name = literal_name(author)
                else:
                    name = surname(author) + given_names(author)
                names.append(name)

            return names

        def date(variable_contents): #{{{3
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
            # }}}3

        variable_contents = self.data.get(variable_name, False)

        if variable_contents:
            return eval(_variable_type.get(variable_name, "plain"))(variable_contents)
        else:
            return []

    def match(self, query): #{{{2
        # Matching engine. Returns 1 if match found, 0 otherwise.
        # Expects query to be a compiled regexp.

        # Very simple, just searches for substrings. Could be updated
        # to provide a 'matches' value for ranking? Using numbers here
        # so as to permit this future application.

        matched = False
        for variable in _significant_tags:
            for token in self.as_array(variable):
                matched = matched or query.search(flatten(token))
                if matched:
                    break

        if matched:
            return 1
        else:
            return 0

    def matches(self, query): #{{{2
        # Provides a boolean match response to query.
        # Expects query to be a compiled regexp.
        if self.match(query) == 0:
            return False
        else:
            return True

    def relevance(self, query): #{{{2
        # Returns the relevance of an item for a query
        query = re.compile(query, re.I)
        relevance = float(0.0)
        tags_matched = []
        for tag in _significant_tags:
            for token in self.as_array(tag):
                if query.search(flatten(token)):
                    tags_matched.append(tag)
                    break
        if tags_matched != []:
            relevance = sum([_significant_tags[t] for t in tags_matched])
        return relevance

class CiteprocSource: #{{{1
    def __init__(self, bib): #{{{2
        try:
            raw_bib = json.loads(check_output(["pandoc-citeproc", "-j", bib]))
        except:
            raw_bib = []
        self.data = [CSLItem(entry) for entry in raw_bib]

    def __iter__(self): #{{{2
        for a in self.data:
            yield a

class CiteprocCollator(SourceCollator): #{{{1
    def collate(self): #{{{2
        data = []

        for bib in self.find_bibfiles():
            for item in CiteprocSource(bib):
                if item.matches(re.compile(self.query, re.I)) and item not in data:
                    data.append(item)

        data.sort(key=lambda i: i.relevance(self.query), reverse=True)

        return [item.data for item in data]

