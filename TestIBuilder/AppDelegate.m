//
//  AppDelegate.m
//  TestIBuilder
//
//  Created by leonid lo on 2/26/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "AppDelegate.h"
#import "ZGestureHandlerVC.h"
#import "ZEditorViewController.h"
#import "ZGestureHandlerView.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    ZGestureHandlerVC *_gestureHandlerVC;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UIViewController* ctr = [sb instantiateViewControllerWithIdentifier:@"emptyVC"];

	ZEditorViewController * rootVC = [ZEditorViewController new];
	self.window.rootViewController = rootVC;
	[self.window makeKeyAndVisible];

    self.window.translatesAutoresizingMaskIntoConstraints = YES;
	[self addGestureHandler];
	
	_gestureHandlerVC.gestureHandlerView.delegate = rootVC;
	rootVC.gestureHandlerView = _gestureHandlerVC.gestureHandlerView;
	
//    [self performSelector:@selector(addGestureHandler) withObject:nil afterDelay:0.1];

    return YES;
}

- (void)addGestureHandler
{
    ZGestureHandlerVC * ctr = [ZGestureHandlerVC new];
    _gestureHandlerVC = ctr;
    ctr.view.frame = self.window.bounds;
    [self.window addSubview:ctr.view];

    [self.window removeConstraints:self.window.constraints];
    [ctr.view removeConstraints:ctr.view.constraints];

    const CGFloat constant = 30;

    [self.window addConstraint:[NSLayoutConstraint constraintWithItem:ctr.view
                                                            attribute:NSLayoutAttributeLeading
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.window
                                                            attribute:NSLayoutAttributeLeading
                                                           multiplier:1
                                                             constant:constant]
     ];

    [self.window addConstraint:[NSLayoutConstraint constraintWithItem:self.window
                                                            attribute:NSLayoutAttributeTrailing
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:ctr.view
                                                            attribute:NSLayoutAttributeTrailing
                                                           multiplier:1
                                                             constant:constant]
     ];

    [self.window addConstraint:[NSLayoutConstraint constraintWithItem:ctr.view
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.window
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1
                                                             constant:constant]
     ];

    [self.window addConstraint:[NSLayoutConstraint constraintWithItem:self.window
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:ctr.view
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1
                                                             constant:constant]
     ];

    return;


    if (1) {
        NSLayoutConstraint *x0 = [NSLayoutConstraint constraintWithItem:self.window attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:ctr.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
        [self.window addConstraint:x0];


        NSLayoutConstraint *x1 = [NSLayoutConstraint constraintWithItem:ctr.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.window attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
        [self.window addConstraint:x1];
    }
    else {
        UIView * view = ctr.view;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);

        NSUInteger options = NSLayoutAttributeLeading | NSLayoutAttributeTrailing;

        [self.window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[view]-|" options:options metrics:nil views:views]];
        
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
