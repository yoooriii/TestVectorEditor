//
//  ZCanvasView.h
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBasicObjectView;

@interface ZCanvasView : UIView

@property (nonatomic, strong, readonly) NSArray<ZBasicObjectView*>* allObjects;
@property (nonatomic, weak) ZBasicObjectView * selectedObject;
- (BOOL)addObject:(ZBasicObjectView*)object;
- (BOOL)removeObject:(ZBasicObjectView*)object;

@end
