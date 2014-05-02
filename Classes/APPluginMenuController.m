//
//  APMenuConctroller.m
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self projectRoot] != nil;
}

- (IBAction)load:sender
{
    (void)[[APConsoleController alloc] initNib:@"APConsoleWindow" project:[self projectRoot] command:@"apportable load"];
}

- (IBAction)debug:sender
{
    (void)[[APConsoleController alloc] initNib:@"APConsoleWindow" project:[self projectRoot] command:@"apportable debug"];
}

- (IBAction)kill:sender
{
    (void)[[APConsoleController alloc] initNib:@"APConsoleWindow" project:[self projectRoot] command:@"apportable kill"];
}

- (IBAction)log:sender
{
    (void)[[APLogController alloc] initNib:@"APLogWindow" project:[self projectRoot] command:@"apportable log"];
}

@end
