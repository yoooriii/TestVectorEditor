//
//  ZzBarcodeDrawView.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/19/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZBasicObjectView.h"

@class ZBarcode;

@interface ZzBarcodeDrawView : ZBasicObjectView
@property (nonatomic, strong) ZBarcode * barcodeModel;
@end
