//
//  ZGestureHandlerVC.h
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZzUserInteractionControlView;

@interface ZGestureHandlerVC : UIViewController

@property (nonatomic, readonly) ZzUserInteractionControlView * gestureHandlerView;
- (void)handleScrollRecognizers:(NSArray<UIGestureRecognizer*>*)scrollRecognizers;

@end
