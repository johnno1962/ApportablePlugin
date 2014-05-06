//
//  APPluginMenuController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APPluginMenuController.h"
#import "APLogController.h"

@implementation APPluginMenuController

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static APPluginMenuController *apportablePlugin;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		apportablePlugin = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:apportablePlugin
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification object:nil];
	});
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    if ( ![[NSBundle bundleForClass:[self class]] loadNibNamed:@"APPluginMenuController" owner:self topLevelObjects:NULL] )
        NSLog( @"APPluginMenuController: Could not load interface." );

	NSMenu *productMenu = [[[NSApp mainMenu] itemWithTitle:@"Product"] submenu];
    [productMenu addItem:[NSMenuItem separatorItem]];
    [productMenu addItem:self.apportableMenu];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSTextViewDidChangeSelectionNotification object:nil];
}

- (void)selectionDidChange:(NSNotification *)notification
{
    id object = [notification object];
	if ([object isKindOfClass:NSClassFromString(@"DVTSourceTextView")] &&
        [[object delegate] respondsToSelector:@selector(document)])
        self.lastTextView = object;
}

- (NSString *)selectedFileSaving:(BOOL)save
{
    NSDocument *doc = [(id)[self.lastTextView delegate] document];
    if ( save )
        [doc saveDocument:self];
    return [[doc fileURL] path];
}

- (NSString *)projectRoot
{
    id delegate = [[NSApp keyWindow] delegate];
    if ( ![delegate respondsToSelector:@selector(document)] )
        delegate = self.lastDelegate;
    else
        self.lastDelegate = delegate;

    NSDocument *workspace = [delegate document];
    if ( ![workspace isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")] )
        return nil;

    NSString *documentPath = [[workspace fileURL] path];
    static NSRegularExpression *projRootRegexp;
    if ( !projRootRegexp )
        projRootRegexp = [NSRegularExpression regularExpressionWithPattern:@"^(.*?)/([^/]+)\\.(xcodeproj|xcworkspace)"
                                                                   options:0 error:NULL];

    NSArray *matches = [projRootRegexp matchesInString:documentPath options:0 range:NSMakeRange(0, [documentPath length])];
    return [matches count] ? [documentPath substringWithRange:[matches[0] rangeAtIndex:1]] : nil;
}

static __weak APConsoleController *debugger;
static NSString *debugProjectRoot;
static int revision;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ( [menuItem action] == @selector(demo:) )
        return YES;
    else if ( [menuItem action] == @selector(patch:) )
        return [[self selectedFileSaving:NO] hasSuffix:@".m"] && debugProjectRoot;
    else
        return [self projectRoot] != nil;
}

- (void)startDebugger:(NSString *)command
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
    debugger = [[APConsoleController alloc] initNib:@"APConsoleWindow"
                                            project:debugProjectRoot
                                            command:command];
#pragma clang diagnostic pop
}

- (IBAction)prepare:sender
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = @"/bin/bash";
    task.currentDirectoryPath = [self projectRoot];
    task.arguments = @[@"-c", [NSString stringWithFormat:@"\"%@\" \"%@\" 2>&1",
                               [bundle pathForResource:@"prepare" ofType:@"pl"],
                               [bundle pathForResource:@"APLiveCoding" ofType:@"m"]]];

    [task launch];
    [task waitUntilExit];

    if ( [task terminationStatus] != EXIT_SUCCESS )
        [[NSAlert alertWithMessageText:@"ApportablePlugin" defaultButton:@"OK" alternateButton:nil otherButton:nil
             informativeTextWithFormat:@"%@", @"Error preparing project, consult console."] runModal];
}

- (IBAction)debug:sender
{
    debugProjectRoot = [self projectRoot];
    [self startDebugger:@"apportable debug"];
    [debugger sendTask:@"c\n"];
}

- (IBAction)attach:sender
{
    [self startDebugger:@"apportable just_attach"];
}

- (IBAction)patch:sender
{
    if ( !debugger && sender )
        [self attach:sender];

    if ( debugger.task && [debugger.console.string rangeOfString:@"(gdb)"].location == NSNotFound ) {
        [self performSelector:@selector(patch:) withObject:nil afterDelay:.5];
        return;
    }

    if ( !debugProjectRoot )
        debugProjectRoot = [self projectRoot];

    NSString *shlib = [NSString stringWithFormat:@"/data/local/tmp/APLiveCoding%d.so", ++revision];
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = @"/bin/bash";
    task.currentDirectoryPath = debugProjectRoot;
    task.arguments = @[@"-c", [NSString stringWithFormat:@"\"%@\" \"%@\" \"%@\" \"%@\" 2>&1",
                               [[NSBundle bundleForClass:[self class]] pathForResource:@"inject" ofType:@"pl"],
                               debugProjectRoot, shlib, [self selectedFileSaving:YES]]];

    task.standardInput = [[NSPipe alloc] init];
    task.standardOutput = [[NSPipe alloc] init];

    NSString *gdbLoadCommand = [NSString stringWithFormat:@"p [APLiveCoding inject:\"%@\"]\nc\n", shlib];
    [debugger runTask:task sendOnCompletetion:gdbLoadCommand];
}

- (IBAction)load:sender
{
    debugProjectRoot = [self projectRoot];
    (void)[[APConsoleController alloc] initNib:@"APConsoleWindow" project:[self projectRoot]
                                       command:@"apportable load"];
}

- (IBAction)kill:sender
{
    (void)[[APConsoleController alloc] initNib:@"APConsoleWindow" project:[self projectRoot]
                                       command:@"apportable kill"];
}

- (IBAction)log:sender
{
    (void)[[APLogController alloc] initNib:@"APLogWindow" project:[self projectRoot]
                                   command:@"apportable log"];
}

- (IBAction)demo:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"InjectionDemo/InjectionDemo" ofType:@"xcodeproj"]]];
}

@end
