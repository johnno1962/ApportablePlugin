//
//  APLogController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APLogController.h"

@implementation APLogController

- (NSString *)filterLinesByCurrentRegularExpression:(NSArray *)lines
{
    NSMutableString *out = [[NSMutableString alloc] init];
    NSRegularExpression *filterRegexp = [NSRegularExpression regularExpressionWithPattern:self.filter.stringValue
                                                                                  options:0 error:NULL];
    for ( NSString *line in lines ) {
        if ( !filterRegexp ||
            [filterRegexp rangeOfFirstMatchInString:line options:0
                                              range:NSMakeRange(0, [line length])].location != NSNotFound ) {
            [out appendString:line];
            [out appendString:@"\n"];
        }
    }

    return out;
}

- (IBAction)filterChange:sender
{
    self.console.string = [self filterLinesByCurrentRegularExpression:self.lineBuffer];
}

- (void)insertText:(NSString *)outStr
{
    NSMutableArray *newLlines = [[outStr componentsSeparatedByString:@"\n"] mutableCopy];

    if ( [newLlines count] && [newLlines[[newLlines count]-1] length] == 0 )
        [newLlines removeObjectAtIndex:[newLlines count]-1];

    if ( !_lineBuffer )
        _lineBuffer = [[NSMutableArray alloc] init];
    [self.lineBuffer addObjectsFromArray:newLlines];

    [self.console insertText:[self filterLinesByCurrentRegularExpression:newLlines]];
}

@end
