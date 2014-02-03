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

    # once it's done, we cal back the server that called us to notify
    command = " ".join(["vim --servername", servername,  \
          "--remote-expr \"pantondoc#command#PandocAsyncCallback(" + should_open + ", " + returncode + ")\""])
    Popen(shlex.split(command))
