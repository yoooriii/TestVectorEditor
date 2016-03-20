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
#import "ZBarTextItem.h"

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
	ZBarcode *barcodeModel = self.barcodeModel;
	
	BOOL finished = NO;
	BOOL success = NO;
	
	switch (barcodeModel.symbology) {
		case ZBarcodeTypeEAN8:
		case ZBarcodeTypeEAN13:
			LLog(@"EAN");
		case ZBarcodeTypeUPCE:
		case ZBarcodeTypeUPCA:
			success = drawBarcodeModelInContext_UPC(cx, barcodeModel, renderRect);
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
	if (barcodeModel.symbology == ZBarcodeType39 || barcodeModel.symbology == ZBarcodeType39_43 || barcodeModel.symbology == ZBarcodeTypeI25 || barcodeModel.symbology == ZBarcodeTypeCodabar) {
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
		NSDictionary *attributes = @{NSForegroundColorAttributeName : barcodeModel.foregroundColor, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraph, NSUnderlineStyleAttributeName : underline};
		//	render text
		CGRect txtFrame = CGRectMake(offsetX, offsetTextY, barcodeWidth, heightText);
		drawStringWithAttributesInRectInContext(barcodeText, attributes, txtFrame, cx);
	}
	
	return YES;
}

CGPathRef createBarcodePath_UPC(ZBarcode *barcodeModel)
{
	assert(nil != barcodeModel);
	const short * const pattern_of_barcode = barcode_pattern_bar_UPC(barcodeModel.symbology);
	if (!pattern_of_barcode) {
		return NULL;
	}

	const char ** barcodeCSubstrings = [barcodeModel encodedSubstrings];
	CGMutablePathRef bcPath = CGPathCreateMutable();
	CGRect stripeRect = CGRectMake(0, 0, 0, 1);
	bool blackON = true;
	int i_pattern = -1;
	short pattern_len = 0;
	for (size_t n=0; barcodeCSubstrings[n]; ++n) {
		const char * codestring = barcodeCSubstrings[n];
		const size_t cs_length = strlen(codestring);
		
		if (pattern_len > 0) {
			--pattern_len;
		}
		if (pattern_len == 0) {
			pattern_len = pattern_of_barcode[++i_pattern];
		}
		
		//	draw next barcode element
		for (size_t i = 0, l = 0; i < cs_length; ++i) {
			const size_t wl = codestring[i]-'0';
			stripeRect.size.width = (CGFloat)wl;
			if (blackON) {
				CGPathAddRect(bcPath, NULL, stripeRect);
			}
			blackON = !blackON;
			l += wl;
			stripeRect.origin.x += stripeRect.size.width;
		}
	}
	
	return bcPath;
}

