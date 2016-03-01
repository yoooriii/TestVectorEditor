//
//  ZBasicObjectView.m
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZBasicObjectView.h"

@implementation ZBasicObjectView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.backgroundColor = [UIColor redColor];
	}
	
	return self;
}

- (ZCanvasView *)canvas
{
	return (ZCanvasView *)self.superview;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p> [%@] sel%@;", [self class], self,
			NSStringFromCGRect(self.frame), self.selected?@"+":@"-"];
}

@end
