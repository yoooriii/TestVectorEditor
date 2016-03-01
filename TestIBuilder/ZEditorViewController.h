//
//  ZEditorViewController.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZGestureHandlerViewDelegate.h"

@class ZGestureHandlerView;

@interface ZEditorViewController : UIViewController <ZGestureHandlerViewDelegate>
@property (nonatomic, weak) ZGestureHandlerView	* gestureHandlerView;
@end
