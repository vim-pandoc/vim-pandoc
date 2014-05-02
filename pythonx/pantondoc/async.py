#!/usr/bin/env python

if __name__ == "__main__":
    import sys
    import getopt
    import shlex
    from subprocess import Popen

    opts = dict(getopt.getopt(sys.argv[1:3], "", ["servername=", "open", "noopen"])[0])
    servername = opts["--servername"]
    should_open = '1' if "--open" in opts else '0'

    # run the command
    with open("pandoc.out", 'w') as tmp:
        com = Popen(sys.argv[3:], stdout=tmp, stderr=tmp)
        com.wait()
        returncode = str(com.returncode)

    # once it's done, we call back the server that called us
    # to notify pandoc's execution
    if sys.platform.startswith("win"):
        # TODO: make this hardcoded value dynamic or configurable
        command = ["C:\Program Files\Vim\\vim74\vim.exe"]
    else:
        command = ["vim"]
    args = " ".join(["--servername", servername,  \
                     "--remote-expr \"pantondoc#command#PandocAsyncCallback(" + should_open + ", " + returncode + ")\""])
    command.extend(shlex.split(args))
    Popen(command)

