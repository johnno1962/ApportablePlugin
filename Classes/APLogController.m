//
//  APLogController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APLogController.h"

@interface APLogController()

@property (nonatomic,assign) IBOutlet NSSearchField *filter;
@property (nonatomic,assign) IBOutlet NSButton *paused;

@property (nonatomic,strong) NSMutableArray *lineBuffer;
@property (atomic,strong) NSMutableString *incoming;
@property (atomic,strong) NSLock *lock;

@end

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

- (void)insertText:(NSString *)output
{
    if ( !self.lock )
        self.lock = [[NSLock alloc] init];

    [self.lock lock];
    if ( !self.incoming )
        self.incoming = [[NSMutableString alloc] init];
    [self.incoming appendString:output];
    [self.lock unlock];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self insertIncoming];
    });

}

- (void)insertIncoming
{
    if ( !self.incoming )
        return;

    [self.lock lock];
    NSMutableArray *newLlines = [[self.incoming componentsSeparatedByString:@"\n"] mutableCopy];
    self.incoming = nil;
    [self.lock unlock];

    NSUInteger lineCount = [newLlines count];
    if ( lineCount && [newLlines[lineCount-1] length] == 0 )
        [newLlines removeObjectAtIndex:lineCount-1];

    if ( !self.lineBuffer )
        self.lineBuffer = [[NSMutableArray alloc] init];
    [self.lineBuffer addObjectsFromArray:newLlines];

    if ( ![self.paused state] ) {
        NSString *filtered = [self filterLinesByCurrentRegularExpression:newLlines];
        if ( [filtered length] )
            [super insertText:filtered];
    }

}

- (IBAction)pausePlay:sender
{
    if ( [self.paused state] ) {
        [self.paused setImage:[self imageNamed:@"play"]];
    }
    else {
        [self.paused setImage:[self imageNamed:@"pause"]];
        [self filterChange:self];
    }
}

- (NSImage *)imageNamed:(NSString *)name
{
    return [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]]
                                                    pathForResource:name ofType:@"png"]];
}

@end
