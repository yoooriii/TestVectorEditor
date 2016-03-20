//
//  ZzBarcode1DView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/20/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZzBarcode1DView.h"
#import "ZBarcode.h"

@implementation ZzBarcode1DView
{
	CAShapeLayer * _barcodeLayer;
}

- (CAShapeLayer*)barcodeLayer {
	return _barcodeLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.clipsToBounds = NO;
		_barcodeLayer = [CAShapeLayer layer];
		[self.layer addSublayer:_barcodeLayer];
		_barcodeLayer.anchorPoint = CGPointZero;
		_barcodeLayer.lineWidth = 0;
		_barcodeLayer.fillColor = [UIColor blackColor].CGColor;
		_barcodeLayer.strokeColor = NULL;
		_barcodeLayer.lineJoin = kCALineJoinMiter;
		_barcodeLayer.lineCap = kCALineCapButt;
		_barcodeLayer.backgroundColor = NULL;
	}
	
	return self;
}

- (void)layoutSublayersOfLayer:(CALayer*)layer
{
	if (self.layer == layer)
	{
		CGPathRef path = self.barcodeLayer.path;
		if (!path) {
			return;
		}
		const CGRect barcodeRect = CGPathGetPathBoundingBox(path);
		const CGRect bounds = layer.bounds;
		const CGFloat itemWidth = self.barcodeModel.barItemWidth;
		
		//TODO: add: horizontal alignment; text area;
		self.barcodeLayer.affineTransform = CGAffineTransformMakeScale(itemWidth, bounds.size.height);
		self.barcodeLayer.frame = CGRectMake(0, 0, barcodeRect.size.width*itemWidth, 1);
	}
}

- (void)setBarcodeModel:(ZBarcode *)barcodeModel
{
	if (_barcodeModel != barcodeModel) {
		_barcodeModel = barcodeModel;
		if (barcodeModel) {
			self.barcodeLayer.hidden = NO;
			self.barcodeLayer.path = barcodeModel.CGPath;
			self.backgroundColor = barcodeModel.backgroundColor;
			self.barcodeLayer.fillColor = barcodeModel.foregroundColor.CGColor;
			[self setNeedsLayout];
		}
		else {
			self.barcodeLayer.hidden = YES;
			self.barcodeLayer.path = NULL;
		}
	}
}

@end
