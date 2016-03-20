#import "ZzBarcodePlainFunctions.h"
#import "NSString+additions.h"

//	common use functions
//	returns the result string (out buffer) length
size_t join_substrings (const char **substrings, char *buffer, const char *joint);
size_t convert_string_to_int_buffer (const char *string, const size_t str_size, unsigned int *buffer, const size_t buf_size);


BOOL isValidChar_39 (const char sym);
char * validate_string_EAN_UPC (char *string, const size_t max_leng, const size_t min_leng, BOOL insert_zero);

//	UPC
//	copyes and aligns a string into result_str with expected_length and returns strlen(string) if can or 0 if cannot
//	if no checksymbol then sets '*' on its place
size_t prepare_string_UPC_EAN (const char *string, char *result_str, const size_t expected_length);
BOOL transcode_UPCE_to_UPCA_codebuffer (const char *str, unsigned int *codebuffer);

//	represents checksum to be calculated
const char WILDSYMBOL = 17;

//	shared data
unsigned int shared_code_buffer_32[32];
char shared_char_buffer_1024[1024];
char shared_char_buffer_90[90];
char shared_char_formatted_string[90];

#pragma mark - hardcode - begin

void free_barcode_symbol (barcode_symbol *barcode)
{
	printf("%s: not implemented\n", __PRETTY_FUNCTION__);
}


const size_t SymbolLength_39 = 10;


size_t join_substrings (const char **substrings, char *buffer, const char *joint)
{
	if (!substrings) {
		return 0;
	}
	size_t offset = 0;
	const size_t leng_joint = joint ? strlen(joint) : 0;
	for (size_t i=0; NULL != substrings[i]; ++i) {
		const size_t len = strlen(substrings[i]);
		memcpy(buffer + offset, substrings[i], len);
		offset += len;
		if (leng_joint) {
			memcpy(buffer + offset, joint, leng_joint);
			offset += leng_joint;
		}
#ifdef BARCODE_DEBUG
		printf("%s ", substrings[i]);
#endif
	}
	//	remove the last joint if any
	offset -= leng_joint;
	buffer[offset] = '\0';
	
	return offset;
}


int chartoi(const char source)
{
	if((source >= '0') && (source <= '9')) {
		return (source - '0');
	}
	return -1;
}

const char * expand_buffer_as_bitmap (const char *buffer) {
	static char encoded_data[178 * 8];
	size_t writer = 0;
	size_t n = strlen(buffer);
	char latch = '1';
	
	for (unsigned int reader = 0; reader < n; ++reader) {
		const int number = chartoi(buffer[reader]);
		for (int i = 0; i < number; ++i, ++writer) {
			encoded_data[writer] = latch;
		}
		
		latch = (latch == '1' ? '0' : '1');
	}
	encoded_data[writer] = '\0';
	
	return encoded_data;
}

void test_expand(const char *data)
{
	const size_t n = strlen(data);
	int writer = 0;
	char latch = '1';
	
	unsigned char encoded_data[178 * 8];
	bzero(encoded_data, sizeof(encoded_data));
	
	for (unsigned int reader = 0; reader < n; ++reader) {
		const int number = chartoi(data[reader]);
		for (int i = 0; i < number; ++i, ++writer) {
			encoded_data[writer] = latch;
		}
		
		latch = (latch == '1' ? '0' : '1');
	}
	
#ifdef BARCODE_DEBUG
	printf("encoded[%d]:'%s';\n\n", writer, encoded_data);
#endif
}

size_t convert_string_to_int_buffer (const char *string, const size_t str_size, unsigned int *buffer, const size_t buf_size)
{
	assert(buf_size >= str_size);
	
	bzero(buffer, sizeof(unsigned int) * buf_size);
	const size_t offset = (buf_size == str_size) ? 0 : buf_size - str_size -1;
	for (size_t i = 0; i < str_size; ++i) {
		const char next_symbol = string[i];
		if (!isdigit(next_symbol)) {
			//	non digit symbol, full stop
			return 0;
		}
		buffer[i+offset] = next_symbol-'0';
	}
	return str_size;
}

#pragma mark - common renders

const CGFloat GAP = 8;

#ifndef CONSOLE_APP
void render_nobarcode_in_rect (CGContextRef cx,
							   CGRect *rect,
							   NSString *error_string,
							   CGColorRef bgColor,
							   CGColorRef color,
							   const CGFloat font_size,
							   const char *font_name)
{
	assert(cx != NULL);
	assert(rect != NULL);
	
	NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
	paragraph.alignment = NSTextAlignmentCenter;
	paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
	
	UIFont *font = [UIFont fontWithName:font_name ? [NSString stringWithUTF8String:font_name] : @"Helvetica" size:font_size > 1 ? font_size : 14];
	if (!font) {
		font = [UIFont systemFontOfSize:font_size > 1 ? font_size : 14];
	}
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:8];
	attributes[NSForegroundColorAttributeName] = [UIColor redColor];
	attributes[NSFontAttributeName] = font;
	attributes[NSParagraphStyleAttributeName] = paragraph;
	attributes[NSStrokeColorAttributeName] = [UIColor whiteColor];
	attributes[NSStrokeWidthAttributeName] = @(1);

	NSAttributedString *text = [[NSAttributedString alloc] initWithString:error_string attributes:attributes];
	[text drawWithRect:*rect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
}

