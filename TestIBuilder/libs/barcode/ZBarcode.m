//
//  ZBarcode.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/14/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZBarcode.h"
#import "ZBarTextItem.h"

ZBarcodeErrorCode errorCodeWithSymbology(ZBarcodeType symbology)
{
	switch (symbology) {
		case ZBarcodeType39:		return ZBarcodeErrorCodeUpperAbcDigitsOnly;
		case ZBarcodeType39_43:		return ZBarcodeErrorCodeUpperAbcDigitsOnly;
		case ZBarcodeTypeI25:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeC128A:		return ZBarcodeErrorCodeAbcDigitsOnly;
		case ZBarcodeTypeC128B:		return ZBarcodeErrorCodeAbcDigitsOnly;
		case ZBarcodeTypeC128C:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeC128auto:	return ZBarcodeErrorCodeAbcDigitsOnly;
		case ZBarcodeTypeEAN8:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeEAN13:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeUPCA:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeUPCE:		return ZBarcodeErrorCodeDigitsOnly;
		case ZBarcodeTypeCodabar:	return ZBarcodeErrorCodeDigitsSelectSymbolsOnly;
		case ZBarcodeTypeITF14:		return ZBarcodeErrorCodeDigitsOnly;
		default:					break;
	}
	
	return ZBarcodeErrorCodeUndefined;
}

@interface NSString (ZTmp_Refactorit)

@end

@implementation NSString (ZTmp_Refactorit)

- (CGSize)prefferedSizeWithFont:(UIFont *)font actualFontSize:(CGFloat *)actualFontSize forWidth:(const CGFloat)width
{
	return [self sizeWithFont:font minFontSize:1 actualFontSize:actualFontSize forWidth:width lineBreakMode:NSLineBreakByCharWrapping];
}

@end

#pragma mark -

@interface ZBarcode ()

@property (nonatomic, readonly) NSMutableArray	*stringToShowSubitems;

@end

@implementation ZBarcode
{
	char					_encodedBuffer[1024];
	const char				*_encodedSubstrings[256];
	CGPathRef				_cgPath;
}

- (void)dealloc
{
	if (_cgPath) {
		CGPathRelease(_cgPath);
		_cgPath = NULL;
	}
}

- (id)init
{
	if ((self = [super init]))
	{
		_encodingError = ZBarcodeErrorCodeInvalid;
		_stringToShowSubitems = [NSMutableArray arrayWithCapacity:4];
		self.font = [UIFont fontWithName:@"Arial" size:10];
		_symbology = ZBarcodeType39;
		_barcodeSize = ZBarcodeSizeSmall;
		self.backgroundColor = [UIColor clearColor];
		self.foregroundColor = [UIColor blackColor];
		self.barcodeCompound = ZBcCompoundBarcodeText;
	}
	return self;
}

- (CGFloat)barItemWidth
{
	return [[self class] barItemWidthWithBarcodeSize:self.barcodeSize];
}

+ (CGFloat)barItemWidthWithBarcodeSize:(ZBarcodeSize)bcSize
{
	const CGFloat WidthDecoder[] = {3,5,8};
	bcSize = MIN(MAX(bcSize, 0), 2); // 0<=sz<=2
	return WidthDecoder[bcSize] * 72.0 / 300.0;
}

- (char *)encodedBuffer {
	return _encodedBuffer;
}

- (const char **)encodedSubstrings {
	return _encodedSubstrings;
}


#pragma mark - encoding

