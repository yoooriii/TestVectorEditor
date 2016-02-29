//
//  ZGestureHandlerView.m
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZGestureHandlerView.h"

static inline CGPoint CGRectGetMaxXY(CGRect rect) {
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
}

static inline CGPoint CGPointDelta(CGPoint pt1, CGPoint pt2) {
    return CGPointMake(pt1.x - pt2.x, pt1.y - pt2.y);
}

static inline CGPoint CGPointPlusPoint(CGPoint pt1, CGPoint pt2) {
    return CGPointMake(pt1.x + pt2.x, pt1.y + pt2.y);
}

@class ZGestureHandlerView;

@interface ZHandleMoveView : UIView
@property (nonatomic, strong) UIPanGestureRecognizer * panRecognizer;
@property (nonatomic, assign) CGPoint hotPoint;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
- (ZGestureHandlerView*)parent;
- (void)_internalInit;
@end

@interface ZPinView : ZHandleMoveView
@property (nonatomic, strong) UIColor * pinColor;
@end


@interface ZSelectionView : ZHandleMoveView
@property (nonatomic, strong) UIColor * selectionColor;
@end


@interface ZGestureHandlerView ()
@property (nonatomic, strong) ZPinView *handleView1;
@property (nonatomic, strong) ZPinView *handleView2;
@property (nonatomic, strong) ZSelectionView *selectionView;
@property (nonatomic, assign) BOOL disableNormalization;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
- (void)subviewDidBeginMoving:(UIView*)subview;
- (void)subviewDidMove:(UIView*)subview;
- (void)subviewDidEndMoving:(UIView*)subview;
@end


#pragma mark -

@implementation ZHandleMoveView
{
    CGPoint _initialPanPosition;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self _internalInit];
    }

    return self;
}

- (void)_internalInit
{
    [self sizeToFit];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizerDidPan:)];
    [self addGestureRecognizer:self.panRecognizer];
    self.userInteractionEnabled = YES;
}

- (ZGestureHandlerView *)parent
{
    return (ZGestureHandlerView*)self.superview;
}

- (CGPoint)hotPoint
{
    return self.center;
}

- (void)setHotPoint:(CGPoint)hotPoint
{
    self.center = hotPoint;
}

- (void)recognizerDidPan:(UIPanGestureRecognizer*)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStatePossible:
            break;
            
        case UIGestureRecognizerStateBegan:
        {
            const CGPoint position = self.hotPoint;
            const CGPoint initialTranslation = [recognizer translationInView:self.superview];
            _initialPanPosition = position;

            CGPoint translation;
            translation.x = position.x - initialTranslation.x;
            translation.y = position.y - initialTranslation.y;

            [recognizer setTranslation:translation inView:self.superview];
            [self.parent subviewDidBeginMoving:self];
            break;
        }

            
        case UIGestureRecognizerStateEnded:
        {
            _initialPanPosition = CGPointZero;
            CGPoint tr = [recognizer translationInView:self.superview];
            self.hotPoint = tr;
            [self.parent subviewDidMove:self];
            [self.parent subviewDidEndMoving:self];
            break;
        }

        case UIGestureRecognizerStateChanged:
        {
            CGPoint tr = [recognizer translationInView:self.superview];
            self.hotPoint = tr;
            [self.parent subviewDidMove:self];
            break;
        }
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            self.hotPoint = _initialPanPosition;
            _initialPanPosition = CGPointZero;
            [self.parent subviewDidMove:self];
            [self.parent subviewDidEndMoving:self];
            break;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view = [super hitTest:point withEvent:event];
    return view;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(44, 44);
}

@end


@implementation ZPinView

- (void)_internalInit
{
    [super _internalInit];

    self.backgroundColor = [UIColor whiteColor];
    self.pinColor = [UIColor blueColor];
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 1, 1)];
    [[UIColor blackColor] setStroke];
    [self.pinColor setFill];
    path.lineWidth = 1;
    [path fill];
    [path stroke];
}

@end

#pragma mark -


@implementation ZSelectionView

- (void)_internalInit
{
    [super _internalInit];

    self.layer.borderColor = [UIColor greenColor].CGColor;
    self.layer.borderWidth = 1;
    self.backgroundColor = [UIColor clearColor];
}

@end

#pragma mark -


@implementation ZGestureHandlerView
{
    BOOL _isMoving;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        if (1) {
            self.layer.borderColor = [UIColor greenColor].CGColor;
            self.layer.borderWidth = 1;
            self.layer.cornerRadius = 10;
        }

        [self _internalInit];
    }

    return self;
}

- (void)_internalInit
{
    _selectionView = [ZSelectionView new];
    [self addSubview:self.selectionView];

    _handleView1 = [ZPinView new];
    if (1) {
        self.handleView1.tag = 1;
    }
    [self addSubview:self.handleView1];

    _handleView2 = [ZPinView new];
    if (1) {
        self.handleView2.tag = 2;
        self.handleView2.pinColor = [UIColor redColor];
    }
    [self addSubview:self.handleView2];

    self.userInteractionEnabled = YES;
    [self setNeedsLayout];
}

- (void)setSelectionRect:(CGRect)selectionRect
{
    self.selectionView.frame = selectionRect;
    self.handleView1.hotPoint = selectionRect.origin;
    self.handleView2.hotPoint = CGRectGetMaxXY(selectionRect);
}

- (CGRect)selectionRect
{
    return self.selectionView.frame;
}

- (void)layoutSubviews
{
    if (!_isMoving)
    {
        NSLog(@"layoutSubviews");
    }
}

- (void)subviewDidBeginMoving:(UIView*)subview
{
    if ((subview == self.handleView1) || (subview == self.handleView2))
    {
        [self bringSubviewToFront:subview];
    }

    _isMoving = YES;
}

- (void)subviewDidEndMoving:(UIView*)subview
{
    _isMoving = NO;

    if (!self.disableNormalization)
    {
        if ((subview == self.handleView1) || (subview == self.handleView2))
        {
            //  normalize rect if needed
            const CGPoint point1 = self.handleView1.hotPoint;
            const CGPoint point2 = self.handleView2.hotPoint;

            BOOL normalize = NO;

            if (point1.x > point2.x) {
                normalize = YES;
            }

            if (point1.y > point2.y) {
                normalize = YES;
            }

            if (normalize)
            {
                const CGRect selectionRect = self.selectionRect;
                [self setSelectionRect:selectionRect];
                
            }
        }
    }
}

- (void)subviewDidMove:(UIView*)subview
{
    if ((subview == self.handleView1) || (subview == self.handleView2))
    {
        //  resize w left-top / right-bottom
        const CGPoint point1 = self.handleView1.hotPoint;
        const CGPoint point2 = self.handleView2.hotPoint;

        CGRect selectionRect;
        selectionRect.origin = point1;
        selectionRect.size.width = point2.x - point1.x;
        selectionRect.size.height = point2.y - point1.y;

        self.selectionView.frame = selectionRect;
    }
    else if (subview == self.selectionView)
    {
        //  move selection rect
        CGRect selectionRect = self.selectionView.frame;
        self.handleView1.hotPoint = selectionRect.origin;
        self.handleView2.hotPoint = CGRectGetMaxXY(selectionRect);
    }
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected)
    {
        _selected = selected;
        self.handleView1.selected = selected;
        self.handleView2.selected = selected;
        self.selectionView.selected = selected;
    }
}

@end