void render_error_in_rect(CGContextRef cx,
						  CGRect rect,
						   NSString *string)
{
	assert(cx != NULL);
	assert(string != nil);
	
	const CGFloat initialFontSize = 18;
	CGFloat actualFontSize = initialFontSize;
	UIFont *font = [UIFont boldSystemFontOfSize:actualFontSize];
	CGSize size = [string _deprecated_sizeWithFont:font minFontSize:1 actualFontSize:&actualFontSize forWidth:rect.size.width lineBreakMode:NSLineBreakByTruncatingTail];
	LLog(@"%@ : %@", NSStringFromCGRect(rect), NSStringFromCGSize(size));
	if (actualFontSize < initialFontSize) {
		font = [UIFont boldSystemFontOfSize:actualFontSize];
		size = [string _deprecated_sizeWithFont:font minFontSize:1 actualFontSize:NULL forWidth:rect.size.width lineBreakMode:NSLineBreakByTruncatingTail];
	}
	CGRect bgRect;
	bgRect.size.width = size.width + 2;
	bgRect.size.height = size.height + 2;
	bgRect.origin.x = rect.origin.x + (rect.size.width - bgRect.size.width)/2.0;
	bgRect.origin.y = rect.origin.y + (rect.size.height - bgRect.size.height)/2.0;
	[[[UIColor whiteColor] colorWithAlphaComponent:0.4] setFill];
	CGContextFillRect(cx, bgRect);
	[[UIColor redColor] set];
	[string _deprecated_drawInRect:bgRect withFont:font lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
	
	CGContextStrokeRectWithWidth(cx, bgRect, 0.5);
}


CGRect render_barcode_in_rect_v1 (CGContextRef cx,
								  CGRect *rect,
								  const char *bitmap_buffer,
								  CGColorRef bgColor,
								  CGColorRef color,
								  const CGFloat iwidth,
								  const CGFloat gap_width)
{
	//	sanity check
	assert(cx != NULL);
	assert(rect != NULL);
	if (!bitmap_buffer) {
		return CGRectZero;
	}
	
	CGRect resultRect = *rect;
	CGPathRef barcodePath = createPathBarcode_v1(&resultRect, bitmap_buffer, iwidth, gap_width);
	
	if (bgColor) {
		CGContextSetFillColorWithColor(cx, bgColor);
		CGContextFillRect(cx, resultRect);
	}
	if (!color) {
		color = [UIColor whiteColor].CGColor;
	}
	CGContextAddPath(cx, barcodePath);
	CGContextSetFillColorWithColor(cx, color);
	CGContextFillPath(cx);
	CGPathRelease(barcodePath);
	
	return resultRect;
}

CGPathRef createPathBarcode_v1 (CGRect *resultRect,
								const char *bitmap_buffer,
								const CGFloat iwidth,
								const CGFloat gap_width)
{
	if (!bitmap_buffer) {
		return NULL;
	}
	if (!resultRect) {
		return NULL;
	}
	
	CGFloat x = gap_width;
	CGFloat y = 0;
	const size_t sym_length = strlen(bitmap_buffer);

	CGMutablePathRef path = CGPathCreateMutable();
	
	for (int i = 0; i < sym_length; i++, x += iwidth) {
		BOOL val = (bitmap_buffer[i] == '1');
		if (val) {
			CGRect rect = CGRectMake(x, y, iwidth, resultRect->size.height);
			CGPathAddRect(path, NULL, rect);
		}
	}
	
	resultRect->origin = CGPointZero;
	resultRect->size.width = width_barcode_v1(bitmap_buffer, iwidth, gap_width);
	return path;
}

CGRect render_barcode_in_rect (CGContextRef cx, CGRect *rect, const char *bitmap_buffer, CGColorRef bgColor, CGColorRef color, const CGFloat iwidth)
{
	//	sanity check
	assert(cx != NULL);
	assert(rect != NULL);
	if (!bitmap_buffer) {
		return CGRectZero;
	}
	
	CGFloat x = CGRectGetMinX(*rect);
	CGFloat y = CGRectGetMinY(*rect);
	const CGFloat dx = iwidth;
	const CGFloat bar_height = (rect->size).height;
	
	//	calculate the barcode's width
	const size_t len_buffer = strlen(bitmap_buffer);
	size_t item_count = 0;
	for (int i=0; i < len_buffer; ++i) {
		const int len = bitmap_buffer[i] - '0';
		item_count += len;
	}
#ifdef BARCODE_DEBUG
	printf("item_count:%zd\n", item_count);
#endif
	
	CGRect realRect = CGRectMake(x, y, dx * item_count + 2.0*GAP, bar_height);
	
	if (bgColor) {
		CGContextSetFillColorWithColor(cx, bgColor);
		CGContextFillRect(cx, realRect);
	}
	x += GAP;
	
	int latch = 1;
	for (int reader=0; reader < len_buffer; ++reader, latch = !latch) {
		const int ilen = bitmap_buffer[reader] - '0';
		const CGFloat w = iwidth * ilen;
		if (latch) {
			CGRect r = CGRectMake(x, y, w, bar_height);
			CGContextAddRect(cx, r);
		}
		x += w;
	}
	
	CGContextClosePath(cx);
	if (color) {
		CGContextSetFillColorWithColor(cx, color);
	}
	CGContextFillPath(cx);
	
	return realRect;
}

CGFloat width_barcode (const char *bitmap_buffer,
						  const CGFloat iwidth,
						  const CGFloat gap_width)
{
	if (!bitmap_buffer || iwidth < 0.001) {
		return 0;
	}
	const size_t len_buffer = strlen(bitmap_buffer);
	size_t item_count = 0;
	for (int i=0; i < len_buffer; ++i) {
		const int len = bitmap_buffer[i] - '0';
		item_count += len;
	}
	
	return iwidth * item_count + 2.0*gap_width;
}

CGFloat width_barcode_v1 (const char *bitmap_buffer,
						  const CGFloat iwidth,
						  const CGFloat gap_width)
{
	if (!bitmap_buffer || iwidth < 0.001) {
		return 0;
	}
	const size_t symWidth = strlen(bitmap_buffer);
	return iwidth * symWidth + 2.0*gap_width;
}

CGFloat width_barcode_for_symbology (const char *bitmap_buffer,
									 ZBarcodeType barcodeType,
									 const CGFloat iwidth)
{
	switch (barcodeType) {
			
		case ZBarcodeType39:
		case ZBarcodeTypeI25:
		case ZBarcodeTypeEAN8:
		case ZBarcodeTypeEAN13:
		case ZBarcodeTypeCodabar:
		case ZBarcodeTypeUPCA:
		case ZBarcodeTypeUPCE:
		case ZBarcodeType39_43:
		case ZBarcodeTypeITF14:
			return width_barcode_v1(bitmap_buffer, iwidth, iwidth);
			
		case ZBarcodeTypeC128A:
		case ZBarcodeTypeC128B:
		case ZBarcodeTypeC128C:
		case ZBarcodeTypeC128auto:
			return width_barcode(bitmap_buffer, iwidth, iwidth);
			
		default:	break;
	}
	
	return -1;
}

CGPathRef createPathBarcode (CGRect *resultRect,
							 const char *bitmap_buffer,
							 const CGFloat iwidth,
							 const CGFloat gap_width)
{
	if (!bitmap_buffer) {
		return NULL;
	}
	if (!resultRect) {
		return NULL;
	}
	
	CGFloat x = gap_width;
	CGFloat y = 0;
	resultRect->size.width = width_barcode(bitmap_buffer, iwidth, gap_width);

	CGMutablePathRef barcodePath = CGPathCreateMutable();
	int latch = 1;
	const CGFloat bar_height = resultRect->size.height;
	const size_t len_buffer = strlen(bitmap_buffer);
	for (int reader=0; reader < len_buffer; ++reader, latch = !latch) {
		const int ilen = bitmap_buffer[reader] - '0';
		const CGFloat w = iwidth * ilen;
		if (latch) {
			CGRect r = CGRectMake(x, y, w, bar_height);
			CGPathAddRect(barcodePath, NULL, r);
		}
		x += w;
	}

	return barcodePath;
}


const char ** barcode_encode_as_substrings (const char *string_to_encode,
											ZBarcodeType symbology,
											const char **formatted_string)
{
	switch (symbology) {
		case ZBarcodeTypeUPCE: {
			return barcode_encode_as_substrings_UPCE(string_to_encode, formatted_string);
		}
			
		default:
			break;
	}
	return NULL;
}

CGPathRef createPathBarcodeWithTextSymbology (NSString *barcodeText,
											  CGRect *actualRect,
											  ZBarcodeType barcodeType,
											  const CGFloat baritemWidth,
											  NSString **formattedBarcodeText)
{
	CGPathRef barcodePath = NULL;
	const char *formatted_barcode_string = NULL;
	
	switch (barcodeType) {
			
		case ZBarcodeTypePDF417:
		case ZBarcodeTypeQRCode:
			LLog(@"2D barcodes have not implemented yet");
			break;
			
		case ZBarcodeTypeEAN8: {
			const char *buffer = barcode_encode_as_bitmap_EAN8([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], &formatted_barcode_string);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeEAN13: {
			const char *buffer = barcode_encode_as_bitmap_EAN13([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], &formatted_barcode_string);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeUPCA: {
			const char *buffer = barcode_encode_as_bitmap_UPCA([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], &formatted_barcode_string);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeUPCE: {
			const char *buffer = barcode_encode_as_bitmap_UPCE([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], &formatted_barcode_string);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeType39:
		case ZBarcodeType39_43: {
			const BOOL mod43 = (barcodeType == ZBarcodeType39_43);
			const char *buffer = barcode_encode_as_bitmap_39([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], mod43, &formatted_barcode_string);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeI25: {
			const char *buffer = barcode_encode_as_bitmap_I25([barcodeText cStringUsingEncoding:NSASCIIStringEncoding]);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeCodabar: {
			const char *buffer = barcode_encode_as_bitmap_Codabar([barcodeText cStringUsingEncoding:NSASCIIStringEncoding]);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			
			break;
		}
			
		case ZBarcodeTypeC128A: {
			const char *buffer = barcode_encode_as_bitmap_C128A([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], barcodeText.length);
			barcodePath = createPathBarcode(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			//			render_barcode_in_rect(cx, &renderRect, buffer, bgColor, color, baritemWidth);
			
			break;
		}
			
		case ZBarcodeTypeC128B: {
			const char *buffer = barcode_encode_as_bitmap_C128B([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], barcodeText.length);
			barcodePath = createPathBarcode(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			//			render_barcode_in_rect(cx, &renderRect, buffer, bgColor, color, baritemWidth);
			
			break;
		}
			
		case ZBarcodeTypeC128C: {
			const char *buffer = barcode_encode_as_bitmap_C128C([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], barcodeText.length);
			barcodePath = createPathBarcode(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			//			render_barcode_in_rect(cx, &renderRect, buffer, bgColor, color, baritemWidth);
			
			break;
		}
			
		case ZBarcodeTypeC128auto: {
			const char *buffer = barcode_encode_as_bitmap_C128auto([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], barcodeText.length);
			barcodePath = createPathBarcode(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
			//			render_barcode_in_rect(cx, &renderRect, buffer, bgColor, color, baritemWidth);
			
			break;
		}
			
		case ZBarcodeTypeITF14: {
			const char *buffer = barcode_encode_as_bitmap_ITF14([barcodeText cStringUsingEncoding:NSASCIIStringEncoding], formattedBarcodeText ? &formatted_barcode_string : NULL);
			barcodePath = createPathBarcode_v1(actualRect, buffer, baritemWidth, baritemWidth * 2.0);
		}
			
		default:
			LLog(@"Undefined barcode type to render (%d)", (int)barcodeType);
			break;
	}
	
	if (formattedBarcodeText) {
		if (formatted_barcode_string) {
			*formattedBarcodeText = [NSString stringWithCString:formatted_barcode_string encoding:NSASCIIStringEncoding];
		}
		else {
			*formattedBarcodeText = NULL;
			//
			*formattedBarcodeText = barcodeText;
		}
	}
	
	return barcodePath;
}
#endif

#pragma mark - code 39

BOOL isValidChar_39 (const char sym)
{
	if (isdigit(sym)) {
		return YES;
	}
	if (isupper(sym)) {
		return YES;
	}
	switch (sym) {
		case ' ':
		case '-':
		case '+':
		case '.':
		case '$':
		case '/':
		case '%':
//		case '*':	//	wrong case I suppose
			return YES;
			
		default:
			break;
	}
	
	return NO;
}

const size_t max_string_leng_code39 = 40;

const char * validate_string_c39 (const char *str)
{
	const size_t str_len = str ? strlen(str) : 0;
	if (str_len == 0 || str_len > max_string_leng_code39) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
		return NULL;
	}
	char *buffer = shared_char_buffer_90;
	size_t ibuf = 0;
	for (size_t i=0; i<str_len; ++i) {
		if ((0 == i) && ('*' == str[0])) {
			continue;
		}
		if (!isValidChar_39(str[i])) {
			if ((0 == i) || (str_len - 1 == i)) {
				//	skip '*' asterisks at the beginning and at the end of the string
				if ('*' == str[i]) {
					continue;
				}
			}
            BarcodeLastErrorCode = ZBarcodeErrorCodeUpperAbcDigitsOnly;
			return NULL;
		}
		buffer[ibuf++] = str[i];
	}
	buffer[ibuf] = '\0';
	
	if (0 == ibuf) {
		//	after removing '*'s the buffer is empty
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	
	return buffer;
}

//	SILVER
const char IndexTable39[] =	"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*";//<--asterisk is there
/* Incorporates Table A1 */
const char *CodeTable39[45] = {
	"111221211", "211211112", "112211112", "212211111", "111221112",
	"211221111", "112221111", "111211212", "211211211", "112211211", "211112112",
	"112112112", "212112111", "111122112", "211122111", "112122111", "111112212",
	"211112211", "112112211", "111122211", "211111122", "112111122", "212111121",
	"111121122", "211121121", "112121121", "111111222", "211111221", "112111221",
	"111121221", "221111112", "122111112", "222111111", "121121112", "221121111",
	"122121111", "121111212", "221111211", "122111211", "121212111", "121211121",
	"121112121", "111212121", "121121211", NULL
};
/* Code 39 character assignments (Table 1) */
const char *Code39_start_stop_string = "121121211";

const char * encode_symbol_code39(const char symbol)
{
	for (size_t i = 0; i < strlen(IndexTable39); ++i) {
		if (symbol == IndexTable39[i]) {
			return CodeTable39[i];
		}
	}
	return NULL;
}

const size_t index_of_symbol_code39(const char symbol)
{
	for (size_t i = 0; i < strlen(IndexTable39); ++i) {
		if (symbol == IndexTable39[i]) {
			return i;
		}
	}
	return -1;
}

const char *barcode_encode_as_bitmap_39(const char *str_to_encode, BOOL is_mod_43, const char ** formatted_string)
{
	if (formatted_string) {
		*formatted_string = NULL;
	}
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str_to_encode) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	const char *str = validate_string_c39(str_to_encode);
	const size_t leng = str ? strlen(str) : 0;
	if (!leng) {
        return NULL;
	}
	if (formatted_string) {
		*formatted_string = str;
	}

	const char *substrings[50];
	size_t substring_i = 0;
	
	unsigned int checksum = 0;
	
	//	1. START
	substrings[substring_i++] = Code39_start_stop_string;
	//	2. BODY
	for (size_t i = 0; i < leng; ++i) {
		const size_t indx = index_of_symbol_code39(str[i]);
		if (indx == -1) {
			BarcodeLastErrorCode = ZBarcodeErrorCodeUpperAbcDigitsOnly;
			LLog(@"wrong symbol");
			return NULL;
		}
		checksum += indx;
		substrings[substring_i++] = CodeTable39[indx];
	}
	//	3. CHECK SUM 43 (if needed)
	if (is_mod_43) {
		checksum = checksum % 43;
		substrings[substring_i++] = CodeTable39[checksum];
	}
	//	4. STOP
	substrings[substring_i++] = Code39_start_stop_string;
	//	5. Terminator
	substrings[substring_i] = NULL;
	
	char *buffer = shared_char_buffer_1024;
#ifdef BARCODE_DEBUG
	size_t lll =
#endif
	join_substrings(substrings, buffer, "1");
	
#ifdef BARCODE_DEBUG
	printf("join buf[%ld]:'%s'\n", lll, buffer);
#endif
	
	const char *encoded_data = expand_buffer_as_bitmap (buffer);
	
#ifdef BARCODE_DEBUG
	printf("encoded_data[%ld]:%s;\n", strlen(encoded_data), encoded_data);
#endif
	
	return encoded_data;
}

#pragma mark - I 2 of 5

BOOL isValidChar_I25 (const char sym) {
	return (BOOL) isdigit(sym);
}

const char * validate_string_I25 (const char *string)
{
	if (!string) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	
	const size_t len = strlen(string);
	if (len == 0 || len > 40) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
		return NULL;
	}
	
	for (size_t i = 0; i<len; ++i) {
		if (!isValidChar_I25(string[i])) {
            BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
			return NULL;
		}
	}
	
	if (len & 1) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEvenCharactersOnly;
		return NULL;
	}

	return string;
}

//	C25InterTable
const char *CodeTableI25[10] = {"11331", "31113", "13113", "33111", "11313", "31311", "13311", "11133", "31131", "13131"};


const char *barcode_encode_as_bitmap_I25(const char *str)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!validate_string_I25(str)) {
		return NULL;
	}
	
	char *buffer = shared_char_buffer_1024;
	char *pBuffer = buffer;
	
	/* start character */
	strcpy(pBuffer, "1111");
	pBuffer += 4;

	/* Input must be an even number of characters for Interlaced 2 of 5 to work:
	 if an odd number of characters has been entered then add a leading zero */
	char tmpString[50];
	tmpString[0] = '0';
	strcpy(&tmpString[1], str);

	const char *pString = (strlen(str) & 1) ? tmpString : tmpString + 1;
	while (*pString) {
		const unsigned int indxBar = (*pString) - '0';
		if (indxBar > 9) {
			//	wrong input string
			return NULL;
		}
		const char *pBars = CodeTableI25[indxBar];
		++pString;
		
		const unsigned int indxSpace = ((*pString) == '\0') ? 0 : (*pString) - '0';
		if (indxSpace > 9) {
			//	wrong input string
			return NULL;
		}
		const char *pSpaces = CodeTableI25[indxSpace];
		++pString;
		
		for (int j=0; j<5; ++j) {
			*pBuffer = pBars[j];
			++pBuffer;
			*pBuffer = pSpaces[j];
			++pBuffer;
		}
	}
	
	/* stop character */
	strcpy (pBuffer, "311");
	pBuffer += 3;
	*pBuffer = '\0';
	
#ifdef BARCODE_DEBUG
	printf("RAW RESULT: '%s'\n", buffer);
#endif

	//	expand the result into a bitmap
	const size_t n = strlen(buffer);
	int writer = 0;
	char latch = '1';
	
	static char encoded_data[178 * 8];
	
	for (unsigned int reader = 0; reader < n; ++reader) {
		const int number = chartoi(buffer[reader]);
		for (int i = 0; i < number; ++i, ++writer) {
			encoded_data[writer] = latch;
		}
		
		latch = (latch == '1' ? '0' : '1');
	}
	encoded_data[writer] = '\0';
	
#ifdef BARCODE_DEBUG
	printf("encoded_data: '%s'\n", encoded_data);
#endif

	return encoded_data;
}


#pragma mark - code 128 a,b,c

/* Code 128 tables checked against ISO/IEC 15417:2007 */
const char *CodeTable128[107] = {"212222", "222122", "222221", "121223", "121322", "131222", "122213",
	"122312", "132212", "221213", "221312", "231212", "112232", "122132", "122231", "113222",
	"123122", "123221", "223211", "221132", "221231", "213212", "223112", "312131", "311222",
	"321122", "321221", "312212", "322112", "322211", "212123", "212321", "232121", "111323",
	"131123", "131321", "112313", "132113", "132311", "211313", "231113", "231311", "112133",
	"112331", "132131", "113123", "113321", "133121", "313121", "211331", "231131", "213113",
	"213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111", "314111",
	"221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214",
	"112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112",
	"134111", "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112",
	"421211", "212141", "214121", "412121", "111143", "111341", "131141", "114113", "114311",
	"411113", "411311", "113141", "114131", "311141", "411131",
	"211412",	//	103:START-A
	"211214",	//	104:START-B
	"211232",	//	105:START-C
	"2331112"	//	106:STOP
};
/* Code 128 character encodation - Table 1 */


BOOL isValidChar_C128B (const char sym)
{
	return (sym >= 32 && sym <= 127);
}

BOOL isValidChar_C128A (const char sym)
{
	return (sym >= 0 && sym <= 95);
}

BOOL isValidChar_C128C (const char sym)
{
	return isdigit(sym);
}

BOOL isValidChar_C128auto (const char sym)
{
	return (sym >= 0 && sym <= 127);
}

const char * validate_string_C128A (const char *string, const size_t leng)
{
	return validate_string_C128_ABC(string, leng, 'A');
}

const char * validate_string_C128B (const char *string, const size_t leng)
{
	return validate_string_C128_ABC(string, leng, 'B');
}

const char * validate_string_C128C (const char *string, const size_t leng)
{
	return validate_string_C128_ABC(string, leng, 'C');
}

const char * validate_string_C128auto (const char *string, const size_t leng)
{
	return validate_string_C128_ABC(string, leng, '\0');
}

const char * validate_string_C128_ABC (const char *string, const size_t leng, const char subcode)
{
	if (!string || (0 == leng)) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	
	typedef BOOL (*is_valid_func) (const char);
	is_valid_func is_valid_char;
	switch (subcode) {
		case '\0':
			if (leng > 40) {
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
				return NULL;
			}
			is_valid_char = isValidChar_C128auto;
			break;
			
		case 'A':
			if (leng > 40) {
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
				return NULL;
			}
			is_valid_char = isValidChar_C128A;
			break;
			
		case 'B':
			if (leng > 40) {
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
				return NULL;
			}
			is_valid_char = isValidChar_C128B;
			break;
			
		case 'C':
            if (leng > 60) {
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceed60DigitsLimit;
                return NULL;
            }
			is_valid_char = isValidChar_C128C;
			break;
			
		default:
			return NULL;
	}
	
	for (int i=0; i<leng; ++i) {
		if (!is_valid_char(string[i])) {
            switch (subcode) {
                case '\0':
                case 'A':
                case 'B':
                    BarcodeLastErrorCode = ZBarcodeErrorCodeAbcDigitsOnly;
                    break;
                case 'C':
                    BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
                default:
                    break;
            }
			return NULL;
		}
	}
    
    if (subcode == 'C' && (leng & 1)) {
        //	C requires even digits count
        LLog(@"128-C requires even digits count (%zd)", leng);
        BarcodeLastErrorCode = ZBarcodeErrorCodeEvenCharactersOnly;
        return NULL;
    }

	return string;
}

char * encode_bitmap_code_128 (const unsigned int *bitmap_codes, const size_t leng)
{
	//	encode result codes into a bitmap
	static char bitmap[(108+4)*6];
	bzero(bitmap, sizeof(bitmap));
	char *pbitmap = bitmap;
	
	for (size_t i=0; i<leng; ++i) {
		const size_t code = bitmap_codes[i];
#ifdef BARCODE_DEBUG
		if (code > sizeof(CodeTable128)/sizeof(CodeTable128[0])) {
			printf("wrong code (%zd) !!!", code);
		}
		printf("%02zd ", code);
#endif
		const char *encoded = CodeTable128[code];
		const size_t ln = strlen(encoded);
		memcpy(pbitmap, encoded, ln+1);
		pbitmap += ln;
	}
	*pbitmap = '\0';
	printf("\n");
	
#ifdef BARCODE_DEBUG
	printf("BITMAP-128:'%s'\n", bitmap);
#endif
	
	return bitmap;
}

char barcode_calc_checksum_C128(const unsigned int *bitmap_codes, const size_t leng)
{
	if (!bitmap_codes) {
		return 0;
	}
	//	checksum
	int total_sum = bitmap_codes[0];
	for (int i = 1; i < leng; ++i) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnevermind"
		const int val = bitmap_codes[i] * i;
#pragma clang diagnostic pop
		total_sum += val;
	}
	return total_sum % 103;
}

int _ctoi(char source)
{ /* Converts a character 0-9 to its equivalent integer value */
	if((source >= '0') && (source <= '9'))
		return (source - '0');
	return(source - 'A' + 10);
}

/** Converts an integer value to its hexadecimal character */
char _itoc(int source)
{
	if ((source >= 0) && (source <= 9)) {
		return ('0' + source); }
	else {
		return ('A' + (source - 10)); }
}

char _upc_check(char source[])
{ /* Calculate the correct check digit for a UPC barcode + EAN */
	unsigned int i, count, check_digit;
	
	count = 0;
	
	for (i = 0; i < strlen(source); i++) {
		count += _ctoi(source[i]);
		
		if (!(i & 1)) {
			count += 2 * (_ctoi(source[i]));
		}
	}
	
	check_digit = 10 - (count%10);
	if (check_digit == 10) { check_digit = 0; }
	return _itoc(check_digit);
}


unsigned int *barcode_encode_codetable_C128A(const char *str, const size_t leng, unsigned int *pcodes)
{
	//	start symbol { START-A : 103 }
	*(pcodes++) = 103;
	//	text
	for (size_t i = 0; i < leng; ++i) {
		unsigned int symbol = str[i];
		if (symbol < 32) {
			symbol += 64;
			*(pcodes++) = symbol & 0x7F;
		}
		else {
			*(pcodes++) = (symbol & 0x7F) - 32;
		}
	}
	return pcodes;
}

const char *barcode_encode_as_bitmap_C128(const char *str, const size_t leng, const char subcode)
{
	switch (subcode) {
		case 'A':
			return barcode_encode_as_bitmap_C128A(str, leng);
			
		case 'B':
			return barcode_encode_as_bitmap_C128B(str, leng);
			
		case 'C':
			return barcode_encode_as_bitmap_C128C(str, leng);
			
		case '\0':
			return barcode_encode_as_bitmap_C128auto(str, leng);

		default:	break;
	}
	return NULL;
}

const char *barcode_encode_as_bitmap_C128A(const char *str, const size_t leng)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str || (0 == leng)) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!validate_string_C128A(str, leng)) {
		return NULL;
	}
	
	unsigned int bitmap_codes[108];
	//	start-A + text
	unsigned int *pcodes = barcode_encode_codetable_C128A(str, leng, bitmap_codes);
	//	checksum
	const int checksymbol = barcode_calc_checksum_C128(bitmap_codes, leng+1);
#ifdef BARCODE_DEBUG
	printf("checksymbol2:%02d\n", checksymbol);
#endif
	*(pcodes++) = checksymbol;
	//	stop symbol
	*(pcodes++) = 106;	//	STOP
	
	//	encode result codes into a bitmap
	//	leng(text) + <start> + <check> + <stop>
	return encode_bitmap_code_128(bitmap_codes, leng+3);
}

unsigned int *barcode_encode_codetable_C128B(const char *str, const size_t leng, unsigned int *pcodes)
{
	//	start symbol	{ START-B : 104 }
	*(pcodes++) = 104;
	
	//	text
	for (size_t i = 0; i < leng; ++i) {
		const int symbol = str[i];
		*(pcodes++) = (symbol & 127) - 32;
	}
	return pcodes;
}

const char *barcode_encode_as_bitmap_C128B(const char *str, const size_t leng)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str || (0 == leng)) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!validate_string_C128B(str, leng)) {
		
		return NULL;
	}
	
	unsigned int bitmap_codes[108];
	//	start-B + text
	unsigned int *pcodes = barcode_encode_codetable_C128B(str, leng, bitmap_codes);
	//	checksum
	const int checksymbol = barcode_calc_checksum_C128(bitmap_codes, leng+1);
