//
//  ZBarcode.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/14/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZBarcode.h"

@implementation ZBarcode
{
	char					_encodedBuffer[1024];
	const char				*_encodedSubstrings[256];
	CGPathRef				_cgPath;
	CGFloat _minimalWidth;
	CGFloat _minimalHeight;

}

- (CGFloat)barItemWidth
{
	if (ZBarcodeTypeQRCode == self.barcodeType) {
		//Leonid: Im not sure about this
		return [[self class] barItemWidthWithBarcodeSize:ZBarcodeSizeSmall];
	}
	return [[self class] barItemWidthWithBarcodeSize:self.barcodeSize];
}

const CGFloat WidthDecoder[] = {3,5,8};

+ (CGFloat)barItemWidthWithBarcodeSize:(ZBarcodeSize)bcSize
{
	return WidthDecoder[bcSize] * 72.0 / 300.0;
}

- (CGFloat)minimalWidth {
	return 100;
}

- (CGFloat)minimalHeight {
	return 100;
}

- (char *)encodedBuffer {
	return _encodedBuffer;
}

- (const char **)encodedSubstrings {
	return _encodedSubstrings;
}

- (CGPathRef)CGPath {
	return _cgPath;
}

#pragma mark - encoding

- (void)encode
{
	_encodingError = ZBarcodeErrorCodeOK;
	NSString *barcodeText = self.text;
	const char *buffer = NULL;
	const char **bufferSubstrings = NULL;
	NSStringEncoding encoding = NSASCIIStringEncoding;
	
	if (0 == [barcodeText length])
	{
		self.encodingError = ZBarcodeErrorCodeEmptyString;
		return;
	}
	
//	if (self.barcodeType == ZBarcodeTypeQRCode) {
//		[self encodeQR];
//	}
//	else if (self.barcodeType == ZBarcodeTypePDF417) {
//		[self encodePDF417];
//	}
//	else
		if ([barcodeText canBeConvertedToEncoding:encoding])
	{
		const char *barcodeCString = [barcodeText cStringUsingEncoding:encoding];
		const size_t text_length = [barcodeText lengthOfBytesUsingEncoding:encoding];
		
		switch (self.barcodeType)
		{
			case ZBarcodeType39:
			case ZBarcodeType39_43:
			{
				const BOOL mod43 = (self.barcodeType == ZBarcodeType39_43);
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
		_encodingError = getLastErrorCode();
	}
	else
	{
		static NSDictionary *sPIValidationErrorsMap = nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sPIValidationErrorsMap = @{@(ZBarcodeType39) : @(ZBarcodeErrorCodeUpperAbcDigitsOnly),
									   @(ZBarcodeType39_43) : @(ZBarcodeErrorCodeUpperAbcDigitsOnly),
									   @(ZBarcodeTypeI25) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeC128A) : @(ZBarcodeErrorCodeAbcDigitsOnly),
									   @(ZBarcodeTypeC128B) : @(ZBarcodeErrorCodeAbcDigitsOnly),
									   @(ZBarcodeTypeC128C) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeC128auto) : @(ZBarcodeErrorCodeAbcDigitsOnly),
									   @(ZBarcodeTypeEAN8) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeEAN13) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeUPCA) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeUPCE) : @(ZBarcodeErrorCodeDigitsOnly),
									   @(ZBarcodeTypeCodabar) : @(ZBarcodeErrorCodeDigitsSelectSymbolsOnly),
									   @(ZBarcodeTypeITF14) : @(ZBarcodeErrorCodeDigitsOnly)};
		});
		NSNumber *errorNumber = sPIValidationErrorsMap[@(self.barcodeType)];
		if (errorNumber)
		{
			_encodingError = [errorNumber unsignedIntegerValue];
		}
		else {
			_encodingError = ZBarcodeErrorCodeUndefined;	//<-- should never happen
		}
	}
	[self calculateOptimalWidth];
}

- (void)calculateOptimalWidth
{
	_minimalWidth = 100;
	_minimalHeight = 100;
}
@end
