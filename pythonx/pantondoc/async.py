#!/usr/bin/env python

if __name__ == "__main__":
    import sys
    import getopt
    import shlex
    from subprocess import Popen

    # run the command
    with open("pandoc.out", 'w') as tmp:
        Popen(sys.argv[3:], stdout=tmp, stderr=tmp).wait()

    # once it's done, we cal back the server that called us to notify
    opts = dict(getopt.getopt(sys.argv[1:3], "", ["servername=", "open", "noopen"])[0])
    servername = opts["--servername"]
    should_open = '1' if opts.has_key("--open") else '0'

    command = " ".join(["vim --servername", servername,  \
          "--remote-expr \"pantondoc_command#PandocAsyncCallback(" + should_open + ")\""])

    Popen(shlex.split(command))
