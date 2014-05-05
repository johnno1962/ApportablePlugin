//
//  INAppDelegate.h
//  InjectionDemo
//
//  Created by John Holdsworth on 22/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class INViewController;

@interface INAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) INViewController *viewController;

@end
