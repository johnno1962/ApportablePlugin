//
//  APDebugController.m
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/06/2014.
//
//

#import "APDebugController.h"

#import "APPluginMenuController.h"

@interface NSObject(APMethodsUsed)
+ (NSImage *)iconImage_pause;
+ (NSImage *)iconImage_resume;
@end

@interface APDebugController()

@property (nonatomic,retain) IBOutlet NSView *scrollView;

@property (nonatomic,retain) NSButton *pauseResume;
@property (nonatomic,retain) NSTextView *debugger;

@end

static id pauseTarget;

@implementation APDebugController

- (instancetype)initNib:(NSString *)nibName project:(NSString *)projectRoot command:(NSString *)command
{
    self = [super initNib:nibName project:projectRoot command:command];

    [self findConsole:[[APPluginMenuController sharedPlugin].lastKeyWindow contentView]];
    NSView *splitView = self.debugger;
    for ( int i=0 ; i<8 ; i++ )
        splitView = [splitView superview];
    self.scrollView.frame = splitView.frame;
    [[splitView superview] addSubview:self.scrollView];

    if ( [[[self.pauseResume target] class] respondsToSelector:@selector(iconImage_pause)] )
        pauseTarget = [self.pauseResume target];
    self.pauseResume.enabled = TRUE;
    self.pauseResume.target = self;
    return self;
}

- (void)findConsole:(NSView *)view
{
    for ( NSView *subview in [view subviews] ) {
        if ( [subview isKindOfClass:[NSButton class]] &&
            [(NSButton *)subview action] == @selector(pauseOrResume:) )
            self.pauseResume = (NSButton *)subview;
        if ( [subview class] == NSClassFromString(@"IDEConsoleTextView") )
            self.debugger = (NSTextView *)subview;
        [self findConsole:subview];
    }
}

- (void)pauseOrResume:sender
{
    if ( [self.pauseResume image] == [[pauseTarget class] iconImage_pause] ) {
        self.pauseResume.image = [[pauseTarget class] iconImage_resume];
        [self.task interrupt];
    }
    else {
        self.pauseResume.image = [[pauseTarget class] iconImage_pause];
        [self sendTask:@"c\n"];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    self.pauseResume.image = [[pauseTarget class] iconImage_pause];
    self.pauseResume.target = pauseTarget;
    [self.scrollView removeFromSuperview];
    [super windowWillClose:notification];
}

@end
