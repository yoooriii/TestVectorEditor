//
//  ZzBarcodeDrawView.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/19/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZzBarcodeDrawView.h"
#import "ZzBarcodeRender.h"
#import "ZBarcode.h"

@interface MyFrameAction : NSObject <CAAction>
- (void)runActionForKey:(NSString *)event object:(id)anObject
			  arguments:(nullable NSDictionary *)dict;
@end

@implementation MyFrameAction

- (void)runActionForKey:(NSString *)event object:(CALayer*)layer
			  arguments:(nullable NSDictionary *)dict
{
	[layer setNeedsDisplay];
}

@end

@interface MyNothingAction : NSObject <CAAction>
- (void)runActionForKey:(NSString *)event object:(id)anObject
			  arguments:(nullable NSDictionary *)dict;
@end

@implementation MyNothingAction

- (void)runActionForKey:(NSString *)event object:(CALayer*)layer
			  arguments:(nullable NSDictionary *)dict
{
}

@end

#pragma mark -

@interface ZzBarcodeDrawView ()
@property (nonatomic, strong) ZzBarcodeRender * render;
@end

@implementation ZzBarcodeDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.layer.needsDisplayOnBoundsChange = YES;
		self.layer.drawsAsynchronously = YES;
	}
	
	return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)cx
{
	ZBarcode * barcodeModel = self.barcodeModel;
	
	CGColorRef fillColor = barcodeModel.backgroundColor ? barcodeModel.backgroundColor.CGColor : [UIColor whiteColor].CGColor;
	CGContextSetFillColorWithColor(cx, fillColor);
	CGContextFillRect(cx, layer.bounds);
	
	CGPathRef bcPath = barcodeModel.CGPath;
	if (!bcPath) {
		return;
	}
	
	const CGRect box = CGPathGetPathBoundingBox(bcPath);
	if (CGRectEqualToRect(box, CGRectNull)) {
		return;
	}

	const CGFloat offsetX = 0;
	const CGFloat baritemWidth = barcodeModel.barItemWidth;
	const CGRect renderRect = layer.bounds;
	const CGFloat barcodeWidth = box.size.width * baritemWidth;

	
	//	drawing
	const CGFloat barInsetX = baritemWidth * 8.0;
	const CGRect barcodeRect = CGRectMake(offsetX - barInsetX, 0, barcodeWidth + 2.0* barInsetX, renderRect.size.height);
	//	draw bg
	CGColorRef bgColor = barcodeModel.backgroundColor ? barcodeModel.backgroundColor.CGColor : [UIColor whiteColor].CGColor;
	bgColor = [UIColor yellowColor].CGColor;
	CGContextSetFillColorWithColor(cx, bgColor);
	CGContextFillRect(cx, barcodeRect);
	//	draw barcode itself
	CGColorRef foregroundColor = barcodeModel.foregroundColor ? barcodeModel.foregroundColor.CGColor : [UIColor blackColor].CGColor;
	CGContextSetFillColorWithColor(cx, foregroundColor);
	CGAffineTransform ttt1 = CGAffineTransformMakeTranslation(offsetX, 2);
	CGAffineTransform ttt2 = CGAffineTransformScale(ttt1, baritemWidth, renderRect.size.height-5);
	CGPathRef ppp2 = CGPathCreateCopyByTransformingPath(bcPath, &ttt2);
	CGContextAddPath(cx, ppp2);//, bcPath);
	CGContextFillPath(cx);
	CGPathRelease(ppp2), ppp2 = NULL;
	return;
	
	[self.render drawRenderRect:layer.bounds inContext:cx isEditing:NO];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
	if ([event isEqualToString:@"bounds"]) {
		return [MyFrameAction new];
	}
	if ([event isEqualToString:@"position"]) {
		return [MyNothingAction new];
	}
	return nil;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef cx = UIGraphicsGetCurrentContext();
	[self.render drawRenderRect:rect inContext:cx isEditing:NO];
}

- (void)setBarcodeModel:(ZBarcode *)barcodeModel
{
	if (_barcodeModel != barcodeModel) {
		_barcodeModel = barcodeModel;
		self.render.barcodeModel = barcodeModel;
		[self setNeedsDisplay];
	}
}

- (ZzBarcodeRender*)render
{
	if (!_render) {
		_render = [ZzBarcodeRender new];
	}
	
	return _render;
}

@end
