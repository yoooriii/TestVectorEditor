//
//  ZGestureHandlerVC.m
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZGestureHandlerVC.h"
#import "ZGestureHandlerView.h"

@implementation ZGestureHandlerVC

- (void)loadView
{
    self.view = [ZGestureHandlerView new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    return;

    // Create our three labels using the category method

    UILabel *one = [UILabel new];
    one.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *two = [UILabel new];
    two.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *three = [UILabel new];
    three.translatesAutoresizingMaskIntoConstraints = NO;


    // Put some content in there for illustrations
    int labelNumber = 0;
    for (UILabel *label in @[one,two,three])
    {
        label.backgroundColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = [NSString stringWithFormat:@"%d",labelNumber++];
        [self.view addSubview:label];
    }

    // Create the views and metrics dictionaries
    NSDictionary *metrics = @{@"height":@450.0};
    NSDictionary *views = NSDictionaryOfVariableBindings(one,two,three);

    // Horizontal layout - note the options for aligning the top and bottom of all views
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[one(two)]-[two(three)]-[three]-|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:metrics views:views]];

    // Vertical layout - we only need one "column" of information because of the alignment options used when creating the horizontal layout
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[one(height)]-|" options:0 metrics:metrics views:views]];
}

@end
