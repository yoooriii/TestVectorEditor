#import <Foundation/Foundation.h>

typedef struct _BarRange_ {
	float	location;
	float	length;
} BarRange;

#define FREE_SAFELY(x) { if(x){ free(x); x = NULL; } }

typedef NS_ENUM (NSInteger, ZBarcodeType)
{
	ZBarcodeTypeUndefined = -1,
	ZBarcodeType39 = 0,
    ZBarcodeType39_43 = 1,
	ZBarcodeTypeI25 = 2,
	ZBarcodeTypeC128A = 3,
	ZBarcodeTypeC128B = 4,
	ZBarcodeTypeC128C = 5,
	ZBarcodeTypeC128auto = 6,
	ZBarcodeTypeEAN8 = 7,
	ZBarcodeTypeEAN13 = 8,
	ZBarcodeTypeUPCA = 9,
	ZBarcodeTypeUPCE = 10,
	ZBarcodeTypeCodabar = 11,	//=10
	ZBarcodeTypeITF14 = 12,
	ZBarcodeTypeQRCode,
	ZBarcodeTypePDF417,
};

typedef enum ZBarcodeSize : NSInteger
{
	ZBarcodeSizeSmall = 0,		//	3
	ZBarcodeSizeMedium,		//	5
	ZBarcodeSizeLarge			//	8
} ZBarcodeSize;

#define ZzQRCodeMaxCodeWidth 177

typedef NS_ENUM(NSUInteger, ZBarcodeContentType)
{
	ZBarcodeContentTypeAutodetect = 0,
	ZBarcodeContentTypePlainText = 1,
	ZBarcodeContentTypeURL = 2,
	ZBarcodeContentTypeEmail = 3,
	ZBarcodeContentTypePhoneNumber = 4
};

typedef NS_ENUM(NSUInteger, ZBarcodeErrorCorrectionLevel)
{
	ZBarcodeErrorCorrectionLevelLow = 0,
	ZBarcodeErrorCorrectionLevelMedium = 1,
	ZBarcodeErrorCorrectionLevelQuartile = 2,
	ZBarcodeErrorCorrectionLevelHigh = 3
};

//	where to draw encoded text
typedef NS_ENUM (NSUInteger, ZBcCompound)
{
	ZBcCompoundBarcodeText = 0,	//	barcode above, text below = default
	ZBcCompoundTextBarcode,		//	text above, barcode below
	ZBcCompoundBarcodeOnly,		//	no text
	ZBcCompoundTextOnly			//	no barcode
};


NSInteger ZzQRCodeWidthForVersion(NSInteger version);
NSInteger ZzQRCodeOptimalVersionForWidth(NSInteger width);