#ifdef BARCODE_DEBUG
	printf("checksymbol2:%02d\n", checksymbol);
#endif
	*(pcodes++) = checksymbol;
	//	stop symbol
	*(pcodes++) = 106;	//	STOP

	//	encode result codes into a bitmap
	//	leng(text) + <start> + <check> + <stop>
	return encode_bitmap_code_128(bitmap_codes, leng+3);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnevermind"
unsigned int *barcode_encode_codetable_C128C(const char *str, const size_t leng, unsigned int *pcodes)
{
	//	start symbol { START-C : 105 }
	*(pcodes++) = 105;
	//	text
	for (size_t i = 0; i < leng; i+=2) {
		const int symbol0 = str[ i ] - '0';
		const int symbol1 = str[i+1] - '0';
		*(pcodes++) = symbol0 * 10 + symbol1;
	}
	return pcodes;
}

const char *barcode_encode_as_bitmap_C128C(const char *str, const size_t leng)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str || (0 == leng)) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!validate_string_C128C(str, leng)) {		
		return NULL;
	}
	
	unsigned int bitmap_codes[108/2];
	//	start-C + text
	unsigned int *pcodes = barcode_encode_codetable_C128C(str, leng, bitmap_codes);
	//	checksum
	const int checksymbol = barcode_calc_checksum_C128(bitmap_codes, leng/2+1);
