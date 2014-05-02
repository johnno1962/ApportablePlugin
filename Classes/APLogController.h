//
//  APLogController.h
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "APConsoleController.h"

@interface APLogController : APConsoleController

@property (nonatomic,assign) IBOutlet NSSearchField *filter;
@property (nonatomic,strong) NSMutableArray *lineBuffer;

@end
