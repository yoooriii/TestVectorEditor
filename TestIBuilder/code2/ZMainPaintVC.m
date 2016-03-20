//
//  ZMainPaintVC.m
//  TestIBuilder
//
//  Created by Yu Lo on 3/13/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZMainPaintVC.h"
#import "ZCanvasView.h"
#import "ZGlassView.h"
#import "ZKeepResizeContentView.h"
#import "ZBasicObjectView.h"
#import "ZzUserInteractionControlView.h"
//
#import "ZzBarcodeView.h"
#import "ZBarcode.h"
#import "ZzBarcodeDrawView.h"

@interface ZMainPaintVC () <UIScrollViewDelegate, ZzUserInteractionControlViewDelegate>
@property (nonatomic) UIScrollView * scrollView;
@property (nonatomic) ZCanvasView * canvasView;
@property (nonatomic) ZzUserInteractionControlView * controlView;

@property (nonatomic) UITapGestureRecognizer * tapRecognizer;
//@property (nonatomic) UIPanGestureRecognizer * moveRecognizer;
@end

static const CGSize CanvasSize = {800, 800};

@implementation ZMainPaintVC

- (void)loadView {
	ZKeepResizeContentView * view = [ZKeepResizeContentView new];
	self.view = view;
	view.translatesAutoresizingMaskIntoConstraints = NO;
	
	_scrollView = [UIScrollView new];
	self.scrollView.delegate = self;
	[self.view addSubview:self.scrollView];
	
	_canvasView = [[ZCanvasView alloc] initWithFrame:CGRectMake(0, 0, CanvasSize.width, CanvasSize.height)];
	[self.scrollView addSubview:self.canvasView];
	
	_controlView = [ZzUserInteractionControlView new];
	self.controlView.delegate = self;
	self.controlView.translatesAutoresizingMaskIntoConstraints = NO;
	self.controlView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:self.controlView];
	
	view.subviewsToResize = @[self.scrollView, self.controlView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.scrollView.contentSize = CanvasSize;
	self.scrollView.minimumZoomScale = 0.25;
	self.scrollView.maximumZoomScale = 4;
	
	[self loadCanvas];
	
	_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapRecognizer:)];
	[self.scrollView addGestureRecognizer:self.tapRecognizer];
	
//	_moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didMoveRecognizer:)];
//	[self.view addGestureRecognizer:self.moveRecognizer];
	
}

- (void)loadCanvas {
	ZBarcode* barcodeModel = [ZBarcode new];
	barcodeModel.symbology = ZBarcodeTypeUPCA;
	barcodeModel.barcodeCompound = ZBcCompoundBarcodeText;
	barcodeModel.font = [UIFont systemFontOfSize:12];
	barcodeModel.foregroundColor = [UIColor blackColor];
	barcodeModel.backgroundColor = [UIColor whiteColor];
	barcodeModel.horizontalAlignment = ZHorizontalAlignmentCenter;
	barcodeModel.verticalAlignment = ZVerticalAlignmentMiddle;
	barcodeModel.text = @"9876543210";

	ZBasicObjectView * view1 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(10, 10, 100, 150)];
	view1.backgroundColor = [UIColor magentaColor];
	[self.canvasView addObject:view1];
	
	ZBasicObjectView * view2 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(500, 10, 100, 150)];
	view2.backgroundColor = [UIColor cyanColor];
	[self.canvasView addObject:view2];
	
	ZzBarcodeDrawView * view3 = [[ZzBarcodeDrawView alloc] initWithFrame:CGRectMake(10, 500, 100, 150)];
	view3.barcodeModel = barcodeModel;
	view3.backgroundColor = [UIColor brownColor];
	[self.canvasView addObject:view3];
	
	ZzBarcodeView * view4 = [[ZzBarcodeView alloc] initWithFrame:CGRectMake(600, 600, 100, 150)];
	view4.barcodeModel = barcodeModel;
	view4.backgroundColor = [UIColor orangeColor];
	[self.canvasView addObject:view4];
}

#pragma mark - 

- (void)didTapRecognizer:(UITapGestureRecognizer*)recognizer
{
	const CGPoint canvasPoint = [recognizer locationInView:self.canvasView];
	ZBasicObjectView * tapObject = nil;

	for (ZBasicObjectView * object in self.canvasView.allObjects) {
		if (CGRectContainsPoint(object.frame, canvasPoint)) {
			tapObject = object;
			break;
		}
	}
	
	if (tapObject) {
		self.canvasView.selectedObject = tapObject;
		CGRect selRect = [self.controlView convertRect:tapObject.frame fromView:tapObject.superview];
		self.controlView.selectionRect = selRect;
		self.controlView.selected = YES;
	}
	else
	{
		self.controlView.selected = NO;
	}
}

//- (void)didMoveRecognizer:(UITapGestureRecognizer*)recognizer
//{
//	NSLog(@"%s: %@", __PRETTY_FUNCTION__, recognizer);
//}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.canvasView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	ZBasicObjectView * selectedObject = self.canvasView.selectedObject;
	if (selectedObject) {
		CGRect selRect = [self.controlView convertRect:selectedObject.frame fromView:selectedObject.superview];
		self.controlView.selectionRect = selRect;
	}
}

#pragma mark - ZzUserInteractionControlViewDelegate

- (void)gestureHandlerViewBeganMoving:(ZzUserInteractionControlView*)view {
	
}

- (void)gestureHandlerViewMoved:(ZzUserInteractionControlView*)view
{
	self.canvasView.selectedObject.frame = [self.canvasView convertRect:view.selectionRect fromView:view];
}

- (void)gestureHandlerViewEndsMoving:(ZzUserInteractionControlView*)view
{
	self.canvasView.selectedObject.frame = [self.canvasView convertRect:view.selectionRect fromView:view];
}

@end
