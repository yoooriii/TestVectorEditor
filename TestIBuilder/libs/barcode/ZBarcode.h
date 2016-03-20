//
//  ZBarcode.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/14/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZzBarcodesCommon.h"
#import "ZzBarcodePlainFunctions.h"

typedef NS_ENUM(NSInteger, ZHorizontalAlignment)  {
	ZHorizontalAlignmentUndefined = -1,
	ZHorizontalAlignmentLeft = NSTextAlignmentLeft,
	ZHorizontalAlignmentCenter = NSTextAlignmentCenter,
	ZHorizontalAlignmentRight = NSTextAlignmentRight,
	ZHorizontalAlignmentJustified = NSTextAlignmentJustified,
	ZHorizontalAlignmentNatural = NSTextAlignmentNatural,
	ZHorizontalAlignmentCenterBlock = 15,
};

typedef NS_ENUM(NSUInteger, ZVerticalAlignment) {
	ZVerticalAlignmentTop = 0,
	ZVerticalAlignmentMiddle,
	ZVerticalAlignmentBottom
};


@interface ZBarcode : NSObject

@property (nonatomic, assign) ZBarcodeType	symbology;	//	former barcodeType
@property (nonatomic, assign) ZBcCompound barcodeCompound;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString * text;
@property (nonatomic, strong) UIColor * backgroundColor;
@property (nonatomic, strong) UIColor * foregroundColor;

@property (nonatomic, assign) BOOL bold, italic, underline;//??

@property (nonatomic, assign) ZHorizontalAlignment		horizontalAlignment;
@property (nonatomic, assign) ZVerticalAlignment		verticalAlignment;

@property (nonatomic, assign) ZBarcodeErrorCode encodingError;
@property (nonatomic, assign) ZBarcodeSize	barcodeSize;
@property (nonatomic, readonly) CGFloat minimalWidth;
@property (nonatomic, readonly) CGFloat minimalHeight;

- (CGFloat)barItemWidth;
- (char*)encodedBuffer;
- (const char**)encodedSubstrings;
- (CGPathRef)CGPath;
@property (nonatomic, assign) const char *stringToShow;


- (NSArray *)substringsToShow;

@end
