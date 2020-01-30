import sys
from subprocess import Popen, PIPE
import re
from collections import namedtuple
from itertools import chain
import argparse
from vim_pandoc.utils import ensure_string

PandocOption = namedtuple('PandocOption', ['names', 'arg', 'optional_arg'])

class PandocInfo(object):
    def __init__(self, pandoc='pandoc'):
        if type(pandoc) == bytes:
            pandoc = pandoc.decode()
        self.pandoc = pandoc
        self.update()

    def __raw_output(self, cmd, pattern=None):
        data = ensure_string(Popen([self.pandoc, cmd], stdout=PIPE).communicate()[0])
        if pattern:
            return re.search(pattern, data, re.DOTALL).group(1)
        else:
            return data

    def update(self):
        self.version = self.get_version()
        self.options = self.get_options()
        self.extensions = self.get_extensions()
        self.input_formats = self.get_input_formats()
        self.output_formats = self.get_output_formats()

    def get_version(self):
        versionPattern = 'pandoc'
        # check for MSYS terminal
        if sys.platform.startswith('msys'):
            versionPattern += '\.exe'
        versionPattern += ' (\d+\.\d+)'
        return self.__raw_output('--version', pattern=versionPattern)

    def get_options(self):
        # first line describes pandoc usage
        data = self.__raw_output('--help').splitlines()[1:]
        data = [l.strip() for l in data]
        # options from --trace onwards are not meaningful for us
        cutoff = data.index('--trace')
        data = data[:cutoff]

        options = []

        for line in data:
            # TODO: simplify if possible
            if re.search(',', line): # multiple variant options
                if re.search('(?<![a-z])(?<!-)-(?!-)', line):
                    if re.search('\[', line):
                        optional = True
                    else:
                        optional = False
                    opts = re.findall("-+([a-zA-Z-]+)[\[ =]", line)
                    if opts:
                        options.append(PandocOption(opts, True, optional))

                else:
                    opts = re.findall('--([a-z-]+)', line)
                    if opts:
                        options.append(PandocOption(opts, False, False))
            else:
                if re.search('=', line): # take arguments
                    if re.search('\[=', line): # arguments are optional
                        optional = re.findall('--([a-z-]+)\[=', line)
                        if optional:
                            options.append(PandocOption(optional, True, True))
                    else:
                        optarg_opts = re.findall('-+([a-zA-Z-]+)[ =][A-Za-z]+', line)
                        if optarg_opts:
                            options.append(PandocOption(optarg_opts, True, False))
                else: # flags
                    flag_opts = re.findall('-+([a-z-]+(?![=]))', line)
                    if flag_opts:
                        options.append(PandocOption(flag_opts, False, False))

        return options

    def get_options_list(self):
        return list(chain.from_iterable([v.names for v in self.options]))

    def get_extensions(self):
        data = self.__raw_output('--list-extensions').\
            replace(' +', '').replace(' -', '')
        return data.splitlines()

    def get_input_formats(self):
        data = self.__raw_output('--list-input-formats')
        return data.splitlines()

    def get_output_formats(self):
        data = self.__raw_output('--list-output-formats')
        return data.splitlines()

    def is_valid_output_format(self, identifier):
        if not identifier.startswith("markdown") and identifier in self.output_formats:
            return True
        elif identifier.startswith("markdown"):
            return re.match(identifier+"(([+-]("+"|".join(self.extensions)+"))+)?$", identifier)

    def build_argument_parser(self):
        def wrap_flag(flag):
            if len(flag) == 1:
                return "-" + flag
            else:
                return "--" + flag

        parser = argparse.ArgumentParser()
        parser.add_argument('output_format')
        for opt in self.options:
            flags = [wrap_flag(f) for f in opt.names]
            extra = {}
            extra['action'] = 'store_true' if not opt.arg else 'store'
            # some options can be given several times
            if any(map(lambda x: x.isupper() and x != 'T' or x == 'bibliography', opt.names)):
                extra['action'] = 'append'

            if opt.arg:
                extra['nargs'] = '?' if opt.optional_arg else 1
            parser.add_argument(*flags, **extra)
        return parser
