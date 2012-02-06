import vim
import os.path

def ex(*args):
    vim.command(" ".join(args))

def plugin_path():
    return os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
