//
//  ZBasicObjectView.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZCanvasView;

@interface ZBasicObjectView : UIView
@property (nonatomic, weak, readonly) ZCanvasView * canvas;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@end
