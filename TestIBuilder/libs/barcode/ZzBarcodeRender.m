//
//  ZzBarcodeRender.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/14/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZzBarcodeRender.h"
#import "ZzBarcodesCommon.h"
#import "ZBarcode.h"

typedef enum {
	kZBarcodeErrorTypeWarning = 0,
	kZBarcodeErrorTypeCritical = 1
} ZBarcodeErrorType;

BOOL drawBarcodeModelInContextPlain(CGContextRef cx, ZBarcode *barcodeModel, const CGRect renderRect);

BOOL drawBarcodeModelInContext_UPC(CGContextRef cx, ZBarcode *barcodeModel, const CGRect renderRect);

BOOL drawBarcodeModelInContextITF14(CGContextRef cx, ZBarcode *barcodeModel, const CGRect renderRect);

@implementation ZzBarcodeRender

//TODO: remove it or improve the logic
NSMutableAttributedString * measureText(NSString* text, UIFont** font, double width, double height)
{
	assert(nil != text);
	assert(nil != font);
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : *font}];
//	sizeToFitSize(string, CGSizeMake(width, height / 2.0f));
	if (font) {
		*font = [string attribute:NSFontAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [string length])];
	}
	return string;
}

//TODO: remove it or improve the logic
void sizeToFitSize(NSMutableAttributedString *string, CGSize size)
{
	
}


- (void)drawRenderRect:(CGRect)renderRect inContext:(CGContextRef)cx isEditing:(BOOL)editing
{
	//TODO: set bc model
	ZBarcode *barcodeModel = nil;
	
	BOOL finished = NO;
	BOOL success = NO;
	
	switch (barcodeModel.barcodeType) {
		case ZBarcodeTypeEAN8:
		case ZBarcodeTypeEAN13:
			LLog(@"EAN");
		case ZBarcodeTypeUPCE:
		case ZBarcodeTypeUPCA:
//			success = drawBarcodeModelInContext_UPC(cx, barcodeModel, renderRect);
			finished = YES;
			break;
			
			
		case ZBarcodeTypeC128A:
		case ZBarcodeTypeC128B:
		case ZBarcodeTypeC128C:
		case ZBarcodeTypeC128auto:
			LLog(@"128 family");
		case ZBarcodeType39:
		case ZBarcodeType39_43:
		case ZBarcodeTypeI25:
		case ZBarcodeTypeCodabar:
		{
			success = drawBarcodeModelInContextPlain(cx, barcodeModel, renderRect);
			finished = YES;
			break;
		}
			
		case ZBarcodeTypeITF14:
//			success = drawBarcodeModelInContextITF14(cx, barcodeModel, renderRect);
			finished = YES;
			break;
			
		case ZBarcodeTypeQRCode:
		{
//			success = drawQRCodeInContext(cx, barcodeModel, renderRect);
			break;
		}
		case ZBarcodeTypePDF417:
		{
//			success = drawPDF417InContext(cx, barcodeModel, renderRect);
			break;
		}
			
		default:	break;
	}
	
	if (!success) {
		//	and what now?
	}
	
	if (finished) {
		//	SKIP the rest
		return;
	}
	
}

