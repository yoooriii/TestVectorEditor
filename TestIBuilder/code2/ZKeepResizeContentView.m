//
//  ZKeepResizeContentView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/13/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZKeepResizeContentView.h"

@implementation ZKeepResizeContentView

- (void)layoutSubviews {
	const CGRect bounds = self.bounds;
	for (UIView * aView in self.subviewsToResize) {
		aView.frame = bounds;
	}
}

@end
