//
//  APTextView.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APTextView.h"
#import "APConsoleController.h"

@implementation APTextView

- (void)keyDown:(NSEvent *)theEvent
{
    if ( ![(APConsoleController *)self.delegate handleTextViewInput:[theEvent characters]] )
        [super keyDown:theEvent];
}

- (void)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *input = [pb stringForType:NSPasteboardTypeString];
    if ( ![(APConsoleController *)self.delegate handleTextViewInput:input] )
        [super paste:sender];
}

@end
