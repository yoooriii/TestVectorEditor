//
//  ZBarTextItem.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZBarTextItem.h"

@implementation ZBarTextItem

+ (ZBarTextItem *)barTextItemWithCString:(const char *)cString range:(NSRange)range
{
	ZBarTextItem *item = [self new];
	item.string = [[NSString alloc] initWithBytes:cString+range.location length:range.length encoding:NSASCIIStringEncoding];
	return item;
}

- (void)updateSizeWithFont:(UIFont *)font {
	if (!self.string.length) {
		self.stringSize = CGSizeZero;
	}
	
	self.stringSize = [self.string sizeWithFont:font minFontSize:1 actualFontSize:NULL forWidth:CGFLOAT_MAX lineBreakMode:NSLineBreakByCharWrapping];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@:%p> L:%d; s-sz:%@; '%@'",
			[self class], self, (int)self.length, NSStringFromCGSize(self.stringSize), self.string];
}

@end
