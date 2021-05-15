//
//  UIView+Extension.m
//  黑马微博
//
//  Created by 丁巍 on 16/6/21.
//  Copyright © 2016年 weibo. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)

//-----------x------------------
//set 方法
-(void)setX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

//get 方法
-(CGFloat)x{
    return self.frame.origin.x;
}


//------------y-----------------
-(void)setY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

//get 方法
-(CGFloat)y{
    return self.frame.origin.y;
}

//------------width-----------------
-(void)setWidth:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

//get 方法
-(CGFloat)width{
    return self.frame.size.width;
}


//------------width-----------------
-(void)setHeight:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

//get 方法
-(CGFloat)height{
    return self.frame.size.height;
}


//------------size-----------------
-(void)setSize:(CGSize)size{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

//get 方法
-(CGSize)size{
    return self.frame.size;
}

//------------size-----------------
-(void)setOrigin:(CGPoint)origin{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

//get 方法
-(CGPoint)origin{
    return self.frame.origin;
}


//------------x中点-----------------
-(void)setCenterX:(CGFloat)centerX{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

//get 方法
-(CGFloat)centerX{
    return self.center.x;
}


//------------y中点-----------------
-(void)setCenterY:(CGFloat)centerY{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

//get 方法
-(CGFloat)centerY{
    return self.center.y;
}


- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

@end
