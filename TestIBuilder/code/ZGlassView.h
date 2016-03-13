//
//  ZGlassView.h
//  TestIBuilder
//
//  Created by leonid lo on 3/9/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

typedef NS_ENUM(int, MyABC) {
	abcAlpha,
	abcBeta
};

@interface ZGlassView : UIView

@property (nonatomic) IBInspectable CGFloat lineWidth;
@property (nonatomic) IBInspectable UIColor * fillColor;
@property (nonatomic) IBInspectable UIColor * strokeColor;

@property (nonatomic) IBInspectable UIImage * myImage;
@property (nonatomic) IBInspectable CGRect myRect;
@property (nonatomic) IBInspectable CGSize mySize;
@property (nonatomic) IBInspectable CGPoint myPoint;
@property (nonatomic) IBInspectable NSString * myString;
@property (nonatomic) IBInspectable BOOL myBool;

@property (nonatomic) IBInspectable UIFont *myFont;


//these do not work
@property (nonatomic) IBInspectable NSAttributedString * myAttrString;
@property (nonatomic) IBInspectable NSArray * myArray;
@property (nonatomic) IBInspectable UIEdgeInsets myInsets;
@property (nonatomic) IBInspectable MyABC myEnum;


@end
