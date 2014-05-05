#!/usr/bin/perl

#  inject.pl
#  ApportablePlugin
#
#  Created by John Holdsworth on 03/05/2014.
#  Copyright (c) 2014 John Holdsworth. All rights reserved.
#

use IO::File;
use strict;

$| = 1;

my ($projectRoot, $shlib, $selectedFile) = @ARGV;
my ($projName) = $projectRoot =~ m@/([^/]+)/?$@;
my $flags = 0;

my @classes = unique( loadFile( $selectedFile ) =~ /\@implementation\s+(\w+)\b/g );

my $changesFile = "$selectedFile.m";
my $changesSource = IO::File->new( "> $changesFile" )
    or die "Could not open changes source file as: $!";

$changesSource->print( <<CODE );
/*
Generated for Injection of class implementations
*/

#import <UIKit/UIKit.h>

\@interface APLiveCoding
+ (void)loadedClass:(Class)newClass notify:(BOOL)notify;
+ (void)loadedNotify:(BOOL)notify hook:(void *)hook;
\@end

#define INJECTION_BUNDLE

#undef _instatic
#define _instatic extern

#undef _inglobal
#define _inglobal extern

#undef _inval
#define _inval( _val... ) /* = _val */

#import "$selectedFile"

int injectionHook() {
    NSLog( \@"injectionHook( @classes ):" );
    dispatch_async(dispatch_get_main_queue(), ^{
@{[join '', map "        [APLiveCoding loadedClass:[$_ class] notify:$flags];\n", @classes]}        [APLiveCoding loadedNotify:$flags hook:(void *)injectionHook];
    });
    return YES;
}

CODE

$changesSource->close();

print "\nBuilding $selectedFile\n\n";

(my $prjName = $projName) =~ s/ //g;
my @syslibs = qw(android log c m v z cxx stdc++ System SystemConfiguration Security CFNetwork
    Foundation CoreFoundation CoreGraphics CoreText BridgeKit OpenAL GLESv1_CM GLESv2 EGL xml2);
my $isARC = system( "grep 'CLANG_ENABLE_OBJC_ARC = YES' *.xcodeproj/project.pbxproj >/dev/null" ) == 0 ?
    "-fobjc-arc" : "-fno-objc-arc";
my ($file) = $selectedFile =~ m@/([^/]+)$@;
my $tmpobj = "/tmp/injection_$ENV{USER}";

# hard coded build
my $command = <<COMPILE;
cd ~/.apportable/SDK && export PATH=`echo ~/.apportable/SDK/toolchain/macosx/android-ndk/toolchains/arm-linux-androideabi-*/prebuilt/darwin-x86*/arm-linux-androideabi/bin`:\$PATH && ./toolchain/macosx/clang/bin/clang -o $tmpobj.o -fpic -target arm-apportable-linux-androideabi -march=armv5te -mfloat-abi=soft -nostdinc -fsigned-char -isystem toolchain/macosx/clang/lib/clang/3.3/include -Xclang -mconstructor-aliases -fzero-initialized-in-bss -fobjc-runtime=ios-6.0.0 -fobjc-legacy-dispatch -fconstant-cfstrings -mllvm -arm-reserve-r9 -fcolor-diagnostics -Wno-newline-eof -fblocks -fobjc-call-cxx-cdtors -fstack-protector -fno-short-enums -Wno-newline-eof -Werror-return-type -Werror-objc-root-class -fconstant-string-class=NSConstantString -ffunction-sections -funwind-tables -Xclang -fobjc-default-synthesize-properties -Wno-c++11-narrowing $isARC -fasm-blocks -fno-asm -fpascal-strings -Wempty-body -Wno-deprecated-declarations -Wreturn-type -Wswitch -Wparentheses -Wformat -Wuninitialized -Wunused-value -Wunused-variable -iquote Build/android-armeabi-debug/$projName-generated-files.hmap -IBuild/android-armeabi-debug/$projName-own-target-headers.hmap -iquote Build/android-armeabi-debug/$projName-all-target-headers.hmap -iquote Build/android-armeabi-debug/$projName-project-headers.hmap -include System/debug.pch -DDEBUG=1 -D__IPHONE_OS_VERSION_MIN_REQUIRED=60100 -D__PROJECT__='"$projName"' -D__compiler_offsetof=__builtin_offsetof -ISystem -Isysroot/common/usr/include -Isysroot/android/usr/include -Isysroot/common/usr/include/c++/llvm -I/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include -D__SHORT_FILE__='"$file"' -ggdb3 -Wprotocol -std=gnu99 -fgnu-keywords -c "$changesFile" -MMD && ld $tmpobj.o "Build/android-armeabi-debug/$prjName/apk/lib/armeabi/libverde.so" @{[map "sysroot/android/usr/lib/armeabi/lib$_.so", @syslibs]} -shared -o $tmpobj.so
COMPILE

# print "$command";

system( $command ) == 0 or die "Build failed: $changesFile";
unlink $changesFile;

print "\nPushing to device..\n";
system( "~/.apportable/SDK/bin/adb push $tmpobj.so $shlib 2>&1" ) == 0 or die "Could not push to device";

print "Injecting code changes\n";
#sleep 1;
exit 0;

sub loadFile {
    my ($path) = @_;
    if ( my $fh = IO::File->new( $path ) ) {
        local $/ = undef;
        my $data = <$fh>;
        return wantarray() ?
        split "\n", $data : $data;
    }
    else {
        die "Could not open \"$path\" as: $!" if !$fh;
    }
}

sub unique {
    my %hash = map {$_, $_} @_;
    return sort keys %hash;
}

