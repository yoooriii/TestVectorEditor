//
//  ZRulerView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/1/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZRulerView.h"

static const CGFloat DefaultWidth = 25;

@implementation ZRulerView

+ (Class)layerClass
{
	return [CAShapeLayer class];
}

- (CAShapeLayer*)shapeLayer
{
	return (CAShapeLayer*)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		[self _internalInit];
	}
	
	return self;
}

- (void)_internalInit
{
	self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	self.shapeLayer.lineWidth = 1;
	self.shapeLayer.strokeColor = [UIColor blackColor].CGColor;
	self.shapeLayer.fillColor = nil;
	self.userInteractionEnabled = NO;
	
	[self updateShapeLayer];
}

- (void)layoutSubviews
{
	[self updateShapeLayer];
}

- (void)updateShapeLayer
{
	const CGFloat RulerStep = 12;
	
	const CGRect bounds = self.bounds;
	UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:bounds];
	
	if (self.vertical) {
		const CGFloat minX = 5;
		const CGFloat maxX = CGRectGetMaxX(bounds) - minX + 1;
		CGPoint pt = CGPointMake(minX, DefaultWidth);
		for (; pt.y < bounds.size.height; pt.y += RulerStep) {
			[bezier moveToPoint:pt];
			pt.x = maxX;
			[bezier addLineToPoint:pt];
			pt.x = minX;
		}
	}
	else {
		const CGFloat minY = 5;
		const CGFloat maxY = CGRectGetMaxY(bounds) - minY + 1;
		CGPoint pt = CGPointMake(DefaultWidth, minY);
		for (; pt.x < bounds.size.width; pt.x += RulerStep) {
			[bezier moveToPoint:pt];
			pt.y = maxY;
			[bezier addLineToPoint:pt];
			pt.y = minY;
		}
	}
	
	self.shapeLayer.path = bezier.CGPath;
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return self.vertical ? CGSizeMake(DefaultWidth, size.height) : CGSizeMake(size.width, DefaultWidth);
}

@end
