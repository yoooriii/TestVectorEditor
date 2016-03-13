#import "ZzBarcodesCommon.h"
#import "ZzBarcodePlainFunctions.h"

NSInteger ZzQRCodeWidthForVersion(const NSInteger version)
{
	if (version < 1 || version > 40)
	{
		NSLog(@"Wrong QR Code Version");
	}

	NSInteger width = version * 4 + 17;

	return width;
}

NSInteger ZzQRCodeOptimalVersionForWidth(const NSInteger width)
{
	if (width < 21)
	{
		return 1;
	}

	if (width > 177)
	{
		return 40;
	}

	return (width - 17) / 4;
}
