//
//  ZGestureHandlerView.h
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZGestureHandlerViewDelegate.h"

@interface ZGestureHandlerView : UIView
//  touch to select an object
//  touch a handler to resize/move a selected object
@property (nonatomic, weak) id<ZGestureHandlerViewDelegate>	delegate;
@property (nonatomic, assign) CGRect    selectionRect;
@property (nonatomic, assign) CGSize	minSelectionSize;
@property (nonatomic, assign, getter=isMoving) BOOL		moving;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@end
