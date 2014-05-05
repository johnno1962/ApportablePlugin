#!/usr/bin/perl -w

#  prepare.pl
#  ApportablePlugin
#
#  Created by John Holdsworth on 04/05/2014.
#

use IO::File;
use strict;

my ($implementation) = @ARGV;
my ($projectMain) = split "\n", `find . -name 'main.m*' -print`;

system "chmod +w '$projectMain'";
IO::File->new( ">> $projectMain" )->print( <<CODE );

//#ifdef DEBUG
#import "$implementation"
//#endif
CODE

system "open '$projectMain'";
