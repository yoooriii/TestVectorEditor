//
//  ZCanvasView.m
//  TestIBuilder
//
//  Created by Yu Lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZCanvasView.h"
#import "ZBasicObjectView.h"

@interface ZCanvasView ()


@end

@implementation ZCanvasView
{
	NSMutableArray<ZBasicObjectView*>* _allObjects;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _internalInit];
	}
	
	return self;
}

- (void)_internalInit
{
	self.backgroundColor = [UIColor lightGrayColor];
	self.translatesAutoresizingMaskIntoConstraints = NO;
	_allObjects = [NSMutableArray new];
}

- (NSArray<ZBasicObjectView *> *)allObjects
{
	return _allObjects;
}

- (BOOL)addObject:(ZBasicObjectView *)object
{
	NSParameterAssert(nil != object);
	
	BOOL success = NO;
	if ((nil != object) && ![self.allObjects containsObject:object])
	{
		[self addSubview:object];
		[_allObjects addObject:object];
		success = YES;
	}
	
	return success;
}

- (BOOL)removeObject:(ZBasicObjectView *)object
{
	NSParameterAssert(nil != object);
	
	BOOL success = NO;
	if ((nil != object) && [self.allObjects containsObject:object])
	{
		[object removeFromSuperview];
		[_allObjects removeObject:object];
		success = YES;
	}
	
	return success;
}

- (void)drawRect:(CGRect)rect
{
	[[UIColor blackColor] setStroke];
	
	UIBezierPath * bezier = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 2, 2) cornerRadius:10];
	[bezier stroke];
}

- (void)setSelectedObject:(ZBasicObjectView *)selectedObject
{
	if (_selectedObject != selectedObject)
	{
		_selectedObject.selected = NO;
		_selectedObject = selectedObject;
		_selectedObject.selected = YES;
	}
}

@end
