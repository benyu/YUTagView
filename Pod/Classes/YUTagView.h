//
//  YUTagView.h
//  Babe
//
//  Created by Yu Jiang on 3/9/15.
//  Copyright (c) 2015 Benyu. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol YUTagViewDelegate;

@interface YUTagView : UIView
@property(nonatomic, copy) NSString *id;
@property(nonatomic, copy) NSString *style;
@property(nonatomic, copy) NSString *word;
@property(nonatomic, assign) CGPoint position;
@property(nonatomic, assign) BOOL editable;
@property(nonatomic, assign, getter=isLeftDirection) BOOL leftDirection;
@property(nonatomic, weak)id<YUTagViewDelegate> delegate;

// the position is a x and y ratio of width and height of superView
- (CGPoint)currentPosition;

@end


@protocol YUTagViewDelegate <NSObject>

-(void)didRemovedFromSuperview:(YUTagView *)view;

@end