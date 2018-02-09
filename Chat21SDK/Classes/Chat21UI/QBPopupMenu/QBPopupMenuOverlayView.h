//
//  QBPopupMenuOverlayView.h
//  QBPopupMenu
//
//  Created by Tanaka Katsuma on 2013/11/24.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QBPopupMenu;

@interface QBPopupMenuOverlayView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, weak) QBPopupMenu *popupMenu;

@end
