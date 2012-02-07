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
        try:
            return Popen(["pandoc", "-v"], stdout=PIPE).communicate()[0].splitlines()
        except OSError:
            return None

    def __help(self):
        try:
            return Popen(["pandoc", "-h"], stdout=PIPE).communicate()[0].splitlines()
        except OSError:
            return None

    def __getattr__(self, name):
		if self.__version() or  self.__help():
			if name == "version":
				return filter(lambda i: re.match("pandoc\ [0-9].*", i), self.__version())[0].split()[1]
			if name == "mayor_version":
				return self.version.split(".")[:2]
			elif name == "input_formats":
				return map(lambda i: i.strip(),
						filter(lambda i: re.match("Input formats", i), self.__help())\
								[0].split(":  ")[1].split(",")) + ["extra"]
			elif name == "output_formats":
				return map(lambda i: i.strip(),
						filter(lambda i: re.match("Output formats", i), self.__help())\
								[0].split(":  ")[1].split(","))
		else:
			if name == "version":
				return None
			elif name in ("mayor_version", "input_formats", "output_formats"):
				return []

def get_input_extensions():
    extensions = []
    for fmt in set(vim.eval("g:pantondoc_handled_filetypes")):
        extensions.extend(inputs_extension_table[fmt])
    return extensions