- (ZBarcodeErrorCode)encode
{
	ZBarcodeErrorCode success = ZBarcodeErrorCodeOK;
	NSString *barcodeText = self.text;
	const char *buffer = NULL;
	const char **bufferSubstrings = NULL;
	NSStringEncoding encoding = NSASCIIStringEncoding;
	
	if (0 == [barcodeText length])
	{
		return ZBarcodeErrorCodeEmptyString;
	}
	
//	if (self.symbology == ZBarcodeTypeQRCode) {
//		[self encodeQR];
//	}
//	else if (self.symbology == ZBarcodeTypePDF417) {
//		[self encodePDF417];
//	}
//	else
		if ([barcodeText canBeConvertedToEncoding:encoding])
	{
		const char *barcodeCString = [barcodeText cStringUsingEncoding:encoding];
		const size_t text_length = [barcodeText lengthOfBytesUsingEncoding:encoding];
		
		switch (self.symbology)
		{
			case ZBarcodeType39:
			case ZBarcodeType39_43:
			{
				const BOOL mod43 = (self.symbology == ZBarcodeType39_43);
				buffer = barcode_encode_as_bitmap_39(barcodeCString, mod43, &_stringToShow);
				break;
			}
			case ZBarcodeTypeI25:
			{
				buffer = barcode_encode_as_bitmap_I25(barcodeCString);
				break;
			}
			case ZBarcodeTypeC128A:
			{
				buffer = barcode_encode_as_bitmap_C128A(barcodeCString, text_length);
				break;
			}
			case ZBarcodeTypeC128B:
			{
				buffer = barcode_encode_as_bitmap_C128B(barcodeCString, text_length);
				break;
			}
			case ZBarcodeTypeC128C:
			{
				buffer = barcode_encode_as_bitmap_C128C(barcodeCString, text_length);
				break;
			}
			case ZBarcodeTypeC128auto:
			{
				buffer = barcode_encode_as_bitmap_C128auto(barcodeCString, text_length);
				break;
			}
			case ZBarcodeTypeUPCE:
			{
				bufferSubstrings = barcode_encode_as_substrings_UPCE(barcodeCString, &_stringToShow);
				break;
			}
			case ZBarcodeTypeUPCA:
			{
				bufferSubstrings = barcode_encode_as_substrings_UPCA(barcodeCString, &_stringToShow);
				break;
			}
			case ZBarcodeTypeEAN8:
			{
				bufferSubstrings = barcode_encode_as_substrings_EAN(barcodeCString, &_stringToShow, 8);
				break;
			}
			case ZBarcodeTypeEAN13:
			{
				bufferSubstrings = barcode_encode_as_substrings_EAN(barcodeCString, &_stringToShow, 13);
				break;
			}
			case ZBarcodeTypeCodabar:
			{
				buffer = barcode_encode_as_bitmap_Codabar(barcodeCString);
				break;
			}
			case ZBarcodeTypeITF14:
			{
				buffer = barcode_encode_as_bitmap_ITF14(barcodeCString, &_stringToShow);
				break;
			}
			default:
				break;
		}
		//	copy results
		if (buffer) {
			strncpy(_encodedBuffer, buffer, sizeof(_encodedBuffer));
		}
		else {
			_encodedBuffer[0] = 0;
		}
		
		if (bufferSubstrings) {
			for (size_t i = 0; bufferSubstrings[i]; ++i) {
				_encodedSubstrings[i] = bufferSubstrings[i];
			}
		}
		else {
			_encodedSubstrings[0] = NULL;
		}
		success = getLastErrorCode();
	}
	else
	{
		success = errorCodeWithSymbology(self.symbology);
	}
	
	if (ZBarcodeErrorCodeOK == success) {
		[self calculateOptimalWidth];
	}
	else {
		//TODO: set proper min size
		_minimalWidth = 50;
		_minimalHeight = 0;
	}
	
	return success;
}