#ifdef BARCODE_DEBUG
	printf("checksymbol2:%02d\n", checksymbol);
#endif
	*(pcodes++) = checksymbol;
	//	stop symbol
	*(pcodes++) = 106;	//	STOP
	
	//	leng(text)/2 + <start> + <check> + <stop>
	return encode_bitmap_code_128(bitmap_codes, leng/2+3);
}
#pragma clang diagnostic pop


enum {
	code_none = 0,
	code_a = 1,
	code_b = 2,
	code_c = 4,
	code_stop = 0x80
};

int switch_128_code(const char from_code, const char to_code)
{
	switch (from_code) {
		case code_a:
			switch (to_code) {
				case code_b:	return 100;
				case code_c:	return 99;
				default:		break;
			}
			break;
			
		case code_b:
			switch (to_code) {
				case code_a:	return 101;
				case code_c:	return 99;
				default:		break;
			}
			break;
			
		case code_c:
			switch (to_code) {
				case code_a:	return 101;
				case code_b:	return 100;
				default:		break;
			}
			break;
			
		default:
			break;
	}
	return code_none;
}

const char *barcode_encode_as_bitmap_C128auto(const char *str, const size_t leng)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str || (0 == leng)) {
        BarcodeLastErrorCode =ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!validate_string_C128auto(str, leng)) {
		return NULL;
	}
	
#ifdef BARCODE_DEBUG
	if (1) {{
		for (size_t i=0; i<leng; ++i) {
			const char ch = str[i];
			printf("%c  ", ch < 32 ? '?': ch);
		}
		printf("\n");
	}}
#endif
	

	//	find out which codetable to use : 1-A; 2-B; 4-C;
	char codetables[108+1] = {0};
	codetables[leng] = code_stop;
	
	if (1) {
		//	code_selector will contain the info which code is to use A, B or C
		char code_selector[108] = {0};
		code_selector[leng] = code_stop;
		
		//	discover C ranges, the rest is A/B
		size_t count_c = 0;
		for (size_t i=0; i < leng; ++i) {

			//	1. set default values A / B (if any)
			if (isValidChar_C128A(str[i])) {
				code_selector[i] |= code_a;
			}
			if (isValidChar_C128B(str[i])) {
				code_selector[i] |= code_b;
			}

			if (isdigit(str[i])) {
				++count_c;
			}
			else {
				if (count_c >= 4) {
					//	2. override default values with C
					for (size_t j = i - (count_c & 0xFE); j < i; ++j) {
						code_selector[j] = code_c;
					}
				}
				count_c = 0;
			}
		}
		if (count_c >= 4) {
			for (size_t j = leng - (count_c & 0xFE); j < leng; ++j) {
				code_selector[j] = code_c;
			}
		}
		
#ifdef BARCODE_DEBUG
		if (1) {{
			//	debug print
			for (size_t i=0; i < leng; ++i) {
				const char ch = code_selector[i];
				if (ch == code_c) {
					printf("C  ");
				}
				else {
					int count = 3;
					if (ch & code_a) {
						printf("A");
						--count;
					}
					if (ch & code_b) {
						printf("B");
						--count;
					}
					for (int i=0; i<count; ++i) {
						printf(" ");
					}
				}
			}
			printf("\n");
			
			for (size_t i=0; i < leng; ++i) {
				printf("%02zd ", i);
			}
			printf("\n");
		}}
#endif

		
		//	discover A/B ranges and select the longest one
		NSRange range_a = NSMakeRange(NSNotFound, 0);
		NSRange range_b = NSMakeRange(NSNotFound, 0);
		BOOL finish_a = NO;
		BOOL finish_b = NO;
		for (size_t i=0; i <= leng; ++i) {
			
			if ((i == leng) || (code_c == code_selector[i])) {
				//	the last iteration (after the string's length) OR code C
				finish_a = YES;
				finish_b = YES;
			}
			
			if (!finish_a) {
				if (code_selector[i] & code_a) {
					if (range_a.location == NSNotFound) {
						range_a.location = i;
						range_a.length = 1;
					}
					else {
						++range_a.length;
					}
				}
				else {
					if (range_a.location != NSNotFound) {
						finish_a = YES;
					}
				}
			}
			
			if (!finish_b) {
				if (code_selector[i] & code_b) {
					if (range_b.location == NSNotFound) {
						range_b.location = i;
						range_b.length = 1;
					}
					else {
						++range_b.length;
					}
				}
				else {
					if (range_b.location != NSNotFound) {
						finish_b = YES;
					}
				}
			}

			if (finish_a && finish_b) {
				if (0) {{
					//	print A/B result ranges
					if (range_a.location != NSNotFound) {
						printf("A [%02d:%02d]\n", (int)range_a.location, (int)range_a.length);
					}
					if (range_b.location != NSNotFound) {
						printf("B [%02d:%02d]\n", (int)range_b.location, (int)range_b.length);
					}
				}}
				
				const BOOL found_a = (range_a.location != NSNotFound);
				const BOOL found_b = (range_b.location != NSNotFound);
				if (found_a || found_b) {
					NSRange range_code;
					char code = code_none;
					if (found_a && found_b) {
						//	both A and B, so select the longest
						range_code = (range_a.length > range_b.length) ? range_a : range_b;
						code = (range_a.length > range_b.length) ? code_a : code_b;
					}
					else {
						//	either A or B
						if (found_a) {
							//	range A
							range_code = range_a;
							code = code_a;
						}
						else {
							//	range B
							range_code = range_b;
							code = code_b;
						}
					}
					
					if (range_code.location != NSNotFound) {
						//	fill the longest range with A or B codes
						for (size_t j = range_code.location; j < range_code.location + range_code.length; ++j) {
							code_selector[j] = code;
						}
					}
				}
				
				//	preparing for the next iteration (if any)
				range_a.location = NSNotFound;
				range_b.location = NSNotFound;
				finish_a = NO;
				finish_b = NO;
			}
		}
		
#ifdef BARCODE_DEBUG
		if (1) {{
			//	print the result
			for (size_t i=0; i < leng; ++i) {
				const char ch = code_selector[i];
				if (ch == code_c || ch == 'C') {
					printf("C  ");
				}
				else {
					int count = 3;
					if (ch & code_a) {
						printf("A");
						--count;
					}
					if (ch & code_b) {
						printf("B");
						--count;
					}
					for (int i=0; i<count; ++i) {
						printf(" ");
					}
				}
			}
			printf("\n");
		}}
#endif
		
		unsigned int bitmap_codes[108];
		unsigned int *pcodes = bitmap_codes;
		size_t ranges_count = 0;
		char curr_code = code_none;
		NSRange code_range = NSMakeRange(NSNotFound, 0);
		for (size_t i = 0; i <= leng; ++i) {
			if ((i == leng) || (curr_code != code_selector[i])) {
				if (code_range.location != NSNotFound) {
					++ranges_count;
					code_range.length = i - code_range.location;
					//TODO: override start symbol?
					unsigned int *const pstart = pcodes;
					switch (curr_code) {
						case code_a:
							pcodes = barcode_encode_codetable_C128A(str + code_range.location, code_range.length, pcodes);
							break;
							
						case code_b:
							pcodes = barcode_encode_codetable_C128B(str + code_range.location, code_range.length, pcodes);
							break;
							
						case code_c:
							pcodes = barcode_encode_codetable_C128C(str + code_range.location, code_range.length, pcodes);
							break;
							
						default:
							printf ("WTF code? (%d)\n", (int)curr_code);
							//	full stop
							return NULL;
					}
					//	replace a start code with a switch code (except the first one)
					if (pstart != bitmap_codes) {
						const char prev_code = code_selector[code_range.location - 1];
						const int sw_code = switch_128_code(prev_code, curr_code);
						*pstart = sw_code;
					}
				}
				if (i == leng) {
					break;
				}
				//	switch from one codetable to another
				curr_code = code_selector[i];
				code_range.location = i;
				code_range.length = 0;
			}
		}
		//	checksum
		const int checksymbol = barcode_calc_checksum_C128(bitmap_codes, pcodes-bitmap_codes);
#ifdef BARCODE_DEBUG
		printf("%zd ranges discovered\n", ranges_count);
		printf("checksymbol2:%02d\n", checksymbol);
#endif
		*(pcodes++) = checksymbol;
		//	stop symbol
		*(pcodes++) = 106;	//	STOP
		
		//	encode result codes into a bitmap
		//	leng(text) + N*<start> + <check> + <stop>
		return encode_bitmap_code_128(bitmap_codes, pcodes-bitmap_codes);

	}
	
	return NULL;
}

#pragma mark -

/**
 * Translate Code 128 Set B characters into barcodes.
 * This set handles all characters which are not part of long numbers and not
 * control characters.
 */
const char * encode_symbol_128(const char sym)	//	originally c128_set_b
{
	/* limit the range to 0-127 */
	const int indx = (sym & 127) - 32;
	const char *code_symbol = CodeTable128[indx];
	return code_symbol;
}

