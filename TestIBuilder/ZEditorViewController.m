//
//  ZEditorViewController.m
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZEditorViewController.h"
#import "ZBasicObjectView.h"
#import "ZCanvasView.h"
#import "ZGestureHandlerView.h"

@interface ZEditorViewController () <UIScrollViewDelegate>
@property (nonatomic, weak) UIScrollView * scrollView;
@property (nonatomic, strong) ZCanvasView * canvasView;
@end

@implementation ZEditorViewController

- (UIScrollView *)scrollView
{
	return (UIScrollView *) self.view;
}

- (void)loadView
{
	UIScrollView * scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	scroll.delegate = self;
	self.view = scroll;
	
	_canvasView = [[ZCanvasView alloc] initWithFrame:CGRectMake(0, 0, 800, 800)];
	[scroll addSubview:self.canvasView];
	scroll.contentSize = self.canvasView.frame.size;
	scroll.minimumZoomScale = 0.3;
	scroll.maximumZoomScale = 3;
}

- (void)viewDidLoad {
    [super viewDidLoad];


	ZBasicObjectView * view1 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(10, 10, 100, 150)];
	view1.backgroundColor = [UIColor magentaColor];
	[self.canvasView addObject:view1];
	
	ZBasicObjectView * view2 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(500, 10, 100, 150)];
	view2.backgroundColor = [UIColor cyanColor];
	[self.canvasView addObject:view2];
	
	ZBasicObjectView * view3 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(10, 500, 100, 150)];
	view3.backgroundColor = [UIColor brownColor];
	[self.canvasView addObject:view3];
	
	ZBasicObjectView * view4 = [[ZBasicObjectView alloc] initWithFrame:CGRectMake(600, 600, 100, 150)];
	view4.backgroundColor = [UIColor orangeColor];
	[self.canvasView addObject:view4];
	
	
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.canvasView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	ZBasicObjectView * selectedObject = self.canvasView.selectedObject;
	if (selectedObject) {
		CGRect selRect = [self.gestureHandlerView convertRect:selectedObject.frame fromView:selectedObject.superview];
		self.gestureHandlerView.selectionRect = selRect;
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
	
}

#pragma mark - ZGestureHandlerViewDelegate

- (void)gestureHandlerViewBeginsMoving:(ZGestureHandlerView*)view
{

}

- (void)gestureHandlerViewMoved:(ZGestureHandlerView*)view
{
	self.canvasView.selectedObject.frame = [self.canvasView convertRect:view.selectionRect fromView:view];
}

- (void)gestureHandlerViewEndsMoving:(ZGestureHandlerView*)view
{
	self.canvasView.selectedObject.frame = [self.canvasView convertRect:view.selectionRect fromView:view];
}

- (void)gestureHandlerViewDidTap:(ZGestureHandlerView*)view point:(CGPoint)point
{
	ZBasicObjectView * tapObject = nil;
	const CGPoint canvasPoint = [self.canvasView convertPoint:point fromView:view];
	for (ZBasicObjectView * object in self.canvasView.allObjects) {
		if (CGRectContainsPoint(object.frame, canvasPoint)) {
			tapObject = object;
			break;
		}
	}
	
	if (tapObject) {
		self.canvasView.selectedObject = tapObject;
		CGRect selRect = [self.gestureHandlerView convertRect:tapObject.frame fromView:tapObject.superview];
		self.gestureHandlerView.selectionRect = selRect;
		self.gestureHandlerView.selected = YES;
	}
	else
	{
		self.gestureHandlerView.selected = NO;
	}
}

@end
