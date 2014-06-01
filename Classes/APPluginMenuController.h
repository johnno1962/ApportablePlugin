//
//  APPluginMenuController.h
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APPluginMenuController : NSObject

@property (nonatomic,strong) NSWindow *lastKeyWindow;

+ (APPluginMenuController *)sharedPlugin;

@end