/**
 * Translate Code 128 Set B characters into barcodes.
 * This set handles all characters which are not part of long numbers and not
 * control characters.
 */
//void c128_set_b(unsigned char source, char dest[], int values[], int *bar_chars)
//{
//	/* limit the range to 0-127 */
//	source &= 127;
//	source -= 32;
//	
//	concat(dest, C128Table[source]);
//	values[(*bar_chars)++] = source;
//}

#pragma mark - EAN-8, EAN-13

BOOL isValidChar_EAN (const char sym)
{
	return isdigit(sym);
}

unsigned int barcode_calc_checksum_EAN(const unsigned int *code, const size_t leng)
{
#ifdef BARCODE_DEBUG
	for (size_t i=0; i<leng; ++i) {
		printf("%d ", code[i]);
	}
	printf("[%zu]", leng);
#endif
	unsigned int sum_even = 0;
	unsigned int sum_odd  = 0;
	for (size_t i=0; i<leng; ++i) {
		if (i & 1) {	sum_even += code[i]; }
		else {			sum_odd  += code[i]; }
	}
	const unsigned int checksum_value = sum_even + 3 * sum_odd;
	const unsigned int checksum_digit = 10 - (checksum_value % 10);
	const unsigned int the_result = (checksum_digit == 10 ? 0 : checksum_digit);
#ifdef BARCODE_DEBUG
	printf("--chk-->%d\n", the_result);
#endif
	return the_result;
}

BOOL isValidString_EAN (const char *string, const size_t max_leng)
{
	//TODO: check validate_string_EAN_UPC, maybe the same
	if (!string) {
		return NO;
	}
	const size_t leng = strlen(string);
	if ((leng == 0) || (leng > max_leng)) {
		return NO;
	}
	for (size_t i = 0; i < leng; ++i) {
		if (!isValidChar_EAN(string[i])) {
			return NO;
		}
	}
	if (leng == max_leng) {
		//	the last digit may be a checksum
		unsigned int *code_buffer = shared_code_buffer_32;
		convert_string_to_int_buffer(string, leng, code_buffer, max_leng);
		const unsigned int checksum = barcode_calc_checksum_EAN (code_buffer, leng-1);
		const unsigned int check_symbol = string[leng -1] - '0';
		return (checksum == check_symbol);
	}
	return YES;
}

/* Representation set A and C (EN Table 1) */
const char *const CodeTableEAN_setA[10] = {"3211", "2221", "2122", "1411", "1132", "1231", "1114", "1312", "1213", "3112"};
/* Representation set B (EN Table 1) */
const char *const CodeTableEAN_setB[10] = {"1123", "1222", "2212", "1141", "2311", "1321", "4111", "2131", "3121", "2113"};
/* Left hand of the EAN-13 symbol (EN Table 3) */
const char *const CodeTableEAN13_parity[10] = {"AAAAA", "ABABB", "ABBAB", "ABBBA", "BAABB", "BBAAB", "BBBAA", "BABAB", "BABBA", "BBABA"};
//	Start / Stop / center symbols
const char *const EAN_start_stop_string = "111";
const char *const EAN_center_string = "11111";

const char ** barcode_encode_codebuffer_EAN8(unsigned int *code_buffer);
const char ** barcode_encode_codebuffer_EAN13(unsigned int *code_buffer);


char * validate_string_EAN (const char *string, const size_t subcode)
{
	if (subcode != 8 && subcode != 13) {
		return NULL;
	}
	const size_t string_length = strlen(string);
	if (string_length < subcode-1 || string_length > subcode) {
        BarcodeLastErrorCode = (subcode == 8) ? ZBarcodeErrorCodeExceedEAN8Limit : ZBarcodeErrorCodeExceedEAN13Limit;
		return NULL;
	}
	//	prepare string
	char * local_copy = shared_char_formatted_string;
	for (size_t i=0; i<string_length; ++i) {
		local_copy[i] = string[i];
	}
	if (string_length < subcode) {
		local_copy[subcode-1] = WILDSYMBOL;
	}
	local_copy[subcode] = '\0';
	
	return validate_string_EAN_UPC(local_copy, subcode, subcode, (subcode==13));
}


const char ** barcode_encode_as_substrings_EAN(const char *str, const char **formatted_barcode_string, const int subcode)
{
	if (formatted_barcode_string) {
		*formatted_barcode_string = NULL;
	}
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	const char * string = validate_string_EAN(str, subcode);
	
	if (!string) {
		return NULL;
	}
#ifdef BARCODE_DEBUG
	printf("EAN: '%s'[%lu]--prep-->'%s'[%lu]\n\n", str, strlen(str), string, strlen(string));
#endif
	if (formatted_barcode_string) {
		*formatted_barcode_string = string;
	}

	unsigned int *code_buffer = shared_code_buffer_32;
	convert_string_to_int_buffer(string, subcode, code_buffer, subcode);
	
	return (subcode == 8) ? barcode_encode_codebuffer_EAN8(code_buffer) : barcode_encode_codebuffer_EAN13(code_buffer);
}

const char ** barcode_encode_codebuffer_EAN8(unsigned int *code_buffer)
{
	static const char *substrings[20];
	size_t substring_i = 0;
	
	//	START
	substrings[substring_i++] = EAN_start_stop_string;
	for (size_t i = 0; i < 8; ++i) {
		if (i == 4) {
			//	CENTER
			substrings[substring_i++] = EAN_center_string;
		}
		substrings[substring_i++] = CodeTableEAN_setA[code_buffer[i]];
	}
	//	STOP
	substrings[substring_i++] = EAN_start_stop_string;
	substrings[substring_i] = NULL;
	return substrings;
}

