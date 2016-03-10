//
//  ZScrollView.m
//  TestIBuilder
//
//  Created by leonid lo on 3/9/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZScrollView.h"

extern CGSize CanvasSize;

@implementation ZScrollView

- (void)layoutSubviews
{
    const CGFloat scale = self.zoomScale;
    const CGSize scrollViewSize = self.frame.size;
    const CGSize scaledCanvasSize = CGSizeMake(CanvasSize.width * scale, CanvasSize.height * scale);


    CGRect contentRect = CGRectZero; // contentOffset & contentSize
    BOOL shouldUpdate = NO;



    const CGFloat deltaW = scrollViewSize.width - scaledCanvasSize.width;
    if (deltaW > 0) {
        contentRect.size.width = scaledCanvasSize.width;
        contentRect.origin.x = -deltaW/2.0;
        shouldUpdate = YES;
    }

    const CGFloat deltaH = scrollViewSize.height - scaledCanvasSize.height;
    if (deltaH > 0) {
        contentRect.size.height = scaledCanvasSize.height;
        contentRect.origin.y = -deltaH/2.0;
        shouldUpdate = YES;
    }



    if (shouldUpdate) {
        [super layoutSubviews];
//        self.contentSize = contentRect.size;
        self.contentOffset = contentRect.origin;

//        NSValue * value = [NSValue valueWithCGRect:contentRect];
//        [self performSelector:@selector(updateSccrollWithContentRect:) withObject:value afterDelay:0];
    }
    else
    {
        [super layoutSubviews];
    }
}



- (void)updateSccrollWithContentRect:(NSValue*)contentRectValue
{
    const CGRect contentRect = [contentRectValue CGRectValue];
    [UIView animateWithDuration:0.25 animations:^{
        self.contentSize = contentRect.size;
        self.contentOffset = contentRect.origin;
    }];
}

@end