BOOL drawBarcodeModelInContextPlain(CGContextRef cx, ZBarcode *barcodeModel, const CGRect renderRect)
{
	NSString *barcodeText = barcodeModel.text;
	if (!barcodeModel) {
		return NO;
	}
	
	const char *barcode_buffer = [barcodeModel encodedBuffer];
	if (!barcode_buffer || barcode_buffer[0] == '\0') {
		NSString *errorTitle = errorTitleWithCode([barcodeModel encodingError]);
		NSString *errorString = errorStringWithCode([barcodeModel encodingError]);
		drawErrorInContext(kZBarcodeErrorTypeCritical, cx, NSLocalizedString(errorTitle, "bc-render"), NSLocalizedString(errorString, "bc-render"), renderRect);
		return NO;
	}
	
	const CGFloat baritemWidth = [barcodeModel barItemWidth];
	const CGFloat barcodeWidth = [barcodeModel minimalWidth];
	
	if(barcodeWidth > renderRect.size.width)
	{
		drawErrorInContext(kZBarcodeErrorTypeWarning, cx, @"", NSLocalizedString(@"TryToIncreaseWidthText", "bc-render"), renderRect);
		return NO;
	}
	
	if (!barcodeText) {
#warning Leonid: the trouble is here, or rather in measureText
		return NO;
	}
	
	UIFont *font = barcodeModel.font;
	NSMutableAttributedString *text = measureText(barcodeText, &font, barcodeWidth, renderRect.size.height);
	CGSize textSize = [text size];
	const CGFloat heightText = ceilf(textSize.height);
	
	//	bar item to draw
	CGRect stripeRect = CGRectZero;
	
	//	find text Y position if text enabled
	CGFloat offsetTextY = 0;
	BOOL includeText = NO;
	switch (barcodeModel.barcodeCompound) {
		case ZBcCompoundBarcodeText:
			offsetTextY = renderRect.size.height - heightText;
			stripeRect.origin.y = 0;
			stripeRect.size.height = renderRect.size.height - heightText;
			includeText = YES;
			break;
		case ZBcCompoundTextBarcode:
			offsetTextY = 0;
			stripeRect.origin.y = heightText;
			stripeRect.size.height = renderRect.size.height - heightText;
			includeText = YES;
			break;
			//	no text
		default:
			offsetTextY = CGFLOAT_MIN;
			stripeRect.origin.y = 0;
			stripeRect.size.height = renderRect.size.height;
			includeText = NO;
			break;
	}
	
	// align horizontally
	const CGFloat deltaWidth = renderRect.size.width - barcodeWidth;
	CGFloat offsetX = 0;
	switch (barcodeModel.horizontalAlignment) {
		case ZHorizontalAlignmentCenter: {
			offsetX = deltaWidth/2.0;
			break;
		}
			
		case ZHorizontalAlignmentRight: {
			offsetX = deltaWidth;
			break;
		}
			
		default:
		case ZHorizontalAlignmentLeft: {
			offsetX = 0;
			break;
		}
	}
	
	//	DRAW barcode
	stripeRect.origin.x = offsetX;
	CGContextSetFillColorWithColor(cx, [[UIColor whiteColor] CGColor]);
	CGRect barcodeRect = stripeRect;
	barcodeRect.size.width = barcodeWidth;
	barcodeRect = CGRectInset(barcodeRect, -baritemWidth * 8.0f, 0.0f);
	CGContextFillRect(cx, barcodeRect);
	if (barcodeModel.barcodeType == ZBarcodeType39 || barcodeModel.barcodeType == ZBarcodeType39_43 || barcodeModel.barcodeType == ZBarcodeTypeI25 || barcodeModel.barcodeType == ZBarcodeTypeCodabar) {
		stripeRect.size.width = baritemWidth;
		for (size_t i = 0; barcode_buffer[i]; ++i) {
			const char code_char = barcode_buffer[i];
			if (code_char == '1') {
				CGContextAddRect(cx, stripeRect);
			}
			stripeRect.origin.x += stripeRect.size.width;
		}
	}
	else {
		BOOL blackON = YES;
		for (size_t i = 0; barcode_buffer[i]; ++i) {
			const size_t wl = barcode_buffer[i]-'0';
			stripeRect.size.width = baritemWidth * (CGFloat)wl;
			if (blackON) {
				CGContextAddRect(cx, stripeRect);
			}
			blackON = !blackON;
			stripeRect.origin.x += stripeRect.size.width;
		}
	}
	
	CGContextSetFillColorWithColor(cx, [UIColor blackColor].CGColor);
	CGContextFillPath(cx);
	
	//	DRAW text if enabled
	if (includeText) {
		
		NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
		paragraph.alignment = NSTextAlignmentCenter;
		NSNumber *underline = barcodeModel.underline ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
		NSDictionary *attributes = @{NSForegroundColorAttributeName : barcodeModel.textColor, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraph, NSUnderlineStyleAttributeName : underline};
		//	render text
		CGRect txtFrame = CGRectMake(offsetX, offsetTextY, barcodeWidth, heightText);
		drawStringWithAttributesInRectInContext(barcodeText, attributes, txtFrame, cx);
	}
	
	return YES;
}

//	Leonid: this method fixes wrong attributed string drawing in the ios-7-
void drawStringWithAttributesInRectInContext (NSString *str, NSDictionary *attributes, CGRect txtFrame, CGContextRef cx) {
	CGContextSaveGState(cx);
	CGContextTranslateCTM(cx, txtFrame.origin.x, txtFrame.origin.y);
	txtFrame.origin = CGPointZero;
	[str drawInRect:txtFrame withAttributes:attributes];
	CGContextRestoreGState(cx);
}

void drawErrorInContext(ZBarcodeErrorType errorType, CGContextRef cx, NSString *errorTitle, NSString *errorText, const CGRect renderRect)
{
	CGContextSaveGState(cx);
	
	UIImage *errorImage = (errorType == kZBarcodeErrorTypeCritical) ? [UIImage imageNamed:@"Error"] : [UIImage imageNamed:@"Caution"];
	
	CGFloat imageDimension = fminf(fminf(renderRect.size.width, renderRect.size.height) / 2.0f, 24.0f);
	
	[errorImage drawInRect:CGRectMake((renderRect.size.width - imageDimension) / 2.0f, renderRect.size.height / 2.0f - imageDimension, imageDimension, imageDimension)];
	
	if ([errorTitle length] > 0 || [errorText length] > 0)
	{
		if (!errorTitle)
		{
			errorTitle = @"";
		}
		if (!errorText)
		{
			errorText = @"";
		}
		NSMutableParagraphStyle *paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraph setAlignment:NSTextAlignmentCenter];
		NSMutableAttributedString *errorString = [[NSMutableAttributedString alloc] initWithString:errorTitle attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:[UIFont systemFontSize]],
																														   NSParagraphStyleAttributeName : paragraph}];
		if ([errorText length] > 0)
		{
			if ([errorTitle length] > 0)
			{
				[errorString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
			}
			[errorString appendAttributedString:[[NSAttributedString alloc] initWithString:errorText attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
																												  NSParagraphStyleAttributeName : paragraph}]];
		}
		sizeToFitSize(errorString, CGSizeMake(renderRect.size.width, renderRect.size.height / 2.0f));
		[errorString drawInRect:CGRectMake(0.0f, renderRect.size.height / 2.0f, renderRect.size.width, renderRect.size.height / 2.0f)];
	}
	CGContextRestoreGState(cx);
}


@end