const char *barcode_encode_as_bitmap_EAN8(const char *str, const char **formatted_barcode_string)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
		return NO;
	}
	if (!isValidString_EAN(str, 8)) {
		return NULL;
	}
	
	const size_t leng = strlen(str);
	if (leng > 8) {
		return NULL;
	}
	
	unsigned int *code_buffer = shared_code_buffer_32;
	convert_string_to_int_buffer(str, leng, code_buffer, 8);
	code_buffer[7] = barcode_calc_checksum_EAN(code_buffer, 8);
	
	if (formatted_barcode_string) {
		char *pfstr = shared_char_buffer_90;
		*formatted_barcode_string = shared_char_buffer_90;
		for (size_t i=0; i<=3; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = ' ';
		for (size_t i=4; i<=7; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = '\0';
	}
	
	const char *substrings[20];
	size_t substring_i = 0;
	
	//	START
	substrings[substring_i++] = EAN_start_stop_string;
	for (size_t i = 0; i < 8; ++i) {
		if (i == 4) {
			//	CENTER
			substrings[substring_i++] = EAN_center_string;
		}
		substrings[substring_i++] = CodeTableEAN_setA[code_buffer[i]];
	}
	//	STOP
	substrings[substring_i++] = EAN_start_stop_string;
	substrings[substring_i] = NULL;
	
	char *buffer = shared_char_buffer_1024;
#ifdef BARCODE_DEBUG
	size_t lll =
#endif
	join_substrings(substrings, buffer, NULL);

#ifdef BARCODE_DEBUG
	printf("join buf[%ld]:'%s'\n", lll, buffer);
#endif
	
	const char *encoded_data = expand_buffer_as_bitmap (buffer);

#ifdef BARCODE_DEBUG
	printf("encoded_data[%ld]:%s;\n", strlen(encoded_data), encoded_data);
#endif

	return encoded_data;
}

const char *barcode_encode_as_bitmap_EAN13(const char *str, const char **formatted_barcode_string)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
		return NO;
	}
	if (!isValidString_EAN(str, 13)) {
		return NULL;
	}
	
	const size_t leng = strlen(str);
	if (leng > 13) {
		return NULL;
	}
	
	unsigned int *code_buffer = shared_code_buffer_32;
	convert_string_to_int_buffer(str, leng, code_buffer, 13);
	code_buffer[12] = barcode_calc_checksum_EAN(code_buffer, 13);
	
	if (formatted_barcode_string) {
		char *pfstr = shared_char_buffer_90;
		*formatted_barcode_string = shared_char_buffer_90;
		*(pfstr++) = code_buffer[0] + '0';
		*(pfstr++) = ' ';
		for (size_t i=1; i<=6; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = ' ';
		for (size_t i=7; i<=12; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = '\0';
	}
	
#ifdef BARCODE_DEBUG
	{{
		const size_t buf_size = 13;
		const size_t str_size = leng;
		printf ("buf_size:%zd; str_size:%zd;\n", buf_size, str_size);
		for (size_t i=0; i<buf_size; ++i) {
			printf(" %d   ", code_buffer[i]);
		}
		printf("\n");
		for (size_t i=0; i<buf_size; ++i) {
			printf("i%02zd  ", i);
		}
		printf("\n");
	}}
#endif

	
	const char *substrings[20];
	const char **psubstrings = substrings;
	
	const char *parity = CodeTableEAN13_parity[code_buffer[0]];
	
	//	START
	*(psubstrings++) = EAN_start_stop_string;
	for (size_t i = 1; i < 13; ++i) {
		if (i == 7) {
			//	CENTER
			*(psubstrings++) = EAN_center_string;
		}
		unsigned int code = code_buffer[i];
		if ((i > 1) && (i < 7) && (parity[i-2] == 'B')) {
			*(psubstrings++) = CodeTableEAN_setB[code];
		}
		else {
			*(psubstrings++) = CodeTableEAN_setA[code];
		}
	}
	//	STOP
	*(psubstrings++) = EAN_start_stop_string;
	*(psubstrings++) = NULL;
	
	char *buffer = shared_char_buffer_1024;
#ifdef BARCODE_DEBUG
	size_t lll =
#endif
	join_substrings(substrings, buffer, NULL);
	
#ifdef BARCODE_DEBUG
	printf("join buf[%ld]:'%s'\n", lll, buffer);
#endif
	
	const char *encoded_data = expand_buffer_as_bitmap (buffer);
	
#ifdef BARCODE_DEBUG
	printf("encoded_data[%ld]:%s;\n", strlen(encoded_data), encoded_data);
#endif
	
	return encoded_data;
}

const char ** barcode_encode_codebuffer_EAN13(unsigned int *code_buffer)
{
	static const char *substrings[20];
	const char **psubstrings = substrings;
	
	const char *parity = CodeTableEAN13_parity[code_buffer[0]];
	
	//	START
	*(psubstrings++) = EAN_start_stop_string;
	for (size_t i = 1; i < 13; ++i) {
		if (i == 7) {
			//	CENTER
			*(psubstrings++) = EAN_center_string;
		}
		unsigned int code = code_buffer[i];
		if ((i > 1) && (i < 7) && (parity[i-2] == 'B')) {
			*(psubstrings++) = CodeTableEAN_setB[code];
		}
		else {
			*(psubstrings++) = CodeTableEAN_setA[code];
		}
	}
	//	STOP
	*(psubstrings++) = EAN_start_stop_string;
	*(psubstrings++) = NULL;
	return substrings;
}


#pragma mark - UPC-A, UPC-E

//	string must be prepared first
char * validate_string_EAN_UPC (char *string, const size_t max_leng, const size_t min_leng, BOOL insert_zero)
{
	if (!string || (max_leng < 1)) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	size_t string_length = strlen(string);
	if (string_length < 1) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	if (string_length < min_leng || string_length > max_leng) {
        switch (min_leng) {
            case 8:
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceedEAN8Limit;
                break;
            case 11:
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCALimit;
                break;
            case 13:
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceedEAN13Limit;
                break;
                
            default:
                break;
        }
		return NULL;
	}
	for (size_t i = 0; i < string_length; ++i) {
		if (!isdigit(string[i])) {
			if ((i == max_leng-1) && (string[i] == WILDSYMBOL)) {
				//	wildsymbol is OK at the end only
				break;
			}
            BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
			return NULL;
		}
	}

	//	the last digit may be a checksum
	unsigned int *code_buffer = shared_code_buffer_32;
	code_buffer[0]=0;	//	leading zero
	const size_t digits_number = convert_string_to_int_buffer(string, max_leng-1, code_buffer+1, max_leng-1);
		
	
	const size_t code_length = insert_zero ? max_leng : max_leng-1;

	if (0 == digits_number) {
		printf("cannot convert string into digits\n");
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	
	const unsigned int checksum = insert_zero ?
		barcode_calc_checksum_EAN (code_buffer, code_length) :
		barcode_calc_checksum_EAN (code_buffer+1, code_length);
	const char checksymbol = (char)checksum + '0';

#ifdef BARCODE_DEBUG
	printf("chk:%d; \n", checksum);
#endif
	if (string[string_length-1] == WILDSYMBOL) {
		//	replace wildsymbol with checksum
		string[string_length-1] = checksymbol;
		return string;
	}
    BOOL is_correct_checksymbol = (string[string_length-1] == checksymbol);
    if (!is_correct_checksymbol)
    {
        BarcodeLastErrorCode = ZBarcodeErrorCodeWrongChecksum;
        return NULL;
    }
    return string;
	//	compare the last symbol with checksymbol
//	return (string[string_length-1] == checksymbol) ? string : NULL;
}


char * convert_UPCA_into_UPCE(const char *string_UPCA);

const char * validate_string_UPC (const char *string, const char subcode)
{
	const size_t string_length = string ? strlen(string) : 0;
	if (!string_length) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	
	switch (subcode) {
		case 'A': {
			if (string_length < 10 || string_length > 12) {
                BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCALimit;
				return NULL;
			}
			char * local_copy = shared_char_formatted_string;
			size_t indx = 0;
			if (string_length == 10) {
				local_copy[0] = '0';	//	leading '0'
				indx = 1;
			}
			for (size_t i=0; i <= string_length; ++i) {
				local_copy[indx++] = string[i];
			}
			if (string_length == 10 || string_length == 11) {
				local_copy[11] = WILDSYMBOL;
				local_copy[12] = '\0';
			}
			
			return validate_string_EAN_UPC(local_copy, 12, 11, NO);
		}
			
		case 'E':
			return validate_string_UPCE(string);
			
		default:
			printf("UPC: invalid subcode '%c'\n", subcode);
	}
	return NULL;
}

const char * validate_string_UPCE(const char *string)
{
	const size_t string_length = string ? strlen(string) : 0;
	if (!string_length) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	//	digits only
	for (size_t i=0; i<string_length; ++i) {
		if (!isdigit(string[i])) {
			printf("wrong symbol '%c' at %zu\n", string[i], i);
            BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
			return NULL;
		}
	}
	
	static char local_copy[13];
	bzero(local_copy, sizeof(local_copy));
	
	unsigned int codebuffer[12] = {0};
	
	//	UPC-A
	if (string_length >= 10 && string_length <= 12) {
		printf("UPC-A\n");
		size_t indx = 0;
		if (string_length == 10) {
			local_copy[indx++] = '0';	//	leading '0'
			local_copy[11] = WILDSYMBOL;
		}
		for (size_t i=0; i < string_length; ++i) {
			local_copy[indx++] = string[i];
		}
		if (string_length == 11) {
			local_copy[11] = WILDSYMBOL;
		}
		local_copy[12] = '\0';
		
		
		char * str_UPCE = convert_UPCA_into_UPCE(local_copy);
		if (!str_UPCE) {
			return NULL;
		}
		
		const size_t code_leng = convert_string_to_int_buffer(local_copy, 11, codebuffer, 11);
		if (0 == code_leng) {
			return NULL;
		}
		unsigned int chksum = barcode_calc_checksum_EAN(codebuffer, 11);
		if (local_copy[11] == WILDSYMBOL) {
			local_copy[11] = chksum + '0';
			str_UPCE[7] = chksum + '0';
		}
		else {
			if (local_copy[11] != (chksum + '0')) {
				printf("wrong checksum %c != %d\n", local_copy[11], chksum);
                BarcodeLastErrorCode = ZBarcodeErrorCodeWrongChecksum;
				return NULL;
			}
		}
		return str_UPCE;
	}
	
	//	UPC-E
	if (string_length >= 6 && string_length <= 8) {
		printf("UPC-E\n");
		size_t indx = 0;
		if (string_length == 6) {
			local_copy[indx++] = '0';	//	leading '0'
			local_copy[7] = WILDSYMBOL;
		}
		for (size_t i=0; i < string_length; ++i) {
			local_copy[indx++] = string[i];
		}
		if (string_length == 7) {
			local_copy[7] = WILDSYMBOL;
		}
		local_copy[8] = '\0';
		
		BOOL success = transcode_UPCE_to_UPCA_codebuffer(local_copy, codebuffer);
		if (!success) {
			printf("cannot convert to UPC-A\n");
			return NULL;
		}
		
		unsigned int chksum = barcode_calc_checksum_EAN(codebuffer, 11);
		if (local_copy[7] == WILDSYMBOL) {
			local_copy[7] = chksum + '0';
		}
		else {
			if (local_copy[7] != (chksum + '0')) {
				printf("wrong checksum %c != %d\n", local_copy[7], chksum);
                BarcodeLastErrorCode = ZBarcodeErrorCodeWrongChecksum;
				return NULL;
			}
		}
		return local_copy;
	}
	BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCELimit;
    BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCELimit;
	return NULL;
}

char * convert_UPCA_into_UPCE(const char *string_UPCA)
{
	const size_t string_length = string_UPCA ? strlen(string_UPCA) : 0;
	if (!string_length) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	if (string_length != 12) {
		printf("upca must contain 12 symbols not %zu", string_length);
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCELimit;
		return NULL;
	}
	if ((string_UPCA[0] != '0') && (string_UPCA[0] != '1')) {
		printf("the 1st symbol of upca->e must be 0 or 1 not %c", string_UPCA[0]);
	}
	
	static char string_UPCE[9];
	string_UPCE[8] = '\0';
	string_UPCE[7] = string_UPCA[11];	//	checksymbol
	string_UPCE[0] = string_UPCA[0];	//	number system 0/1
	//	there are 10 testcases
	//	0
	if (0 == memcmp(string_UPCA+3, "00000", 5)) {
		string_UPCE[1] = string_UPCA[1];
		string_UPCE[2] = string_UPCA[2];
		string_UPCE[3] = string_UPCA[8];
		string_UPCE[4] = string_UPCA[9];
		string_UPCE[5] = string_UPCA[10];
		string_UPCE[6] = '0';
		return string_UPCE;
	}
	
	//	1
	if (0 == memcmp(string_UPCA+3, "10000", 5)) {
		string_UPCE[1] = string_UPCA[1];
		string_UPCE[2] = string_UPCA[2];
		string_UPCE[3] = string_UPCA[8];
		string_UPCE[4] = string_UPCA[9];
		string_UPCE[5] = string_UPCA[10];
		string_UPCE[6] = '1';
		return string_UPCE;
	}
	
	//	2
	if (0 == memcmp(string_UPCA+3, "20000", 5)) {
		string_UPCE[1] = string_UPCA[1];
		string_UPCE[2] = string_UPCA[2];
		string_UPCE[3] = string_UPCA[8];
		string_UPCE[4] = string_UPCA[9];
		string_UPCE[5] = string_UPCA[10];
		string_UPCE[6] = '2';
		return string_UPCE;
	}
	
	//	3
	if (0 == memcmp(string_UPCA+4, "00000", 5)) {
		string_UPCE[1] = string_UPCA[1];
		string_UPCE[2] = string_UPCA[2];
		string_UPCE[3] = string_UPCA[3];
		string_UPCE[4] = string_UPCA[9];
		string_UPCE[5] = string_UPCA[10];
		string_UPCE[6] = '3';
		return string_UPCE;
	}
	
	//	4
	if (0 == memcmp(string_UPCA+5, "00000", 5)) {
		string_UPCE[1] = string_UPCA[1];
		string_UPCE[2] = string_UPCA[2];
		string_UPCE[3] = string_UPCA[3];
		string_UPCE[4] = string_UPCA[4];
		string_UPCE[5] = string_UPCA[10];
		string_UPCE[6] = '4';
		return string_UPCE;
	}
	
	//	5
	if (0 == memcmp(string_UPCA+6, "00005", 5)) {
		strncpy(string_UPCE+1, string_UPCA+1, 5);
		string_UPCE[6] = '5';
		return string_UPCE;
	}
	
	//	6
	if (0 == memcmp(string_UPCA+6, "00006", 5)) {
		strncpy(string_UPCE+1, string_UPCA+1, 5);
		string_UPCE[6] = '6';
		return string_UPCE;
	}
	
	//	7
	if (0 == memcmp(string_UPCA+6, "00007", 5)) {
		strncpy(string_UPCE+1, string_UPCA+1, 5);
		string_UPCE[6] = '7';
		return string_UPCE;
	}
	
	//	8
	if (0 == memcmp(string_UPCA+6, "00008", 5)) {
		strncpy(string_UPCE+1, string_UPCA+1, 5);
		string_UPCE[6] = '8';
		return string_UPCE;
	}
	
	//	9
	if (0 == memcmp(string_UPCA+6, "00009", 5)) {
		strncpy(string_UPCE+1, string_UPCA+1, 5);
		string_UPCE[6] = '9';
		return string_UPCE;
	}
	
    BarcodeLastErrorCode = ZBarcodeErrorCodeCanNotConvertToUPCE;
	return NULL;
}


size_t prepare_string_UPC_EAN (const char *string, char *result_str, const size_t expected_length)
{
	const size_t length = strlen(string);
	if (length > expected_length || length < 6) {
		//	out of bounds
		result_str[0] = '\0';
		return 0;
	}
	result_str[expected_length] = '\0';
	if (length == expected_length) {
		//	just copy 1:1
		for (size_t i=0; i<length; ++i) {
			result_str[i] = string[i];
		}
	}
	else {
		result_str[expected_length - 1] = WILDSYMBOL;	//	no checksum use WILDSYMBOL instead
		size_t i_out = 0;			//	fill with leading '0's
		for (; i_out<expected_length-length-1; ++i_out) {
			result_str[i_out] = '0';
		}
		for (size_t i_in = 0; i_in < length; ++i_in, ++i_out) {
			result_str[i_out] = string[i_in];
		}
	}
	return length;
}

const char *barcode_encode_as_bitmap_UPCA(const char *str_to_encode, const char **formatted_barcode_string)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str_to_encode) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	const char * str = validate_string_UPC(str_to_encode, 'A');
	if (!str) {
		return NULL;
	}
	const size_t leng = strlen(str);
	
	char string2[11];
	if (leng == 10) {
		//	insert 0
		memcpy(string2+1, str, 10);
		string2[10] = '\0';
		string2[0] = '0';
		isValidString_EAN(string2, 12);
	}
	
	const char *string = (leng == 10) ? string2 : str;
#ifdef BARCODE_DEBUG
	printf("UPCA-string:'%s'\n", string);
#endif
	
	unsigned int *code_buffer = shared_code_buffer_32;
	convert_string_to_int_buffer(string, leng, code_buffer, 12);
	code_buffer[11] = barcode_calc_checksum_EAN(code_buffer, 11);
	
	if (formatted_barcode_string) {
		char *pfstr = shared_char_buffer_90;
		*formatted_barcode_string = shared_char_buffer_90;
		*(pfstr++) = code_buffer[0] + '0';
		*(pfstr++) = ' ';
		for (size_t i=1; i<=5; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = ' ';
		for (size_t i=6; i<=10; ++i) {
			*(pfstr++) = (char)code_buffer[i] + '0';
		}
		*(pfstr++) = '\0';
	}
	
	const char *substrings[20];
	const char **psubstrings = substrings;
	
	*(psubstrings++) = EAN_start_stop_string;
	for (size_t i=0; i<12; ++i) {
		if (i==6) {
			*(psubstrings++) = EAN_center_string;
		}
		const int code = code_buffer[i];
		*(psubstrings++) = CodeTableEAN_setA[code];
	}
	*(psubstrings++) = EAN_start_stop_string;
	*(psubstrings++) = NULL;
	
	
	
	char *buffer = shared_char_buffer_1024;
#ifdef BARCODE_DEBUG
	size_t lll =
#endif
	join_substrings(substrings, buffer, NULL);
	
#ifdef BARCODE_DEBUG
	printf("join buf[%ld]:'%s'\n", lll, buffer);
#endif
	
	const char *encoded_data = expand_buffer_as_bitmap (buffer);
	
#ifdef BARCODE_DEBUG
	printf("encoded_data[%ld]:%s;\n", strlen(encoded_data), encoded_data);
#endif
	
	return encoded_data;
}

const char ** barcode_encode_as_substrings_UPCA(const char *str_to_encode, const char **formatted_barcode_string)
{
	if (formatted_barcode_string) {
		*formatted_barcode_string = NULL;
	}
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str_to_encode) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	const char * string = validate_string_UPC(str_to_encode, 'A');
	const size_t leng = string ? strlen(string) : 0;
	if (!leng) {
		return NULL;
	}
	
	unsigned int *code_buffer = shared_code_buffer_32;
	convert_string_to_int_buffer(string, leng, code_buffer, 12);
	
	if (formatted_barcode_string) {
		*formatted_barcode_string = string;
	}
	
	static const char *substrings[20];
	const char **psubstrings = substrings;
	
	*(psubstrings++) = EAN_start_stop_string;
	for (size_t i=0; i<12; ++i) {
		if (i==6) {
			*(psubstrings++) = EAN_center_string;
		}
		const int code = code_buffer[i];
		*(psubstrings++) = CodeTableEAN_setA[code];
	}
	*(psubstrings++) = EAN_start_stop_string;
	*(psubstrings++) = NULL;
	return substrings;
}

