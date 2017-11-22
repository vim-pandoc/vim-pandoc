import vim

def ensure_string(val):
    if type(val) == bytes:
        return val.decode()
    return val

def plugin_enabled_modules():
    v_enabled = vim.eval('g:pandoc#modules#enabled')
    v_disabled = vim.eval('g:pandoc#modules#disabled')
    return [m for m in v_enabled if m not in v_disabled]
