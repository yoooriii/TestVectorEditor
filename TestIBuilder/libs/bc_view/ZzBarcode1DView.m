//
//  ZzBarcode1DView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/20/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZzBarcode1DView.h"
#import "ZBarcode.h"

@interface ZzBarcode1DView ()
@property (nonatomic, readonly) CAShapeLayer * barcodeLayer;
@property (nonatomic, readonly) CATextLayer * textLayer;
@end

@implementation ZzBarcode1DView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.clipsToBounds = NO;
		_barcodeLayer = [CAShapeLayer layer];
		[self.layer addSublayer:self.barcodeLayer];
		self.barcodeLayer.anchorPoint = CGPointZero;
		self.barcodeLayer.fillColor = [UIColor blackColor].CGColor;
		self.barcodeLayer.backgroundColor = NULL;
		self.barcodeLayer.strokeColor = NULL;
		self.barcodeLayer.lineJoin = kCALineJoinMiter;
		self.barcodeLayer.lineCap = kCALineCapButt;
		self.barcodeLayer.lineWidth = 0;
		
		_textLayer = [CATextLayer layer];
		[self.layer addSublayer:self.textLayer];
		self.textLayer.anchorPoint = CGPointZero;
		self.textLayer.font = (__bridge CFTypeRef _Nullable)(@"Courier");
		self.textLayer.fontSize = 14;
		self.textLayer.alignmentMode = kCAAlignmentCenter;
		self.textLayer.truncationMode = kCATruncationNone;
		self.textLayer.wrapped = NO;
		self.textLayer.backgroundColor = NULL;
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
		const CGFloat bcWidth = barcodeRect.size.width*itemWidth;
		const CGFloat boxHeight = bounds.size.height;
		const CGFloat txtHeight = self.textLayer.hidden ? 0 : (self.textLayer.fontSize + 4);//+margins
		const CGFloat bcHeight = MAX((boxHeight - txtHeight), 0);
		
		//TODO: add: horizontal alignment; text area;
		self.barcodeLayer.affineTransform = CGAffineTransformMakeScale(itemWidth, boxHeight);
		self.barcodeLayer.frame = CGRectMake(0, 0, bcWidth, 1);
		
		if (!self.textLayer.hidden) {
			self.textLayer.frame = CGRectMake(0, bcHeight, bounds.size.width, txtHeight);
		}
	}
}

- (void)setBarcodeModel:(ZBarcode *)barcodeModel
{
	if (_barcodeModel != barcodeModel) {
		_barcodeModel = barcodeModel;
		[self updateContent];
	}
}

- (void)updateContent
{
	if (self.barcodeModel) {
		self.textLayer.hidden = NO;
		CGColorRef foregroundColor = (self.barcodeModel.foregroundColor ?: [UIColor blackColor]).CGColor;
		UIColor * backgroundColor = self.barcodeModel.backgroundColor ?: [UIColor whiteColor];
		self.barcodeLayer.path = self.barcodeModel.CGPath;
		self.backgroundColor = backgroundColor;
		self.barcodeLayer.fillColor = foregroundColor;
		
		self.textLayer.foregroundColor = foregroundColor;
		NSString* text = self.barcodeModel.displayText;
		if (1) {
			text = @"Hello Lee!";
		}
		self.textLayer.string = text;
		self.barcodeLayer.hidden = (0 != text.length);
		
		[self setNeedsLayout];
	}
	else {
		self.textLayer.hidden = YES;
		self.barcodeLayer.hidden = YES;
		self.barcodeLayer.path = NULL;
	}
}

@end
