//
//  ZGlassView.m
//  TestIBuilder
//
//  Created by leonid lo on 3/9/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZGlassView.h"

@implementation ZGlassView
{
    BOOL ibMode; // u may use TARGET_INTERFACE_BUILDER instead
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView * hitView = [super hitTest:point withEvent:event];
    return (self == hitView) ? nil : hitView;
}

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    ibMode = YES;
}

- (void)drawRect:(CGRect)rect
{
#if TARGET_INTERFACE_BUILDER
    if (ibMode)
    {
        UIBezierPath * bp = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 20, 20) cornerRadius:30];
        [[UIColor clearColor] set];
        [self.fillColor setFill];
        [self.strokeColor setStroke];
        bp.lineWidth = self.lineWidth;
        [bp fill];
        [bp stroke];
    }
#endif
}

@end
