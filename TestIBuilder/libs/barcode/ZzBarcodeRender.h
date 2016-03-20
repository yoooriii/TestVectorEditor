//
//  ZzBarcodeRender.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/14/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBarcode.h"

@interface ZzBarcodeRender : NSObject
@property (nonatomic, strong) ZBarcode * barcodeModel;
- (void)drawRenderRect:(CGRect)renderRect inContext:(CGContextRef)cx isEditing:(BOOL)editing;
@end
