//
//  ZGestureHandlerView.m
//  TestIBuilder
//
//  Created by leonid lo on 2/29/16.
//  Copyright © 2016 leonid lo. All rights reserved.
//

#import "ZGestureHandlerView.h"
#import "ZRulerView.h"

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

typedef NS_ENUM(NSUInteger, ZPinKind)
{
	ZPinKindLeftTop = 1,
	ZPinKindRightBottom
};

@interface ZPinView : ZHandleMoveView
@property (nonatomic, strong) UIColor * pinColor;
@property (nonatomic, assign) ZPinKind pinKind;
@end


@interface ZSelectionView : ZHandleMoveView
@property (nonatomic, strong) UIColor * selectionColor;
@end


@interface ZGestureHandlerView ()
@property (nonatomic, strong) ZPinView *handleView1;
@property (nonatomic, strong) ZPinView *handleView2;
@property (nonatomic, strong) ZSelectionView *selectionView;
@property (nonatomic, assign) BOOL disableNormalization;
@property (nonatomic, strong) ZRulerView *rulerViewVertical;
@property (nonatomic, strong) ZRulerView *rulerViewHorizontal;
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
    return CGSizeMake(32, 32);
}

@end


@implementation ZPinView

- (void)_internalInit
{
    [super _internalInit];

    self.backgroundColor = [UIColor clearColor];
    self.pinColor = [UIColor blueColor];
	
	if (1) {
		self.layer.borderColor = [UIColor greenColor].CGColor;
		self.layer.borderWidth = 1;
	}
}

- (void)drawRect:(CGRect)rect
{
	CGRect pinRect = CGRectMake(0, 0, CGRectGetMaxX(rect)*0.66, CGRectGetMaxY(rect)*0.66);
	
	switch (self.pinKind)
	{
		case ZPinKindLeftTop:
			break;
			
		case ZPinKindRightBottom:
			pinRect.origin = CGPointMake(CGRectGetMaxX(rect)-pinRect.size.width, CGRectGetMaxY(rect)-pinRect.size.height);
			break;
	}//sw
	
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(pinRect, 2, 2)];
    [[UIColor blackColor] setStroke];
    [self.pinColor setFill];
    path.lineWidth = 1;
    [path fill];
    [path stroke];
}

@end

#pragma mark -


@implementation ZSelectionView

+ (Class)layerClass
{
	return [CAShapeLayer class];
}

- (CAShapeLayer*)shapeLayer
{
	return (CAShapeLayer*)self.layer;
}

- (void)_internalInit
{
    [super _internalInit];

	self.backgroundColor = [UIColor clearColor];
	
	self.shapeLayer.lineWidth = 1;
	self.shapeLayer.lineDashPattern = @[@10,@10];
	self.shapeLayer.strokeColor = [UIColor blueColor].CGColor;
	self.shapeLayer.fillColor = nil;
	
	[self updateShapeLayer];
}

- (void)layoutSubviews
{
	[self updateShapeLayer];
}

- (void)updateShapeLayer
{
	UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:self.bounds];
	self.shapeLayer.path = bezier.CGPath;
}

@end

#pragma mark -


@implementation ZGestureHandlerView

@synthesize moving = _isMoving;

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
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
	_minSelectionSize = CGSizeMake(70, 50);
	
	self.backgroundColor = [UIColor clearColor];
	self.translatesAutoresizingMaskIntoConstraints = NO;

	_selectionView = [ZSelectionView new];
    [self addSubview:self.selectionView];

    _handleView1 = [ZPinView new];
	self.handleView1.pinKind = ZPinKindLeftTop;
    [self addSubview:self.handleView1];

    _handleView2 = [ZPinView new];
	self.handleView2.pinKind = ZPinKindRightBottom;
    [self addSubview:self.handleView2];

    self.userInteractionEnabled = YES;
    [self setNeedsLayout];
	
	_rulerViewVertical = [ZRulerView new];
	self.rulerViewVertical.vertical = YES;
	[self addSubview:self.rulerViewVertical];
	
	_rulerViewHorizontal = [ZRulerView new];
	self.rulerViewHorizontal.vertical = NO;
	[self addSubview:self.rulerViewHorizontal];
	
	
	_selected = YES;
	self.selected = NO;
	
	if (1) {
		self.handleView2.pinColor = [UIColor redColor];
		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
	}
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
		const CGRect bounds = self.bounds;
		
		CGRect frame = bounds;
		frame.size = [self.rulerViewHorizontal sizeThatFits:frame.size];
		self.rulerViewHorizontal.frame = frame;
		
		frame = bounds;
		frame.size = [self.rulerViewVertical sizeThatFits:frame.size];
		self.rulerViewVertical.frame = frame;
    }
}

- (void)subviewDidBeginMoving:(UIView*)subview
{
    if ((subview == self.handleView1) || (subview == self.handleView2))
    {
        [self bringSubviewToFront:subview];
    }

    _isMoving = YES;
	
	typeof(self.delegate) dlg = self.delegate;
	[dlg gestureHandlerViewBeginsMoving:self];
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
			const CGPoint pointD = CGPointDelta(point2, point1);

            short normalize = 0;

            if (pointD.x < self.minSelectionSize.width) {
                normalize |= 1;
            }

            if (pointD.y < self.minSelectionSize.height) {
				normalize |= 2;
            }

            if (normalize)
            {
				CGRect selectionRect = self.selectionRect;
				const CGFloat dx = selectionRect.size.width - self.minSelectionSize.width;
				short resize = 0;
				if (dx < 0) {
					resize |= 1;
					selectionRect.origin.x += dx * 0.5;
					selectionRect.size.width = self.minSelectionSize.width;
				}
				
				const CGFloat dy = selectionRect.size.height - self.minSelectionSize.height;
				if (dy < 0) {
					resize |= 2;
					selectionRect.origin.y += dy * 0.5;
					selectionRect.size.height = self.minSelectionSize.height;
				}
				
				const BOOL swapAnime = ((3 == normalize) || (0 == normalize));
				//TODO: doesnt work right
				if (resize) {
					[UIView animateWithDuration:0.25
									 animations:^{
										 self.selectionView.frame = selectionRect;
									 }
									 completion:^(BOOL finished) {
										 [UIView animateWithDuration:(finished && swapAnime) ? 0.25 : 0 animations:^{
											 self.handleView1.hotPoint = selectionRect.origin;
											 self.handleView2.hotPoint = CGRectGetMaxXY(selectionRect);
										 }];
									 }];
				}
				else {
					[UIView animateWithDuration:swapAnime ? 0.25 : 0 animations:^{
						self.handleView1.hotPoint = selectionRect.origin;
						self.handleView2.hotPoint = CGRectGetMaxXY(selectionRect);
					}];
				}
            }
        }
    }

	typeof(self.delegate) dlg = self.delegate;
	[dlg gestureHandlerViewEndsMoving:self];
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

	typeof(self.delegate) dlg = self.delegate;
	[dlg gestureHandlerViewMoved:self];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected)
    {
        _selected = selected;
        self.handleView1.selected = selected;
        self.handleView2.selected = selected;
        self.selectionView.selected = selected;
		
		const BOOL hidden = !selected;
		self.handleView1.hidden = hidden;
		self.handleView2.hidden = hidden;
		self.selectionView.hidden = hidden;

    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView * hitView = [super hitTest:point withEvent:event];
    return (self == hitView) ? nil : hitView;
}

@end
