//
//  YUTagView.m
//  Babe
//
//  Created by Yu Jiang on 3/9/15.
//  Copyright (c) 2015 Benyu. All rights reserved.
//

#import "YUUtils.h"
#import <PulsingHalo/MultiplePulsingHaloLayer.h>
#import "YUTagView.h"

@interface YUTagView () <UIAlertViewDelegate>{
    CGPoint touchStart;
    UILongPressGestureRecognizer *longPresGesture;
}
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) MultiplePulsingHaloLayer *hover;
@end

@implementation YUTagView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    if (self) {
        _imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"element.point.white.png"]];
        [_imageView setFrame: CGRectMake(0, (frame.size.height - _imageView.image.size.height)/2,
                                         _imageView.image.size.width, _imageView.image.size.height)];

        _leftDirection = YES;
        
        [self addSubview: _imageView];

        self.opaque = NO;
        self.editable = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                              action: @selector(tapToChangeDirection:)];
        [self addGestureRecognizer: tapGesture];

        longPresGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                        action: @selector(pressToRemoveSelfFromSuperView:)];
        [self addGestureRecognizer: longPresGesture];
        
        _hover = [[MultiplePulsingHaloLayer alloc] initWithHaloLayerNum:2 andStartInterval: 4];
        _hover.useTimingFunction = YES;
        _hover.radius = _imageView.frame.size.width;
        [_hover setHaloLayerColor: [UIColor blackColor].CGColor];
        [_hover buildSublayers];
        [self.layer insertSublayer: _hover below: _imageView.layer];
        
//        [_hover startAnimation: _imageView];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGPoint orgin = self.frame.origin;
    CGSize size = [YUUtils fontSize: self.word withFont: [UIFont systemFontOfSize: 11] withWidth: MAXFLOAT withHeight: self.bounds.size.height];
    
    //width = imageView.width + triangle + font size + space
    CGRect tagBounds = CGRectMake(orgin.x, orgin.y, size.width + _imageView.frame.size.width, size.height);
    tagBounds.size.height += 10;//top/bottom insets
    // triangle == 1/2 height, left and right space == 1/2 height
    tagBounds.size.width += tagBounds.size.height;
    
    self.frame = tagBounds;
    
    tagBounds = CGRectMake(0, (tagBounds.size.height - _imageView.image.size.height) / 2,
                           _imageView.image.size.width, _imageView.image.size.height);
    
    if (!_leftDirection) {
        tagBounds.origin.x = CGRectGetWidth(self.frame) - _imageView.image.size.width;
    }
    
    _imageView.frame = tagBounds;
    _hover.position = _imageView.center;
}

- (void)drawRect:(CGRect)fullrect{
    [super drawRect:fullrect];
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat radius = 4;
    
    //start at hover imageView
    CGFloat x = CGRectGetWidth(_imageView.frame);
    CGFloat y = fullrect.size.width - x, h = fullrect.size.height;
    CGAffineTransform transform;
    
    if (_leftDirection) {
        transform = CGAffineTransformMakeTranslation(x, 0);
        CGPathMoveToPoint(path, &transform, x, 0);
        
        CGPathAddArcToPoint(path, &transform, y, 0, y, h, radius);
        CGPathAddArcToPoint(path, &transform, y, h, x, h, radius);
        
        CGPathAddArcToPoint(path, &transform, x, h, 0, h/2, radius);
        CGPathAddArcToPoint(path, &transform, 0, h/2, x, 0, radius);
        //make it smooth
//        CGPathAddArcToPoint(path, &transform, x, 0, y, h, radius);
        x += h * 2/3;
    }else{
        transform = CGAffineTransformMakeTranslation(0, 0);
        CGPathMoveToPoint(path, &transform, 0, 0);
        
        CGPathAddArcToPoint(path, &transform, y-x, 0, y, h/2, radius);
        CGPathAddArcToPoint(path, &transform, y, h/2, y-x, h, radius);
        CGPathAddArcToPoint(path, &transform, y-x, h, 0, h, radius);
        CGPathAddArcToPoint(path, &transform, 0, h, 0, 0, radius);
        CGPathAddArcToPoint(path, &transform, 0, 0, y-x, 0, radius);
        
        x = h * 1/4;
    }
    
    CGPathCloseSubpath(path);
    CGContextAddPath(gc, path);
    CGContextSetFillColorWithColor(gc, [[UIColor colorWithWhite: 0.1 alpha: .7] CGColor]);
    CGContextFillPath(gc);
    
    CGPathRelease(path);
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject: [UIFont systemFontOfSize: 11] forKey:NSFontAttributeName];
    [attributes setObject: [UIColor whiteColor] forKey: NSForegroundColorAttributeName];
    [self.word drawAtPoint: (CGPoint){ x, 5} withAttributes: attributes];
    
    UIGraphicsEndImageContext();
}

// Always in one status, need not to change to opposite status
- (void)setEditable:(BOOL)editable{
    if (NO == editable) {
        _editable = NO;
        [self removeGestureRecognizer: longPresGesture];
        self.userInteractionEnabled = NO;
    }else{
        _editable = YES;
        self.userInteractionEnabled = YES;
        longPresGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                        action: @selector(pressToRemoveSelfFromSuperView:)];
        [self addGestureRecognizer: longPresGesture];
    }
}

// self.frame.origin is real current, not position.x, position.y
- (CGPoint)currentPosition{
    return CGPointMake(self.frame.origin.x / self.superview.frame.size.width,
                       self.frame.origin.y / self.superview.frame.size.height);
}

#pragma mark - Gesture Methods
- (void)tapToChangeDirection:(UITapGestureRecognizer *)gesture{
    _leftDirection = !_leftDirection;

    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
}

#pragma  mark - Remove superView and delegate
-(void)pressToRemoveSelfFromSuperView:(UITapGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"警告"
                                                       message: @"确认删除选择的标签吗?"
                                                      delegate: self
                                             cancelButtonTitle: @"取消"
                                             otherButtonTitles: @"确定", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(1 == buttonIndex) {
        [self removeFromSuperview];
        if(self.delegate && [self.delegate respondsToSelector: @selector(didRemovedFromSuperview:)]){
            [self.delegate didRemovedFromSuperview: self];
        }
    }
}

#pragma mark - Touches event methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    touchStart = [touch locationInView:self.superview];
}

- (void)translateUsingTouchLocation:(CGPoint)touchPoint {
    CGPoint newCenter = CGPointMake(self.center.x + touchPoint.x - touchStart.x,
                                    self.center.y + touchPoint.y - touchStart.y);
//    if (self.preventsPositionOutsideSuperview) {
        // Ensure the translation won't cause the view to move offscreen.
        CGFloat midPointX = CGRectGetMidX(self.bounds);
        if (newCenter.x > self.superview.bounds.size.width - midPointX) {
            newCenter.x = self.superview.bounds.size.width - midPointX;
        }
        if (newCenter.x < midPointX) {
            newCenter.x = midPointX;
        }
        CGFloat midPointY = CGRectGetMidY(self.bounds);
        if (newCenter.y > self.superview.bounds.size.height - midPointY) {
            newCenter.y = self.superview.bounds.size.height - midPointY;
        }
        if (newCenter.y < midPointY) {
            newCenter.y = midPointY;
        }
//    }
    self.center = newCenter;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touch = [[touches anyObject] locationInView:self.superview];
    [self translateUsingTouchLocation:touch];
    touchStart = touch;
}

@end
