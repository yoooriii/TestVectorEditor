//
//  ZzBarcode1DView.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/20/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBasicObjectView.h"

@class ZBarcode;

@interface ZzBarcode1DView : ZBasicObjectView

@property (nonatomic, strong) ZBarcode * barcodeModel;

@end
