//
//  ZzBarcodeLayer.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZzBarcodeLayer.h"

@implementation ZzBarcodeLayer

- (instancetype)init
{
	if ((self = [super init]))
	{
		[self internalInit];
	}
	return self;
}

- (void)internalInit
{
	LLog(@"+++");
	_shapeLayer = [CAShapeLayer layer];
	[self addSublayer:self.shapeLayer];
	self.shapeLayer.anchorPoint = CGPointZero;
	
	_textLayer = [CATextLayer layer];
	[self addSublayer:self.textLayer];
	self.textLayer.anchorPoint = CGPointZero;
	self.textLayer.delegate = self;
	
	if (1) {
		self.textLayer.cornerRadius = 2;
		self.textLayer.borderColor = [UIColor blackColor].CGColor;
		self.textLayer.borderWidth = 1;
		
		self.shapeLayer.cornerRadius = 2;
		self.shapeLayer.borderColor = [UIColor brownColor].CGColor;
		self.shapeLayer.borderWidth = 1;
	}
}

- (void)layoutSublayers
{
	CGRect bounds = self.bounds;
	CGRect shapeBounds = bounds;
	shapeBounds.size.height *= 0.75;
	self.shapeLayer.frame = shapeBounds;
	
	CGRect textBounds = bounds;
	textBounds.size.height -= shapeBounds.size.height;
	textBounds.origin.y = shapeBounds.size.height;
	self.textLayer.frame = textBounds;
	
	LLog(@"anim:%@", self.textLayer.animationKeys);
}

- (CAAnimation *)animationForKey:(NSString *)key
{
	LLog(@"key:%@", key);
	return [super animationForKey:key];
}

- (nullable id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event;
{
	LLog(@"key:%@", event);
	return nil;;
}

@end
