#!/usr/bin/env python3

import sys

try:
    print(eval(" ".join(sys.argv[1:]), {'__builtins__' : None}, {}))
except:
    print("", end="")

