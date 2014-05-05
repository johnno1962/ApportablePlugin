//
//  APLiveCoding.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 03/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#ifdef ANDROID

#ifndef _APLiveCoding_m_
#define _APLiveCoding_m_

#import "APLiveCoding.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#import <dlfcn.h>
#import <elf.h>

#define INLog NSLog

@implementation UIAlertView(Injection)

- (void)injectionDismiss
{
    [self dismissWithClickedButtonIndex:0 animated:YES];
}

@end

@implementation APLiveCoding

+ (BOOL)inject:(const char *)path {
    NSLog( @"Loading shared library: %s", path );
    void *library = dlopen( path, RTLD_NOW);
    if ( !library )
        NSLog( @"APLiveCoding: %s", dlerror() );
    else {
        int (*hook)() = dlsym( library, "injectionHook" );
        if ( !hook )
            NSLog( @"APLiveCoding: Unable to locate injectionHook() in: %s", path );
        else {
            NSString *err = [self registerSelectorsInLibrary:path containing:hook];
            if ( err )
                NSLog( @"APLiveCoding: registerSelectorsInLibrary: %@", err );
            return hook( path );
        }
    }

    return FALSE;
}

+ (void)loadedClass:(Class)newClass notify:(BOOL)notify
{
    const char *className = class_getName(newClass);
    Class oldClass = objc_getClass(className);

    if  ( newClass != oldClass && newClass != [self class] ) {
        // replace implementations for class and instance methods
        [self swizzle:'+' className:className onto:object_getClass(oldClass) from:object_getClass(newClass)];
        [self swizzle:'-' className:className onto:oldClass from:newClass];
    }

    NSString *msg = [[NSString alloc] initWithFormat:@"Class '%s' injected.", className];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bundle Loaded"
                                                    message:msg delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];

    [alert performSelector:@selector(injectionDismiss) withObject:nil afterDelay:1.];
}

+ (void)loadedNotify:(BOOL)notify hook:(void *)hook
{
    INLog( @"Bundle loaded successfully." );
    [[NSNotificationCenter defaultCenter] postNotificationName:kINNotification
                                                        object:nil];
}

+ (void)swizzle:(char)which className:(const char *)className onto:(Class)oldClass from:(Class)newClass
{
    unsigned i, mc = 0;
    Method *methods = class_copyMethodList(newClass, &mc);

    for( i=0; i<mc; i++ ) {
        SEL name = method_getName(methods[i]);
        IMP newIMPL = method_getImplementation(methods[i]);
        const char *type = method_getTypeEncoding(methods[i]);

        class_replaceMethod(oldClass, name, newIMPL, type);
    }

    free(methods);
}

+ (NSString *)registerSelectorsInLibrary:(const char *)file containing:(void *)hook
{
    struct stat st;
    if ( stat( file, &st ) < 0 )
        return @"could not stat file";

    char *buffer = (char *)malloc( (unsigned)st.st_size );

    FILE *fp = fopen( file, "r" );
    if ( !fp )
        return @"Could not open file";
    if ( fread( buffer, 1, (size_t)st.st_size, fp ) != st.st_size )
        return @"Could not read file";
    fclose( fp );

    Elf32_Ehdr *hdr = (Elf32_Ehdr *)buffer;

    if ( hdr->e_shoff > st.st_size )
        return @"Bad segment header offset";

    Elf32_Shdr *sections = (Elf32_Shdr *)(buffer+hdr->e_shoff);

    // assumes names section is last...
    const char *names = buffer+sections[hdr->e_shnum-1].sh_offset;
    if ( names > buffer + st.st_size )
        return @"Bad section name table offset";

    unsigned offset = 0, nsels = 0;

    for ( int i=0 ; i<hdr->e_shnum ; i++ ) {
        Elf32_Shdr *sect = &sections[i];
        const char *name = names+sect->sh_name;
        if ( strcmp( name, "__DATA, __objc_selrefs, literal_pointers, no_dead_strip" ) == 0 ) {
            offset = sect->sh_addr;
            nsels = sect->sh_size;
        }
    }

    if ( !offset )
        return @"Unable to locate selrefs section";

    Dl_info info;
    if ( !dladdr( hook, &info ) )
        return @"Could not find load address";

    SEL *sels = (SEL *)((char *)info.dli_fbase+offset);
    for ( unsigned i=0 ; i<nsels/sizeof *sels ; i++ )
        sels[i] = sel_registerName( (const char *)(void *)sels[i] );

    free( buffer );
    return nil;
}

@end
#endif
#endif