- (void)calculateOptimalWidth
{
	if (self.encodingError != ZBarcodeErrorCodeOK) {
		return;
	}
	
	const CGFloat baritemWidth = [self barItemWidth];
	
	if (ZBarcodeTypePDF417 != self.symbology) {
		_minimalHeight = 0;
	}
	
	const short * pattern_of_string = barcode_pattern_str_UPC(self.symbology);
	const short * pattern_of_barcode = barcode_pattern_bar_UPC(self.symbology);

	if (pattern_of_string && pattern_of_barcode)
	{
		if (_stringToShow)
		{
			NSUInteger location = 0;
			for (size_t i=0; pattern_of_string[i] >= 0; ++i) {
				const int length = pattern_of_string[i];
				ZBarTextItem *btItem = [ZBarTextItem barTextItemWithCString:_stringToShow range:NSMakeRange(location, length)];
				[self.stringToShowSubitems addObject:btItem];
				location += length;
			}
		}
		size_t bar_whole_length = 0;
		size_t i_offset = 0;
		for (size_t i=0; pattern_of_barcode[i] >= 0; ++i) {
			const short items_number = pattern_of_barcode[i];
			size_t item_length = 0;
			for (size_t j=0; j < items_number; ++j) {
				item_length += substring_item_length(_encodedSubstrings[i_offset+j]);
			}
			bar_whole_length += item_length;
			i_offset += items_number;
		}
		
		const CGFloat barcodeWidth = bar_whole_length * baritemWidth;
		BOOL includeText = self.barcodeCompound != ZBcCompoundBarcodeOnly;
		if (includeText)
		{
			//	divide barcode area into parts
			NSMutableArray *allBarAreaLengths = [NSMutableArray arrayWithCapacity:8];
			size_t i_offset = 0;
			for (size_t i=0; pattern_of_barcode[i] >= 0; ++i) {
				const short items_number = pattern_of_barcode[i];
				size_t item_length = 0;
				for (size_t j=0; j < items_number; ++j) {
					item_length += substring_item_length(_encodedSubstrings[i_offset+j]);
				}
				[allBarAreaLengths addObject:@(item_length)];
				i_offset += items_number;
			}
			
			const CGFloat baritemWidth = [self barItemWidth];
			//	find suitable font (adjust font size)
			UIFont *font = self.font;
			ZBarTextItem *aSubitem = self.stringToShowSubitems[1];
			CGFloat actualFontSize;
			NSString *aSubstring = aSubitem.string;
			const CGFloat substringWidth = (CGFloat)[allBarAreaLengths[1] integerValue] * baritemWidth;
			[aSubstring prefferedSizeWithFont:font actualFontSize:&actualFontSize forWidth:substringWidth];
			if (actualFontSize < font.pointSize) {
				font = [font fontWithSize:actualFontSize];
			}
			if (self.stringToShowSubitems.count == 4) {
				aSubitem = self.stringToShowSubitems[2];
				aSubstring = aSubitem.string;
				const CGFloat substringWidth = (CGFloat)[allBarAreaLengths[1] integerValue] * baritemWidth;
				[aSubstring prefferedSizeWithFont:font actualFontSize:&actualFontSize forWidth:substringWidth];
				if (actualFontSize < font.pointSize) {
					font = [font fontWithSize:actualFontSize];
				}
			}
			
			for (ZBarTextItem *anItem in self.stringToShowSubitems) {
				[anItem updateSizeWithFont:font];
			}
		}
		_minimalWidth = barcodeWidth;
		const NSUInteger ssCount = [self.stringToShowSubitems count];
		if (includeText && ssCount) {
			_minimalWidth += [self.stringToShowSubitems.firstObject stringSize].width;
			_minimalWidth += [self.stringToShowSubitems.lastObject stringSize].width;
		}
	}
	else
	{
		switch (self.symbology)
		{
				//		case ZBarcodeTypeQRCode:
				//			_minimalWidth = self.encodedQRCodeMatrix.width;
				//			return;
				//
				//		case ZBarcodeTypePDF417: {
				//			//	it calculates height as well;
				//			_minimalWidth = self.encoderPDF417.width;
				//			_minimalHeight = self.encoderPDF417.height * 4.0f;//ratio x:y = 1:4
				//			return;
				//		}
				
			case ZBarcodeType39:
			case ZBarcodeType39_43:
			case ZBarcodeTypeI25:
			case ZBarcodeTypeCodabar:
				_minimalWidth = width_barcode_v1(_encodedBuffer, baritemWidth, 0);
				break;

			case ZBarcodeTypeC128A:
			case ZBarcodeTypeC128B:
			case ZBarcodeTypeC128C:
			case ZBarcodeTypeC128auto:
				_minimalWidth = width_barcode(_encodedBuffer, baritemWidth, 0);
				break;
				
			case ZBarcodeTypeITF14:
			{
				const CGFloat additionalWidth = baritemWidth * 28;
				_minimalWidth = width_barcode_v1(_encodedBuffer, baritemWidth, 0) + additionalWidth;
				break;
			}
			default:
				break;
		}
	}
}

