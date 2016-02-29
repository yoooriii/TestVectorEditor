//
//  ViewController.m
//  TestIBuilder
//
//  Created by leonid lo on 2/26/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property(nonatomic, strong) IBOutlet UIView* myview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"+++ %@", self.navigationItem);
}

- (IBAction)testAction:(id)sender
{
    NSLog(@"+++ %@", self.navigationItem);
}

- (IBAction)hideKB:(id)sender
{
    [self.view endEditing:YES];
}

@end

#pragma mark -

@interface COSplashViewPlaceholder : UIView
@end

@implementation COSplashViewPlaceholder

//- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder
//{
//    // Reuse splash view defined in LaunchScreen storyboard
//    UIStoryboard* splashScreenStoryboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
//    UIViewController* splashViewController = [splashScreenStoryboard instantiateViewControllerWithIdentifier:@"my-launch"];
//    UIView* splashView = splashViewController.view;
//    splashViewController.view = nil;
//
//    return splashView;
//}

@end
