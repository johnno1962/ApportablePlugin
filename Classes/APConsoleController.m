//
//  APConsoleController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APConsoleController.h"

static NSMutableArray *visibleControllers;

@implementation APConsoleController

- (instancetype)initNib:(NSString *)nibName project:(NSString *)projectRoot command:(NSString *)command
{
    if ( (self = [super init]) && projectRoot ) {
        if ( !visibleControllers )
            visibleControllers = [[NSMutableArray alloc] init];
        [visibleControllers addObject:self];

        if ( ![[NSBundle bundleForClass:[self class]] loadNibNamed:nibName owner:self topLevelObjects:NULL] )
            NSLog( @"APConsoleController: Could not load interface '%@'", nibName );

        // need to add to Windows menu manually
        // for some reason this is not reliable
        self.menuItem.title = command;
        [[self windowMenu] addItem:self.separator];
        [[self windowMenu] addItem:self.menuItem];

        self.window.title = command;
        self.window.representedFilename = projectRoot;
        [self.window makeKeyAndOrderFront:self];

        self.task = [[NSTask alloc] init];
        self.task.launchPath = @"/bin/bash";
        self.task.currentDirectoryPath = projectRoot;
        self.task.arguments = @[@"-c", [NSString stringWithFormat:@"export PATH="
                                        "\"~/.apportable/SDK/bin:$PATH\" && exec %@ 2>&1", command]];

        self.task.standardInput = [[NSPipe alloc] init];
        self.task.standardOutput = [[NSPipe alloc] init];

        [self runTask:self.task sendOnCompletetion:nil];
    }

    return self;
}

- (NSMenu *)windowMenu {
    return [[[NSApp mainMenu] itemWithTitle:@"Window"] submenu];
}

/*
 * Thanks to NSTask tutorial by Andy Pereira: http://www.raywenderlich.com/36537/nstask-tutorial
 */

- (void)runTask:(NSTask *)aTask sendOnCompletetion:(NSString *)gdbCommand
{
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(backgroundQueue, ^{

        @try {
            NSFileHandle *readHandle = [aTask.standardOutput fileHandleForReading];
            [readHandle waitForDataInBackgroundAndNotify];

            id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                            object:readHandle queue:nil
                                                                        usingBlock:^(NSNotification *notification) {

                NSData *outputData = [readHandle availableData];
                NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

                if ( output )
                    [self insertText:output];

                [readHandle waitForDataInBackgroundAndNotify];
            }];

            [aTask launch];
            [aTask waitUntilExit];

            dispatch_sync(dispatch_get_main_queue(), ^{
                if ( [aTask terminationStatus] == EXIT_SUCCESS ) {
                    if ( !gdbCommand ) {
                        [self.window performSelector:@selector(close) withObject:nil afterDelay:3.];
                        self.task = nil;
                    }
                    else {
                        [self.task interrupt];
                        [self performSelector:@selector(handleTextViewInput:) withObject:gdbCommand afterDelay:.1];
                    }
                }
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
- (void)insertText:(NSString *)output
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.console setSelectedRange:NSMakeRange([self.console.string length], 0)];
        [self.console insertText:output];
    });
}

/*
 * key down event in TextView, relay to running command
 */
- (BOOL)handleTextViewInput:(NSString *)characters
{
    NSString *input = [characters stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];

    if ( !self.inputHistory )
        self.inputHistory = [[NSMutableArray alloc] init];

    if ( !self.startBuffered )
        self.startBuffered = [[self.console selectedRanges][0] rangeValue].location;

    switch ( [input characterAtIndex:0] ) {

        // contrl-a
        case 0x01:
            [self.console setSelectedRange:NSMakeRange(self.startBuffered, 0)];
            return TRUE;

        // control-c
        case 0x03:
            [self.task interrupt];
            self.startBuffered = 0;
            return TRUE;

        // up arrow
        case 0xF700:
            if ( self.historyPointer > 0 ) {
                if ( self.historyPointer == [self.inputHistory count] )
                    [self.inputHistory addObject:[self bufferedInput]];
                self.historyPointer--;
                [self useHistory];
            }
            return TRUE;

        // down arrow
        case 0xF701:
            if ( self.historyPointer+1 < [self.inputHistory count] ) {
                self.historyPointer++;
                [self useHistory];
            }
            return TRUE;

        default:
            if ( [input characterAtIndex:[input length]-1] != '\n' )
                return FALSE;
            else {
                [self sendTask:[[self bufferedInput] stringByAppendingString:input]];
                if ( [[self bufferedInput] length] )
                    [self.inputHistory addObject:[self bufferedInput]];
                self.historyPointer = [self.inputHistory count];
                [self insertText:input];
                self.startBuffered = 0;
                return TRUE;
            }
    }
}

- (NSString *)bufferedInput
{
    return [self.console.string substringWithRange:[self bufferedRange]];
}

- (NSRange)bufferedRange
{
    NSUInteger end = [self.console.string length], start = MIN(self.startBuffered, end);
    return NSMakeRange(start, end>start ? end-start : 0);
}

- (void)useHistory
{
    [self.console replaceCharactersInRange:[self bufferedRange]
                                withString:self.inputHistory[self.historyPointer]];
    [self.console setSelectedRange:NSMakeRange([self.console.string length], 0)];
}

- (void)sendTask:(NSString *)input
{
    @try {
        NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
        [[self.task.standardInput fileHandleForWriting] writeData:data];
    }
    @catch (NSException *exception) {
        NSLog( @"Problem writing to task: %@", [exception description] );
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.task terminate];

    NSMenu *windowMenu = [self windowMenu];
    if ( [windowMenu indexOfItem:self.separator] != -1 )
        [windowMenu removeItem:self.separator];
    if ( [windowMenu indexOfItem:self.menuItem] != -1 )
        [windowMenu removeItem:self.menuItem];

    [visibleControllers removeObject:self];
}

@end
