#!/usr/bin/python

#  inject.py
#  ApportablePlugin
#
#  Created by John Holdsworth on 11/05/2014.
#

import sys
from sys import argv, exit
from os import environ, chdir, unlink, fdopen
from subprocess import call
import re

sys.stdout = fdopen(sys.stdout.fileno(), 'w', 0)

projectRoot = argv[1]
shlib       = argv[2]
selectedFile= argv[3]
flags = 0

projName = re.search(r'/([^/]+)/?$', projectRoot).group(1);

classes = list(set(re.findall(r'@implementation\s+(\w+)\b',open(selectedFile).read())))
injection = "".join(map(lambda cl:'        [APLiveCoding loadedClass:[%s class] notify:%s];\n' % (cl, flags), classes))

changesFile = re.sub( r'(\.\w+)$', r'_\1', selectedFile )

open( changesFile, "w" ).write( """\
/*
Generated for Injection of class implementations
*/

#import <UIKit/UIKit.h>

@interface APLiveCoding
+ (void)loadedClass:(Class)newClass notify:(BOOL)notify;
+ (void)loadedNotify:(BOOL)notify hook:(void *)hook;
@end

#define INJECTION_BUNDLE

#undef _instatic
#define _instatic extern

#undef _inglobal
#define _inglobal extern

#undef _inval
#define _inval( _val... ) /* = _val */

#import "%s"

#if __cplusplus
extern "C" int injectionHook();
#endif

int injectionHook() {
    NSLog( @"injectionHook( %s ):" );
    dispatch_async(dispatch_get_main_queue(), ^{
%s        [APLiveCoding loadedNotify:%s hook:(void *)injectionHook];
    });
    return YES;
}

    """ % (selectedFile, " ".join(classes), injection, flags))


print "\nBuilding "+changesFile
chdir( environ['HOME']+"/.apportable/SDK" )

ninja = open( "Build/build.ninja" ).read();
rule = "compile_c"
if ( re.match( r'\.mm$', selectedFile ) ):
    rule = "compile_cxx"

command = re.search( r'rule %s_.*\n  command = ((?:.*\$\n)*.*)' % rule, ninja ).group(1)
per_file_flags = re.search( r'per_file_flags = (.*)', ninja ).group(1)
tmpobj = "/tmp/injection_"+environ['USER']

command = re.sub( r'\$per_file_flags\b', per_file_flags, command );
command = re.sub( r'\$in\b', '"%s"' % changesFile, command );
command = re.sub( r'\$out\b', '"%s.o"' % tmpobj, command );

command = re.sub( r'\$\n\s+', r'', command )
command = re.sub( r'\$(.)', r'\1', command )

prjName = re.sub( r' ', r'', projName )
syslibs = "android c m v z dl log cxx stdc++ System SystemConfiguration Security CFNetwork "\
    "Foundation CoreFoundation CoreGraphics CoreText BridgeKit OpenAL GLESv1_CM GLESv2 EGL xml2".split(" ")

command = command + ' && ./toolchain/macosx/android-ndk/toolchains/arm-linux-androideabi-*/prebuilt/darwin-x86*/arm-linux-androideabi/bin/ld "%s.o" "Build/android-armeabi-debug/%s/apk/lib/armeabi/libverde.so" %s -shared -o "%s.so"' % \
    (tmpobj, prjName, " ".join(map(lambda lib:'"sysroot/usr/lib/armeabi/lib%s.so"' % lib, syslibs)), tmpobj)

if ( call( ["/bin/bash", "-c", command] ) ):
    print argv[0]+": *** Compile failed: "+changesFile
    exit(1)

unlink( changesFile )

print "\nPushing to device.."
if ( call( ["/bin/bash", "-c", "./bin/adb push %s.so %s 2>&1" % (tmpobj, shlib)] ) ):
    print argv[0]+": *** Could not push to device"
    exit(1)

print "Injecting code changes"
