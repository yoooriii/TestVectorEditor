//
//  ZBarTextItem.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <Foundation/Foundation.h>

//	class holds information about a part of barcode string
@interface ZBarTextItem : NSObject
@property (nonatomic, retain) NSString		*string;
@property (nonatomic, assign) size_t		length;			//	how many barcode stripes it uses
@property (nonatomic, assign) CGSize		stringSize;		//	string size for given font
+ (ZBarTextItem *)barTextItemWithCString:(const char *)cString range:(NSRange)range;
- (void)updateSizeWithFont:(UIFont *)font;
@end
