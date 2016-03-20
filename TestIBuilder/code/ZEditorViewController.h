//
//  ZEditorViewController.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZzUserInteractionControlViewDelegate.h"

@class ZzUserInteractionControlView;

@interface ZEditorViewController : UIViewController <ZzUserInteractionControlViewDelegate>
@property (nonatomic, readonly) UIScrollView * scrollView;
@property (nonatomic, weak) ZzUserInteractionControlView	* gestureHandlerView;
@end
