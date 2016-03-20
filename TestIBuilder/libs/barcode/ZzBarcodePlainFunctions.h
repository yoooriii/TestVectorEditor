#import <Foundation/Foundation.h>
#import "ZzBarcodesCommon.h"
#import <CoreGraphics/CoreGraphics.h>


typedef struct barcode_symbol
{
	ZBarcodeType	type;			//	symbology
	char	*text_to_encode;		//	text to encode
	char	*text_encoded;			//	may differ from the text_to_encode (may have checksum or leading zeros etc.)
	int		error_code;				//	error code or 0 if no error occured
	char	*error_text;
	char	*bitmap_buffer;			//	1d bitmap buffer
	CGFloat	iwidth;					//	the black stripe width
	CGFloat	gap_width;				//	quiet zone width (at the left + right sides)
} barcode_symbol;

void free_barcode_symbol (barcode_symbol *barcode);

int chartoi(const char source);

//	Code 39
//	returns NULL if invalid and formatted string if valid
const char * validate_string_c39 (const char *string);
//	returns a static C array, copy one;
const char *barcode_encode_as_bitmap_39(const char *str, BOOL is_mod_43, const char ** formatted_string);

//	Interleaved 2 of 5 (aka Code 25, I2of5, ITF, I25)
/*
 Each data character is composed of 5 elements, either 5 bars or 5 spaces. Of these 5 elements, two are wide and three are narrow. Adjacent characters are interleaved, alternating the spaces from one character with the bars of the other.
 */
BOOL isValidChar_I25 (const char sym);
const char * validate_string_I25 (const char *string);
const char *barcode_encode_as_bitmap_I25(const char *str);

//	barcode 128A may contain non printable chars [0x0...0x1F] (for instance '\n', '\t', '\r')
BOOL isValidChar_C128A (const char sym);
BOOL isValidChar_C128B (const char sym);
BOOL isValidChar_C128C (const char sym);
BOOL isValidChar_C128auto (const char sym);
//	subcode : ['A', 'B', 'C', '\0'] ('\0'==auto)
const char * validate_string_C128_ABC (const char *string, const size_t leng, const char subcode);
const char * validate_string_C128A (const char *string, const size_t leng);
const char * validate_string_C128B (const char *string, const size_t leng);
const char * validate_string_C128C (const char *string, const size_t leng);
const char * validate_string_C128auto (const char *string, const size_t leng);
const char *barcode_encode_as_bitmap_C128A(const char *str, const size_t leng);
const char *barcode_encode_as_bitmap_C128B(const char *str, const size_t leng);
const char *barcode_encode_as_bitmap_C128C(const char *str, const size_t leng);
const char *barcode_encode_as_bitmap_C128auto(const char *str, const size_t leng);
//	C128 helper functions (internal use)
/**
 str : substring to encode
 leng : the substring's length
 pcodes : in-out array; the result will be in this array;
 result : points to after the end value in the array
 !!! it does not validate arguments
 */
unsigned int *barcode_encode_codetable_C128A(const char *str, const size_t leng, unsigned int *pcodes);
unsigned int *barcode_encode_codetable_C128B(const char *str, const size_t leng, unsigned int *pcodes);
unsigned int *barcode_encode_codetable_C128C(const char *str, const size_t leng, unsigned int *pcodes);

//	EAN-8, EAN-13
BOOL isValidChar_EAN (const char sym);
//	for EAN-8 number=8 / EAN-13 number=13
BOOL isValidString_EAN (const char *string, const size_t number);
const char *barcode_encode_as_bitmap_EAN8(const char *str, const char **formatted_barcode_string);
const char *barcode_encode_as_bitmap_EAN13(const char *str, const char **formatted_barcode_string);


//	UPC-A, UPC-E
//	for UPC-A subcode = 'A' / UPC-E subcode = 'E'
const char * validate_string_UPC (const char *string, const char subcode);
const char * validate_string_UPCE(const char *string);
const char *barcode_encode_as_bitmap_UPCA(const char *str, const char **formatted_barcode_string);
const char *barcode_encode_as_bitmap_UPCE(const char *str, const char **formatted_barcode_string);
//	returns a NULL terminated array of strings / or NULL
const char ** barcode_encode_as_substrings_UPCE (const char *str_to_encode, const char **formatted_barcode_string);
const char ** barcode_encode_as_substrings_UPCA(const char *str_to_encode, const char **formatted_barcode_string);
const char ** barcode_encode_as_substrings_EAN(const char *str, const char **formatted_barcode_string, const int subcode);

//	Codabar
BOOL isValidChar_Codabar (const char sym);
BOOL isValidString_Codabar (const char *string);
const char *barcode_encode_as_bitmap_Codabar(const char *str);

//	ITF-14
BOOL isValidChar_ITF14 (const char sym);
BOOL isValidString_ITF14 (const char *string);
const char *barcode_encode_as_bitmap_ITF14(const char *str, const char **formatted_barcode_string);