/* Number set for UPC-E symbol (EN Table 4) */
const char *CodeTableUPC_parity0[10] = {"BBBAAA", "BBABAA", "BBAABA", "BBAAAB", "BABBAA", "BAABBA", "BAAABB", "BABABA", "BABAAB", "BAABAB"};
 /* Not covered by BS EN 797:1995 */
const char *CodeTableUPC_parity1[10] = {"AAABBB", "AABABB", "AABBAB", "AABBBA", "ABAABB", "ABBAAB", "ABBBAA", "ABABAB", "ABABBA", "ABBABA"};

const char *const UPCE_start_string = "111";
const char *const UPCE_stop_string = "111111";

//	fills codebuffer[12] with UPCA codes
BOOL transcode_UPCE_to_UPCA_codebuffer (const char *str, unsigned int *codebuffer)
{
	//	prepared string is always 8 (validate_string_UPC)
	const size_t leng = 7;
	const size_t string_length = strlen(str);
	if (string_length < leng) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceedUPCELimit;
		return NO;
	}
	for (size_t i=0; i<leng; ++i) {
		if (!isdigit(str[i])) {
			printf("wrong charachter '%c' at %zu\n", str[i], i);
            BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
			return NO;
		}
	}
	if (str[0] != '0' && str[0] != '1') {
		printf("wrong system number '%c'\n", str[0]);
        BarcodeLastErrorCode = ZBarcodeErrorCodeWrongSystemNumber;
		return NO;
	}
	char local_source[20]={0};
	memcpy(local_source, str, 1+leng);
	const unsigned int first_code = str[0] - '0';	//	number system, must be 0 or 1
	
	/* Two number systems can be used - system 0 and system 1 */
	unsigned int num_system = 1;
	if(leng == 7) {
		if (str[0] != '1') {
			num_system = 0;
			local_source[0] = '0';
		}
		
		for(int i = 0; i < 7; i++) {
			local_source[i] = local_source[i+1];	//	shift leftward by 1, removing the symbol at index [0]
		}
	}
	else {
		num_system = 0;
	}
	
	const unsigned int emode = local_source[5] - '0';
	unsigned int * equivalent_code = codebuffer;
	bzero(equivalent_code, 12*sizeof(unsigned int));
	
	/* Expand the zero-compressed UPCE code to make a UPCA equivalent (EN Table 5) */
	if(num_system == 1) {
		equivalent_code[0] = first_code;
	}
	equivalent_code[1] = local_source[0] - '0';
	equivalent_code[2] = local_source[1] - '0';
	
	switch(emode)
	{
		case 0:
		case 1:
		case 2:
			equivalent_code[3] = emode;
			equivalent_code[8] = local_source[2] - '0';
			equivalent_code[9] = local_source[3] - '0';
			equivalent_code[10] = local_source[4] - '0';
			break;
			
		case 3: {
			equivalent_code[3] = local_source[2] - '0';
			equivalent_code[9] = local_source[3] - '0';
			equivalent_code[10] = local_source[4] - '0';
			break;
		}
			
		case 4:
			equivalent_code[3] = local_source[2] - '0';
			equivalent_code[4] = local_source[3] - '0';
			equivalent_code[10] = local_source[4] - '0';
			break;
		case 5:
		case 6:
		case 7:
		case 8:
		case 9:
			equivalent_code[3] = local_source[2] - '0';
			equivalent_code[4] = local_source[3] - '0';
			equivalent_code[5] = local_source[4] - '0';
			equivalent_code[10] = emode;
			break;
	}
	return YES;
}


const char ** barcode_encode_as_substrings_UPCE (const char *str_to_encode, const char **formatted_barcode_string)
{
	if (formatted_barcode_string) {
		*formatted_barcode_string = NULL;
	}
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str_to_encode) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	const char * str = validate_string_UPCE(str_to_encode);
	if (!str) {
		return NULL;
	}
	
	if (formatted_barcode_string) {
		*formatted_barcode_string = str;
	}
	
	const size_t chk_number = str[7] - '0';
	
	/* Use the number system and check digit information to choose a parity scheme */
	const char *parity = (str[0] == '1') ? CodeTableUPC_parity1[chk_number] : CodeTableUPC_parity0[chk_number];
	
	/* Take all this information and make the barcode pattern */
	static const char *substrings[20];
	size_t subindex = 0;
	
	//	START
	substrings[subindex++] = UPCE_start_string;
	//	BODY
	for (int i = 0; i < 6; i++) {
		const unsigned char symbol = str[i+1];	//	skip [0] sys number
		const size_t index = symbol - '0';
		const char next_parity = parity[i];
		substrings[subindex++] = (next_parity == 'A') ? CodeTableEAN_setA[index] : CodeTableEAN_setB[index];
	}
	
	//	STOP
	substrings[subindex++] = UPCE_stop_string;
	substrings[subindex++] = NULL;
	return substrings;
}

const char *barcode_encode_as_bitmap_UPCE(const char *str_to_encode, const char **formatted_barcode_string)
{
	const char **substrings = barcode_encode_as_substrings_UPCE(str_to_encode, formatted_barcode_string);
	if (substrings) {
		char *buffer = shared_char_buffer_1024;
		join_substrings(substrings, buffer, NULL);
		const char *encoded_data = expand_buffer_as_bitmap (buffer);
		return encoded_data;
	}
	return NULL;
}


#pragma mark - Codabar

BOOL isValidChar_Codabar (const char sym)
{
	if (isdigit(sym)) {
		return YES;
	}
	switch (sym) {
		case '+':
		case '-':
		case '.':
		case '/':
		case '$':
		case ':':
		case 'A':
		case 'B':
		case 'C':
		case 'D':
			return YES;

		default:
			break;
	}
    //BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:sym];

    BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsSelectSymbolsOnly;
	return NO;
}

BOOL isValidString_Codabar (const char *string)
{
	if (!string) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	const size_t leng = strlen(string);
	if (leng > 40) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceed40DigitsLimit;
		return NO;
	}
	for (size_t i=0; i<leng; ++i) {
		if (!isValidChar_Codabar(string[i])) {
			return NO;
		}
	}
	return YES;
}

const char CodeTable_CodabarSet[21] = "0123456789-$:/.+ABCD";

const char *CodeTable_Codabar[20] = {
"1111122",
"1111221",
"1112112",
"2211111",
"1121121",
"2111121",
"1211112",
"1211211",
"1221111",
"2112111",
"1112211",
"1122111",
"2111212",
"2121112",
"2121211",
"1121212",
"1122121",
"1212112",
"1112122",
"1112221"
};

//	encodes & returns 1 symbol into aa a string if can, or NULL if cannot
const char *encode_symbol_Codabar(const char symbol)
{
	for (size_t i=0; i<20; ++i) {
		if (symbol == CodeTable_CodabarSet[i]) {
			return CodeTable_Codabar[i];
		}
	}
	return NULL;
}

BOOL isABCD(const char sym)
{
	return ((sym >= 'A') && (sym <= 'D'));
}

