//
//  QBPopupMenuOverlayView.m
//  QBPopupMenu
//
//  Created by Tanaka Katsuma on 2013/11/24.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBPopupMenuOverlayView.h"

#import "QBPopupMenu.h"

@implementation QBPopupMenuOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReceived:)];
        [tapGestureRecognizer setDelegate:self];
        tapGestureRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tapGestureRecognizer];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tapReceived:)];
        [panGestureRecognizer setDelegate:self];
        panGestureRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:panGestureRecognizer];
        
    }
    
    return self;
}

-(void)tapReceived:(UITapGestureRecognizer *)tapGestureRecognizer
{
    NSLog(@".......TAPPED!!!");
    [self.popupMenu dismissAnimated:YES];
}

//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    NSLog(@"TOUCHED!!!");
//    UITouch *touch = [touches anyObject];
//    UIView *view = touch.view;
//    
//    if (view == self) {
//        // Close popup menu
//        [self.popupMenu dismissAnimated:YES];
//    }
//}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"BEGAN!!!");
//    UITouch *touch = [touches anyObject];
//    UIView *view = touch.view;
//    
//    if (view == self) {
//        // Close popup menu
//        [self.popupMenu dismissAnimated:YES];
//    }
//
//}


//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"MOVED!!!");
//    UITouch *touch = [touches anyObject];
//    UIView *view = touch.view;
//    
//    if (view == self) {
//        NSLog(@"CLOSING MOVED!!!");
//        // Close popup menu
//        [self.popupMenu dismissAnimated:YES];
//    }
//}


@end
