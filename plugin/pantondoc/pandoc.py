from subprocess import Popen, PIPE
import re
import vim

inputs_extension_table = {
        "markdown" : ["markdown", "mkd", "md", "pandoc", "pdk", "pd"],
        "native" : ["hs"],
        "rst" : ["rst"],
        "json" : ["json"],
        "textile": ["textile"],
        "html": ["html", "htm"],
        "latex": ["latex", "tex", "ltx"],
        "extra": ["text", "txt"]
        }

class PandocInfo(object):
    def __version(self):
        return Popen(["pandoc", "-v"], stdout=PIPE).communicate()[0].splitlines()

    def __help(self):
        return Popen(["pandoc", "-h"], stdout=PIPE).communicate()[0].splitlines()

    def __getattr__(self, name):
        if name == "version":
            return filter(lambda i: re.match("pandoc\ [0-9].*", i), self.__version())[0].split()[1]
        elif name == "input_formats":
            return map(lambda i: i.strip(),
                    filter(lambda i: re.match("Input formats", i), self.__help())\
                            [0].split(":  ")[1].split(",")) + ["extra"]
        elif name == "output_formats":
            return map(lambda i: i.strip(),
                    filter(lambda i: re.match("Output formats", i), self.__help())\
                            [0].split(":  ")[1].split(","))

def get_input_extensions():
    extensions = []
    supported_filetypes = set(filter(lambda i: "+" not in i, PandocInfo().input_formats))
    handled_filetypes = set(vim.eval("g:pantondoc_handled_filetypes")).intersection(supported_filetypes)
    for fmt in handled_filetypes:
        extensions.extend(inputs_extension_table[fmt])
    return extensions