const char *barcode_encode_as_bitmap_Codabar(const char *str)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	if (!isValidString_Codabar(str)) {
		return NO;
	}
	
	const char *substrings[50];

	//	prepare string, add 'A' at the beginning and 'B' at the end (if there are no start/end symbols)
	const size_t leng = strlen(str);
	const char sym_first = str[0];
	char local_string[50];
	char *plocal_string = local_string;
	if (!isABCD(sym_first)) {
		local_string[0] = 'A';
		++plocal_string;
	}
	memcpy(plocal_string, str, leng);
	plocal_string += leng;
	const char sym_last  = str[leng-1];
	if (!isABCD(sym_last)) {
		*(plocal_string++) = 'B';
	}
	*(plocal_string) = '\0';
	
#ifdef BARCODE_DEBUG
	printf("%s string to encode:'%s'\n", __FUNCTION__, local_string);
#endif
	const char **psubstrings = substrings;
	for(char *pstr = local_string; pstr < plocal_string; ++pstr) {
		const char *ssymbol = encode_symbol_Codabar(*pstr);
		if (!ssymbol) {
			//	something must be really wrong
			return NULL;
		}
		*(psubstrings++) = ssymbol;
	}
	*(psubstrings++) = NULL;
	
	char *buffer = shared_char_buffer_1024;
#ifdef BARCODE_DEBUG
	size_t lll =
#endif
	join_substrings(substrings, buffer, "1");
	
#ifdef BARCODE_DEBUG
	printf("join buf[%ld]:'%s'\n", lll, buffer);
#endif
	
	const char *encoded_data = expand_buffer_as_bitmap (buffer);
	
#ifdef BARCODE_DEBUG
	printf("encoded_data[%ld]:%s;\n", strlen(encoded_data), encoded_data);
#endif
	
	return encoded_data;
}


#pragma mark - ITF-14

unsigned int barcode_calc_checksum_ITF14 (const unsigned int *bitmap_codes);

BOOL isValidChar_ITF14 (const char sym)
{
	return isdigit(sym);
}

BOOL isValidString_ITF14 (const char *string)
{
	if (!string) {
		printf("ITF14: 'string == NULL'\n");
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NO;
	}
	
	const size_t leng = strlen(string);
	if (leng < 13 || leng > 14) {
		//	1. must contain 13 or 14 symbols only
        BarcodeLastErrorCode = ZBarcodeErrorCodeExceedITF14Limit;
		return NO;
	}
	
	unsigned int buffer[14];
	for (size_t i=0; i < leng; ++i) {
		if (!isdigit(string[i])) {
			//	2. digits only
			BarcodeLastErrorCode = ZBarcodeErrorCodeDigitsOnly;
			return NO;
		}
		buffer[i] = string[i] - '0';
	}
	
	if (leng == 14) {
		//	3. has already had checksum so check if it is valid
		const unsigned int checksum = barcode_calc_checksum_ITF14(buffer);
		BOOL ok = (checksum == buffer[13]);
		if (!ok) {
			BarcodeLastErrorCode = ZBarcodeErrorCodeWrongChecksum;
		}
		return ok;
	}
	
	return YES;
}

//	bitmap_codes[] must contain 13 digits (each one is [0...9])
unsigned int barcode_calc_checksum_ITF14 (const unsigned int *bitmap_codes)
{
	assert(bitmap_codes != NULL);
	
	/* Calculate the check digit - the same method used for EAN-13 */
	unsigned int check_sum = 0;
	for (int i = 12; i >= 0; i--) {
		check_sum += bitmap_codes[i];
		
		if (!(i & 1)) {
			check_sum += 2 * bitmap_codes[i];
		}
	}
	
	return ((10 - (check_sum % 10)) % 10);
}

const char *barcode_encode_as_bitmap_ITF14 (const char *str, const char **formatted_barcode_string)
{
	BarcodeLastErrorCode = ZBarcodeErrorCodeOK;
	if (!str) {
        BarcodeLastErrorCode = ZBarcodeErrorCodeEmptyString;
		return NULL;
	}
	if (!isValidString_ITF14(str)) {
		return NULL;
	}
	
	const size_t leng = strlen(str);
	unsigned int buffer[14];
	for (size_t i=0; i < leng; ++i) {
		buffer[i] = str[i] - '0';
	}
	buffer[13] = barcode_calc_checksum_ITF14(buffer);
	
	char char_buffer[15];
	for (size_t i=0; i < 14; ++i) {
		char_buffer[i] = '0' + (char)buffer[i];
	}
	char_buffer[14] = '\0';
	
	if (formatted_barcode_string) {
		static char barcode_string[19];
		*formatted_barcode_string = barcode_string;
		
		barcode_string[ 0] = char_buffer[0];
		barcode_string[ 1] = ' ';
		barcode_string[ 2] = char_buffer[1];
		barcode_string[ 3] = char_buffer[2];
		barcode_string[ 4] = ' ';
		barcode_string[ 5] = char_buffer[3];
		barcode_string[ 6] = char_buffer[4];
		barcode_string[ 7] = char_buffer[5];
		barcode_string[ 8] = char_buffer[6];
		barcode_string[ 9] = char_buffer[7];
		barcode_string[10] = ' ';
		barcode_string[11] = char_buffer[8];
		barcode_string[12] = char_buffer[9];
		barcode_string[13] = char_buffer[10];
		barcode_string[14] = char_buffer[11];
		barcode_string[15] = char_buffer[12];
		barcode_string[16] = ' ';
		barcode_string[17] = char_buffer[13];
		barcode_string[18] = '\0';
	}
	
	return barcode_encode_as_bitmap_I25(char_buffer);
}

#pragma mark - Barcode string pattern

const short * barcode_pattern_bar_UPC(const ZBarcodeType symbology)
{
	static const short pattern_UPCE[] = {1,6,1,-1};
	static const short pattern_UPCA[] = {1,6,1,6,1,-1};
	static const short pattern_EAN8[] = {1,4,1,4,1,-1};
	static const short pattern_EAN13[] = {1,6,1,6,1,-1};
	
	switch (symbology) {
		case ZBarcodeTypeUPCE:	return pattern_UPCE;
		case ZBarcodeTypeUPCA:	return pattern_UPCA;
		case ZBarcodeTypeEAN8:	return pattern_EAN8;
		case ZBarcodeTypeEAN13: return pattern_EAN13;
		default:	break;
	}
	return NULL;
}

const short * barcode_pattern_str_UPC(const ZBarcodeType symbology)
{
	static const short pattern_UPCE[] = {1,6,1,-1};
	static const short pattern_UPCA[] = {1,5,5,1,-1};
	static const short pattern_EAN8[] = {0,4,4,0,-1};
	static const short pattern_EAN13[] = {1,6,6,0,-1};
	
	switch (symbology) {
		case ZBarcodeTypeUPCE:	return pattern_UPCE;
		case ZBarcodeTypeUPCA:	return pattern_UPCA;
		case ZBarcodeTypeEAN8:	return pattern_EAN8;
		case ZBarcodeTypeEAN13: return pattern_EAN13;
		default:	break;
	}
	return NULL;
}

#pragma mark - hardcode - end


BOOL is_nstext_valid (NSString *text, const ZBarcodeType type)
{
	if (text.length == 0) {
		return NO;
	}
	return is_text_valid ([text UTF8String], text.length, type);
}

BOOL is_text_valid (const char *text, const size_t leng, const ZBarcodeType type)
{
	if (!text || (0 == leng)) {
		return NO;
	}
	const char *formatted_string = NULL;
	switch (type) {
		case ZBarcodeType39:
			formatted_string = validate_string_c39(text);
			break;
			
		case ZBarcodeTypeI25:
			formatted_string = validate_string_I25(text);
			break;
			
		case ZBarcodeTypeC128A:
			formatted_string = validate_string_C128A(text, leng);
			break;
			
		case ZBarcodeTypeC128B:
			formatted_string = validate_string_C128B(text, leng);
			break;
			
		case ZBarcodeTypeC128C:
			formatted_string = validate_string_C128C(text, leng);
			break;
			
		case ZBarcodeTypeC128auto:
			formatted_string = validate_string_C128auto(text, leng);
			break;
			
		default:
			break;
	}
	
	return (NULL != formatted_string);
}

#pragma mark - Service Functions

size_t substring_item_length (const char * const item_string) {
	if (!item_string) {
		return 0;
	}
	size_t leng = 0;
	for (size_t i=0; item_string[i]; ++i) {
		leng += (item_string[i]-'0');
	}
#ifdef BARCODE_DEBUG
	printf("%s: '%s'[%d]\n", __FUNCTION__, item_string, (int)leng);
#endif
	return leng;
}

#pragma mark - error handling

NSInteger BarcodeLastErrorCode = ZBarcodeErrorCodeOK;

ZBarcodeErrorCode getLastErrorCode (void) {
	return BarcodeLastErrorCode;
}

NSString *ZzErrorCodeStrings[ZBarcodeErrorCodeCOUNT] = {
	nil,
	@"BarcodeErrorDigitsOnly",
	@"BarcodeErrorDigitsSelectSymbolsOnly",
	@"BarcodeErrorAbcDigitsOnly",
	@"BarcodeErrorUpperAbcDigitsOnly",
	@"BarcodeErrorWrongChecksum",
	@"BarcodeErrorEmptyString",
	@"BarcodeErrorExceed40DigitsLimit",
	@"BarcodeErrorExceed60DigitsLimit",
	@"BarcodeErrorEvenCharactersOnly",
	@"BarcodeErrorExceedEAN8Limit",
	@"BarcodeErrorExceedEAN13Limit",
	@"BarcodeErrorUPCALimit",
	@"BarcodeErrorUPCELimit",
	@"BarcodeErrorExceedITF14Limit",
	@"BarcodeErrorUPCEConversion",
	@"BarcodeErrorUPCEConversion",
	@"BarcodeErrorExceedQRCodeLimit",
	@"BarcodeErrorExceedPDF417Limit",
};

NSString *ZzErrorTitleStrings[ZBarcodeErrorCodeCOUNT] = {
	nil,
	@"BarcodeErrorInvalidCharacter",
	@"BarcodeErrorInvalidCharacter",
	@"BarcodeErrorInvalidCharacter",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidUPCEData",
	@"BarcodeErrorInvalidUPCEData",
	@"BarcodeErrorInvalidData",
	@"BarcodeErrorInvalidData",
};

NSString *errorStringWithCode (ZBarcodeErrorCode errorCode) {
	if (errorCode >= ZBarcodeErrorCodeCOUNT || errorCode <= 0) {
		return nil;
	}
	NSString *errorStr = ZzErrorCodeStrings[errorCode];
	return NSLocalizedString(errorStr, @"barcode error string");
}

NSString *errorTitleWithCode (ZBarcodeErrorCode errorCode) {
	if (errorCode >= ZBarcodeErrorCodeCOUNT || errorCode <= 0) {
		return nil;
	}
	NSString *errorStr = ZzErrorTitleStrings[errorCode];
	return NSLocalizedString(errorStr, @"barcode error string");
}

NSString *lastErrorString (void) {
	return errorStringWithCode (BarcodeLastErrorCode);
}
