//
//  ZzBarcodeLayer.h
//  TestIBuilder
//
//  Created by Yu Lo on 3/18/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZBarcode.h"

@interface ZzBarcodeLayer : CALayer

@property (nonatomic, strong) ZBarcode *barcodeModel;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CATextLayer *textLayer;

@end