BOOL drawBarcodeModelInContext_UPC(CGContextRef cx, ZBarcode *barcodeModel, const CGRect renderRect)
{
	NSString *barcodeText = barcodeModel.text;
	if (!barcodeModel || !barcodeText.length) {
		drawErrorInContext(kZBarcodeErrorTypeCritical, cx, @"", NSLocalizedString(@"BarcodeErrorEmptyString", @"barcode"), renderRect);
		return NO;
	}
	
	const char *  formattedCString = [barcodeModel stringToShow];
	const char ** barcodeCSubstrings = [barcodeModel encodedSubstrings];
	
	const short * const pattern_of_barcode = barcode_pattern_bar_UPC(barcodeModel.symbology);
	
	if (!formattedCString || !barcodeCSubstrings) {
		NSString *errorTitle = errorTitleWithCode([barcodeModel encodingError]);
		NSString *errorString = errorStringWithCode([barcodeModel encodingError]);
		drawErrorInContext(kZBarcodeErrorTypeCritical, cx, NSLocalizedString(errorTitle, @"barcode"), NSLocalizedString(errorString, @"barcode"), renderRect);
		return NO;
	}
	
	if (!pattern_of_barcode) {
		NSLog(@"NULL pointer, skip the rest");
		return NO;
	}
	
	NSArray *allStringItems = [barcodeModel substringsToShow];
	
	//	divide barcode area into parts
	NSMutableArray *allBarAreaLengths = [NSMutableArray arrayWithCapacity:8];
	size_t bar_whole_length = 0;
	size_t i_offset = 0;
	for (size_t i=0; pattern_of_barcode[i] >= 0; ++i) {
		const short items_number = pattern_of_barcode[i];
		size_t item_length = 0;
		for (size_t j=0; j < items_number; ++j) {
			item_length += substring_item_length(barcodeCSubstrings[i_offset+j]);
		}
		[allBarAreaLengths addObject:@(item_length)];
		bar_whole_length += item_length;
		i_offset += items_number;
	}
	
	switch (barcodeModel.symbology) {
		case ZBarcodeTypeUPCE: {
			ZBarTextItem *btItem = allStringItems[1];
			btItem.length = [allBarAreaLengths[1] integerValue];
			break;
		}
			
		case ZBarcodeTypeUPCA: {
			ZBarTextItem *btItem = allStringItems[1];
			btItem.length = [allBarAreaLengths[1] integerValue];
			
			btItem = allStringItems[2];
			btItem.length = [allBarAreaLengths[3] integerValue];
			break;
		}
			
		default:
			break;
	}
	
	const CGFloat baritemWidth = [barcodeModel barItemWidth];
	//	find suitable font (adjust font size)
	UIFont *font = barcodeModel.font;
	ZBarTextItem *aSubitem = allStringItems[1];
	NSString *aSubstring = aSubitem.string;
	const CGFloat substringWidth = (CGFloat)[allBarAreaLengths[1] integerValue] * baritemWidth;
	
	NSMutableAttributedString *string = measureText(aSubstring, &font, substringWidth, renderRect.size.height);
	if (allStringItems.count == 4) {
		aSubitem = allStringItems[2];
		aSubstring = aSubitem.string;
		const CGFloat substringWidth = (CGFloat)[allBarAreaLengths[1] integerValue] * baritemWidth;
		string = measureText(aSubstring, &font, substringWidth, renderRect.size.height);
	}
	
	//	calculate string sizes and find max height
	CGFloat maxStrHeight = 0;
	for (ZBarTextItem *anItem in allStringItems) {
		[anItem updateSizeWithFont:font];
		if (anItem.stringSize.height > maxStrHeight) {
			maxStrHeight = anItem.stringSize.height;
		}
	}
	
	const CGFloat heightText = ceilf(maxStrHeight);
	
	//	find text Y position if text enabled
	CGFloat offsetTextY = 0;
	BOOL includeText = NO;
	switch (barcodeModel.barcodeCompound) {
		case ZBcCompoundBarcodeText:
			offsetTextY = renderRect.size.height - heightText;
			includeText = YES;
			break;
		case ZBcCompoundTextBarcode:
			offsetTextY = 0;
			includeText = YES;
			break;
			//	no text
		default:
			offsetTextY = CGFLOAT_MIN;
			includeText = NO;
			break;
	}
	
	// align horizontally
	const CGFloat barcodeWidth = bar_whole_length * baritemWidth;
	const CGFloat barcodeFullWidth = barcodeWidth + (!includeText ? 0 :
										[allStringItems.firstObject stringSize].width + [allStringItems.lastObject stringSize].width);
	const CGFloat deltaWidth = renderRect.size.width - barcodeWidth;
	
	if(barcodeFullWidth > renderRect.size.width)
	{
		drawErrorInContext(kZBarcodeErrorTypeWarning, cx, @"", NSLocalizedString(@"TryToIncreaseWidthText", @"barcode"), renderRect);
		return NO;
	}
	
	CGFloat offsetX = 0;
	switch (barcodeModel.horizontalAlignment) {
		case ZHorizontalAlignmentCenter: {
			ZBarTextItem *leftItem = allStringItems[0];
			ZBarTextItem *rightItem = [allStringItems lastObject];
			offsetX = (deltaWidth + (includeText ? leftItem.stringSize.width - rightItem.stringSize.width : 0)) / 2.0f;
			break;
		}
			
		case ZHorizontalAlignmentRight: {
			ZBarTextItem *rightItem = [allStringItems lastObject];
			offsetX = deltaWidth - (includeText ? rightItem.stringSize.width + 0.5*baritemWidth : 0);
			break;
		}
			
		default:
		case ZHorizontalAlignmentLeft: {
			ZBarTextItem *leftItem = allStringItems[0];
			offsetX = includeText ? leftItem.stringSize.width + 0.5*baritemWidth : 0;
			break;
		}
			
	}
	

	if(0){
		const CGFloat topOffsetForText = ((barcodeModel.barcodeCompound == ZBcCompoundBarcodeText) ? 0 : heightText);
		//	DRAW barcode
		CGRect stripeRect;
		stripeRect.origin.x = offsetX;
		stripeRect.size.height = renderRect.size.height;
		stripeRect.origin.y = 0;
		bool blackON = true;
		int i_pattern = -1;
		short pattern_len = 0;
		for (size_t n=0; barcodeCSubstrings[n]; ++n) {
			const char * codestring = barcodeCSubstrings[n];
			const size_t cs_length = strlen(codestring);
			
			if (pattern_len > 0) {
				--pattern_len;
			}
			if (pattern_len == 0) {
				pattern_len = pattern_of_barcode[++i_pattern];
			}
			
			//	draw next barcode element
			for (size_t i = 0, l = 0; i < cs_length; ++i) {
				const size_t wl = codestring[i]-'0';
				stripeRect.size.width = baritemWidth * (CGFloat)wl;
				if (blackON) {
					if (includeText) {
						//	make room for text
						if (!(i_pattern & 1)) {
							//	no text
							if (barcodeModel.barcodeCompound == ZBcCompoundBarcodeText) {
								//	text below
								stripeRect.origin.y = 0;
							}
							else {
								//	text above
								stripeRect.origin.y = 0.5*heightText;
							}
							stripeRect.size.height = renderRect.size.height-0.5*heightText;
						}
						else {
							//	save place for text
							stripeRect.origin.y = topOffsetForText;
							stripeRect.size.height = renderRect.size.height - heightText;
						}
					}
				CGContextAddRect(cx, stripeRect);
				}
				blackON = !blackON;
				l += wl;
				stripeRect.origin.x += stripeRect.size.width;
			}
			
		}
	}
	
	//	drawing
	const CGFloat barInsetX = baritemWidth * 8.0;
	const CGRect barcodeRect = CGRectMake(offsetX - barInsetX, 0, barcodeWidth + 2.0* barInsetX, renderRect.size.height);
	//	draw bg
	CGColorRef bgColor = barcodeModel.backgroundColor ? barcodeModel.backgroundColor.CGColor : [UIColor whiteColor].CGColor;
	bgColor = [UIColor yellowColor].CGColor;
	CGContextSetFillColorWithColor(cx, bgColor);
	CGContextFillRect(cx, barcodeRect);
	//	draw barcode itself
	CGPathRef bcPath = createBarcodePath_UPC(barcodeModel);
	CGColorRef foregroundColor = barcodeModel.foregroundColor ? barcodeModel.foregroundColor.CGColor : [UIColor blackColor].CGColor;
	CGContextSetFillColorWithColor(cx, foregroundColor);
	CGAffineTransform ttt1 = CGAffineTransformMakeTranslation(offsetX, 2);
	CGAffineTransform ttt2 = CGAffineTransformScale(ttt1, baritemWidth, renderRect.size.height-5);
	CGPathRef ppp2 = CGPathCreateCopyByTransformingPath(bcPath, &ttt2);
	CGContextAddPath(cx, ppp2);//, bcPath);
	CGContextFillPath(cx);
	CGPathRelease(bcPath), bcPath = NULL;
	CGPathRelease(ppp2), ppp2 = NULL;
	
	//	DRAW text if enabled
	if (includeText)
	{
		NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
		paragraph.alignment = NSTextAlignmentCenter;
		UIColor *textColor = [UIColor blackColor];//barcodeModel.textColor;
		NSNumber *underline = barcodeModel.underline ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
		NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : font,
									 NSParagraphStyleAttributeName : paragraph,
									 NSUnderlineStyleAttributeName : underline};
		//	render text
		CGRect txtFrame;
		txtFrame.origin.y = offsetTextY;
		txtFrame.size.height = heightText;
		ZBarTextItem *btItem;
		//	left, before barcode
		btItem = allStringItems[0];
		txtFrame.origin.x = offsetX - btItem.stringSize.width - baritemWidth * 0.5;
		txtFrame.size.width = btItem.stringSize.width;
		if (txtFrame.size.width > 1) {
			drawStringWithAttributesInRectInContext(btItem.string, attributes, txtFrame, cx);
		}
		//	middle (or middle left)
		btItem = allStringItems[1];
		txtFrame.origin.x = offsetX + (CGFloat)[allBarAreaLengths[0] integerValue] * baritemWidth;
		txtFrame.size.width = (CGFloat)[allBarAreaLengths[1] integerValue] * baritemWidth;
		if (txtFrame.size.width > 1) {
			drawStringWithAttributesInRectInContext(btItem.string, attributes, txtFrame, cx);
		}
		//	UPC-A middle-right
		if (allStringItems.count == 4) {
			btItem = allStringItems[2];
			txtFrame.origin.x += txtFrame.size.width;
			txtFrame.origin.x += (CGFloat)([allBarAreaLengths[2] integerValue]) * baritemWidth;
			txtFrame.size.width = (CGFloat)[allBarAreaLengths[3] integerValue] * baritemWidth;
			if (txtFrame.size.width > 1) {
				drawStringWithAttributesInRectInContext(btItem.string, attributes, txtFrame, cx);
			}
		}
		//	right, after barcode
		btItem = [allStringItems lastObject];
		txtFrame.origin.x = offsetX + ((CGFloat)bar_whole_length + 0.5) * baritemWidth;
		txtFrame.size.width = btItem.stringSize.width;
		if (txtFrame.size.width > 1) {
			drawStringWithAttributesInRectInContext(btItem.string, attributes, txtFrame, cx);
		}
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