//	helper functions to calculate the barcode's size
CGFloat width_barcode_v1 (const char *bitmap_buffer,
						const CGFloat iwidth,
						const CGFloat gap_width);

CGFloat width_barcode (const char *bitmap_buffer,
					   const CGFloat iwidth,
					   const CGFloat gap_width);
CGFloat width_barcode_for_symbology (const char *bitmap_buffer,
									 ZBarcodeType barcodeType,
									 const CGFloat iwidth);
#ifndef CONSOLE_APP

//	PDF417
//	QRcode

/*
 first create a bitmap with one of barcode_encode_as_bitmap_*** functions then render one
 bitmap_buffer : a buffer previously generated with 1 of <barcode_encode_as_bitmap***> functions
 iwidth : the 1 bar item's width (in pixels, intended to adjust bar's width 3/5/8)
 btw : a barcode may be rendered beyond the rect's bounds
 */
CGRect render_barcode_in_rect (CGContextRef cx, CGRect *rect, const char *bitmap_buffer, CGColorRef bgColor, CGColorRef color, const CGFloat iwidth);
//	the first version
//	returns the real rect
CGRect render_barcode_in_rect_v1 (CGContextRef cx,				//	context
								CGRect *rect,					//	rect to render in
								const char *bitmap_buffer,		//	bitmap to render
								CGColorRef bgColor,				//	background color (white)
								CGColorRef color,				//	foreground color (black)
								const CGFloat iwidth,			//	black bar width
								const CGFloat gap_width);		//	quiet zone width (at the left and at the right sides)

void render_nobarcode_in_rect (CGContextRef cx,
							   CGRect *rect,
							   NSString *error_string,
							   CGColorRef bgColor,
							   CGColorRef color,
							   const CGFloat font_size,
							   const char *font_name);

void render_error_in_rect(CGContextRef cx,
						  CGRect rect,
						  NSString *string);

CGPathRef createPathBarcode_v1 (CGRect *resultRect,
								const char *bitmap_buffer,
								const CGFloat iwidth,
								const CGFloat gap_width);

CGPathRef createPathBarcode (CGRect *resultRect,
							 const char *bitmap_buffer,
							 const CGFloat iwidth,
							 const CGFloat gap_width);

CGPathRef createPathBarcodeWithTextSymbology (NSString *barcodeText,
											  CGRect *actualRect,
											  ZBarcodeType barcodeType,
											  const CGFloat baritemWidth,
											  NSString **formattedBarcodeText);

const char ** barcode_encode_as_substrings (const char *string_to_encode,
											ZBarcodeType symbology,
											const char **formatted_string);



#endif


size_t substring_item_length (const char * const item_string);
size_t join_substrings (const char **substrings, char *buffer, const char *joint);



/**
 text : text to encode
 type : symbology
 */
BOOL is_text_valid (const char *text, const size_t leng, const ZBarcodeType type);
BOOL is_nstext_valid (NSString *text, const ZBarcodeType type);

typedef enum ZBarcodeErrorCode : NSInteger {
	ZBarcodeErrorCodeOK = 0,			//	no error, everything is ok
	ZBarcodeErrorCodeDigitsOnly,
	ZBarcodeErrorCodeDigitsSelectSymbolsOnly,
    ZBarcodeErrorCodeAbcDigitsOnly,
    ZBarcodeErrorCodeUpperAbcDigitsOnly,
	ZBarcodeErrorCodeWrongChecksum,
	ZBarcodeErrorCodeEmptyString,
	ZBarcodeErrorCodeExceed40DigitsLimit,
	ZBarcodeErrorCodeExceed60DigitsLimit,
	ZBarcodeErrorCodeEvenCharactersOnly,
	ZBarcodeErrorCodeExceedEAN8Limit,
	ZBarcodeErrorCodeExceedEAN13Limit,
	ZBarcodeErrorCodeExceedUPCALimit,
	ZBarcodeErrorCodeExceedUPCELimit,
	ZBarcodeErrorCodeExceedITF14Limit,
	ZBarcodeErrorCodeWrongSystemNumber,
    ZBarcodeErrorCodeCanNotConvertToUPCE,
	ZBarcodeErrorCodeExceedQRCodeLimit,
	ZBarcodeErrorCodeExceedPDF417Limit,
	ZBarcodeErrorCodeCOUNT,			//	count, for validation use only
	ZBarcodeErrorCodeUndefined=-1,	//<-- this should never happen
	ZBarcodeErrorCodeInvalid=-2		//<-- marked as invalid, barcode was not encoded yet (if was then either OK or any other error code)
} ZBarcodeErrorCode;

extern NSInteger BarcodeLastErrorCode;

const short * barcode_pattern_bar_UPC(const ZBarcodeType symbology);
const short * barcode_pattern_str_UPC(const ZBarcodeType symbology);

ZBarcodeErrorCode getLastErrorCode (void);

NSString *errorStringWithCode (ZBarcodeErrorCode errorCode);
NSString *errorTitleWithCode (ZBarcodeErrorCode errorCode);

NSString *lastErrorString (void);
