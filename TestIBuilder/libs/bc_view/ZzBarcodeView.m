//
//  ZzBarcodeView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZzBarcodeView.h"
#import "ZzBarcodeLayer.h"

@interface ZzBarcodeView ()
@property (nonatomic, readonly) ZzBarcodeLayer *barcodeLayer;
@end

@implementation ZzBarcodeView

+ (Class)layerClass
{
	return [ZzBarcodeLayer class];
}

- (ZzBarcodeLayer*)barcodeLayer
{
	return (ZzBarcodeLayer*)self.layer;
}

- (void)setBarcodeModel:(ZBarcode *)barcodeModel
{
	if (_barcodeModel != barcodeModel) {
		_barcodeModel = barcodeModel;
		self.barcodeModel = barcodeModel;
		[self.layer setNeedsLayout];
		[self.layer setNeedsDisplay];
		
		self.barcodeLayer.textLayer.foregroundColor = [UIColor blackColor].CGColor;
		self.barcodeLayer.textLayer.string = barcodeModel.text;
		self.barcodeLayer.textLayer.alignmentMode = kCAAlignmentCenter;
		
		UIBezierPath* bezier = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(5, 5, 30, 30) cornerRadius:5];
		self.barcodeLayer.shapeLayer.path = bezier.CGPath;
		self.barcodeLayer.shapeLayer.fillColor = [UIColor redColor].CGColor;
		self.barcodeLayer.shapeLayer.strokeColor = [UIColor blueColor].CGColor;
		self.barcodeLayer.shapeLayer.lineWidth = 2;
	}
}

@end
