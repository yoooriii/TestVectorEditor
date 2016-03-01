//
//  ZGestureHandlerViewDelegate.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

@class ZGestureHandlerView;

@protocol ZGestureHandlerViewDelegate <NSObject>

- (void)gestureHandlerViewBeginsMoving:(ZGestureHandlerView*)view;
- (void)gestureHandlerViewMoved:(ZGestureHandlerView*)view;
- (void)gestureHandlerViewEndsMoving:(ZGestureHandlerView*)view;
- (void)gestureHandlerViewDidTap:(ZGestureHandlerView*)view point:(CGPoint)point;

@end