- (BOOL)useStringSubitems {
	return (self.symbology == ZBarcodeTypeUPCA)
		|| (self.symbology == ZBarcodeTypeUPCE)
		|| (self.symbology == ZBarcodeTypeEAN8)
		|| (self.symbology == ZBarcodeTypeEAN13);
}

- (NSArray *)substringsToShow
{
	if ([self useStringSubitems] && self.stringToShowSubitems.count) {
		return self.stringToShowSubitems;
	}
	return nil;
}

#pragma mark - Smart (lazy) logic

- (void)setText:(NSString *)text
{
	//TODO: additional logic: text and text to show is not the same (checksum makes the difference)
	if (![_text isEqualToString:text]) {
		_text = [text copy];
		[self invalidate];
	}
}

- (void)setSymbology:(ZBarcodeType)symbology
{
	if (_symbology != symbology) {
		_symbology = symbology;
		[self invalidate];
	}
}

- (void)invalidate
{
	self.encodingError = ZBarcodeErrorCodeInvalid;
	[self.stringToShowSubitems removeAllObjects];
	if (_cgPath) {
		CGPathRelease(_cgPath);
		_cgPath = NULL;
	}
	//	not sure we need to cleanup these
//	bzero(_encodedBuffer, sizeof(_encodedBuffer));
//	for (size_t i=0; i< sizeof(_encodedSubstrings); ++i) {
//		_encodedSubstrings[i] = 0;
//	}
}

- (CGPathRef)CGPath {
	if (!_cgPath) {
		self.encodingError = [self encode];
		if (ZBarcodeErrorCodeOK == self.encodingError) {
			CGRect resultRect = CGRectMake(0, 0, 0, 1);
			NSString* resultText = nil;
			_cgPath = createPathBarcodeWithTextSymbology(self.text, &resultRect, self.symbology, 1, &resultText);
		}
	}
	return _cgPath;
}
#pragma mark - Debug

- (NSString*)symbologyString
{
	switch (self.symbology) {
#define CASE(x, y) case x: return y
			CASE(ZBarcodeTypeUndefined, @"undefined");
			CASE(ZBarcodeType39, @"39");
			CASE(ZBarcodeType39_43, @"39 mod43");
			CASE(ZBarcodeTypeI25, @"I2of5");
			CASE(ZBarcodeTypeC128A, @"C128A");
			CASE(ZBarcodeTypeC128B, @"C128B");
			CASE(ZBarcodeTypeC128C, @"C128C");
			CASE(ZBarcodeTypeC128auto, @"C128auto");
			CASE(ZBarcodeTypeEAN8, @"EAN8");
			CASE(ZBarcodeTypeEAN13, @"EAN13");
			CASE(ZBarcodeTypeUPCA, @"UPCA");
			CASE(ZBarcodeTypeUPCE, @"UPCE");
			CASE(ZBarcodeTypeCodabar, @"Codabar");
			CASE(ZBarcodeTypeITF14, @"ITF14");
			CASE(ZBarcodeTypeQRCode, @"QR");
			CASE(ZBarcodeTypePDF417, @"PDF417");
#undef CASE
	}
	return @"???";
}

- (NSString *)description
{
	NSString* status = (ZBarcodeErrorCodeOK == self.encodingError) ? @"OK" : [NSString stringWithFormat:@"err:%d", (int)self.encodingError];
	return [NSString stringWithFormat:@"<%@:%p>%@:'%@'(%@)", [self class], self, [self symbologyString], self.text, status];
}
@end
