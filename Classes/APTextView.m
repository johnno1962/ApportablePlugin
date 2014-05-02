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
    [(APConsoleController *)self.delegate keyDownInTextViewEvent:theEvent];
}

@end
