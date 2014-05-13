#!/usr/bin/python

#  prepare.py
#  ApportablePlugin
#
#  Created by John Holdsworth on 11/05/2014.
#

import sys
from subprocess import Popen, PIPE, call

implementation = sys.argv[1]

main_m = Popen(["find", ".", "-name", "main.m*", "-print"],
               stdout=PIPE).stdout.read().split( "\n" )[0]

call(["chmod", "+w", main_m])

open(main_m, "a").write("""
//#ifdef DEBUG
#import "%s"
//#endif
""" % implementation)

call(["open", main_m])
