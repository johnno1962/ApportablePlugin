//
//  APLiveCoding.h
//  ApportablePlugin
//
//  Created by John Holdsworth on 03/05/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#ifndef _APLiveCoding_h_
#define _APLiveCoding_h_

#import <Foundation/Foundation.h>

#define kINNotification @"INJECTION_BUNDLE_NOTIFICATION"

#ifdef DEBUG
#define _instatic
#else
#define _instatic static
#endif

#define _inglobal

#define _inval( _val... ) = _val

@interface APLiveCoding : NSObject

+ (void)loadedClass:(Class)newClass notify:(BOOL)notify;
+ (void)loadedNotify:(BOOL)notify hook:(void *)hook;

@end

#endif
