//
//  ZGlassView.h
//  TestIBuilder
//
//  Created by leonid lo on 3/9/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface ZGlassView : UIView

@property (nonatomic) IBInspectable CGFloat lineWidth;
@property (nonatomic) IBInspectable UIColor * fillColor;
@property (nonatomic) IBInspectable UIColor * strokeColor;


@end
