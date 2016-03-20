//
//  ZzUserInteractionControlViewDelegate.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

@class ZzUserInteractionControlView;

@protocol ZzUserInteractionControlViewDelegate <NSObject>

- (void)gestureHandlerViewBeganMoving:(ZzUserInteractionControlView*)view;
- (void)gestureHandlerViewMoved:(ZzUserInteractionControlView*)view;
- (void)gestureHandlerViewEndsMoving:(ZzUserInteractionControlView*)view;

- (void)gestureHandlerViewBeganRotating:(ZzUserInteractionControlView*)view;
- (void)gestureHandlerViewRotated:(ZzUserInteractionControlView*)view;
- (void)gestureHandlerViewEndsRotating:(ZzUserInteractionControlView*)view;

@end
