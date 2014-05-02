//
//  APConsoleController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APConsoleController.h"

static NSMutableArray *controllers;

@implementation APConsoleController

- (instancetype)initNib:(NSString *)nibName project:(NSString *)projectRoot command:(NSString *)command
{

    if ( (self = [super init]) && projectRoot ) {
        if ( !controllers )
            controllers = [[NSMutableArray alloc] init];
        [controllers addObject:self];

        [[NSBundle bundleForClass:[self class]] loadNibNamed:nibName owner:self topLevelObjects:NULL];

        // need to add to Windows menu manually
        // for some reason this is not reliable
        self.menuItem.title = command;
        [[self windowMenu] addItem:self.separator];
        [[self windowMenu] addItem:self.menuItem];

        self.window.representedFilename = projectRoot;
        self.window.title = command;
        [self.window makeKeyAndOrderFront:self];

        self.task = [[NSTask alloc] init];
        self.task.launchPath = @"/bin/bash";
        self.task.currentDirectoryPath = projectRoot;
        self.task.arguments = @[@"-c", [NSString stringWithFormat:@"export PATH=\"~/.apportable/SDK/bin:$PATH\" && "
                                   "exec %@ 2>&1", command]];

        [self runTask:self.task];
    }

    return self;
}

- (NSMenu *)windowMenu {
    return [[[NSApp mainMenu] itemWithTitle:@"Window"] submenu];
}

/*
 * Thanks to NSTask tutorial by Andy Pereira: http://www.raywenderlich.com/36537/nstask-tutorial
 */

- (void)runTask:(NSTask *)task
{

    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{

        @try {
            task.standardInput = [[NSPipe alloc] init];
            task.standardOutput = [[NSPipe alloc] init];

            NSFileHandle *readHandle = [task.standardOutput fileHandleForReading];
            [readHandle waitForDataInBackgroundAndNotify];

            id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                            object:readHandle queue:nil
                                                                        usingBlock:^(NSNotification *notification) {

                NSData *output = [readHandle availableData];
                NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self insertText:outStr];
                });

                [readHandle waitForDataInBackgroundAndNotify];
            }];

            [task launch];
            [task waitUntilExit];

            dispatch_sync(dispatch_get_main_queue(), ^{
                if ( [task terminationStatus] == 0 )
                    [self.window performSelector:@selector(close) withObject:nil afterDelay:3.];
                self.task = nil;
            });

            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
        @catch (NSException *exception) {
            self.console.string = [NSString stringWithFormat:@"Problem Running Task: %@", [exception description]];
        }
    });
}

/*
 * insert text into text view, overridden for filtering in APLogController.m
 */
- (void)insertText:(NSString *)outStr
{
    [self.console insertText:outStr];
}

/*
 * key down event in TextView, relay to running command
 */
- (void)keyDown:(NSEvent *)theEvent
{
    NSString *input = [[theEvent characters] stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    if ( [input isEqualToString:@"\003"] ) {
        [self.task interrupt];
        return;
    }

    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    [[self.task.standardInput fileHandleForWriting] writeData:data];
    [self.console insertText:input];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.task terminate];

    NSMenu *windowMenu = [self windowMenu];
    if ( [windowMenu indexOfItem:self.separator] != -1 )
        [windowMenu removeItem:self.separator];
    if ( [windowMenu indexOfItem:self.menuItem] != -1 )
        [windowMenu removeItem:self.menuItem];

    [controllers removeObject:self];
}

@end
