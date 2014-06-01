//
//  APConsoleController.h
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APConsoleController : NSObject <NSWindowDelegate,NSTextViewDelegate>

@property (nonatomic,assign) IBOutlet NSTextView *console;
@property (nonatomic,strong) NSTask *task;

- (instancetype)initNib:(NSString *)nibName project:(NSString *)projectRoot command:(NSString *)command;
- (void)runTask:(NSTask *)task sendOnCompletetion:(NSString *)gdbCommand;
- (BOOL)handleTextViewInput:(NSString *)characters;
- (void)insertText:(NSString *)output;
- (void)sendTask:(NSString *)input;

@end
