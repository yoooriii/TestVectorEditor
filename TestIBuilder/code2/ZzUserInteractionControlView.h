//
//  ZzUserInteractionControlView.h
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZzUserInteractionControlViewDelegate.h"
//#import "ZGlassView.h"

@interface ZzUserInteractionControlView : UIView// ZGlassView// UIView
//  touch to select an object
//  touch a handler to resize/move a selected object
@property (nonatomic, weak) id<ZzUserInteractionControlViewDelegate>	delegate;
@property (nonatomic, assign) CGRect    selectionRect;
@property (nonatomic, assign) CGSize	minSelectionSize;
@property (nonatomic, assign, getter=isMoving) BOOL		moving;
@property (nonatomic, assign, getter=isResizing) BOOL		resizing;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, assign) CGFloat rotationAngle;
@end
