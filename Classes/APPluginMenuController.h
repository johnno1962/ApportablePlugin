//
//  APMenuConctroller.h
//  ApportablePlugin
//
//  Created by John Holdsworth on 01/05/2014.
//
//

#import <Cocoa/Cocoa.h>

@interface APPluginMenuController : NSObject

@property (nonatomic,strong) IBOutlet NSMenuItem *apportableMenu;
@property (nonatomic,strong) id lastDelegate;

@end
