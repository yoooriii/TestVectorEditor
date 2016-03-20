//
//  NSString+additions.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "NSString+additions.h"

@implementation NSString (additions)

- (CGSize)_deprecated_sizeWithFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode
{
	return [self sizeWithFont:font minFontSize:minFontSize actualFontSize:actualFontSize forWidth:width lineBreakMode:lineBreakMode];
}

- (CGSize)_deprecated_drawInRect:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode alignment:(NSTextAlignment)alignment
{
	return [self drawInRect:rect withFont:font lineBreakMode:lineBreakMode alignment:alignment];
}

@end
