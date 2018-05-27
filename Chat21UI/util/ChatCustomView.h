//
//  ChatCustomView.h
//
//  Created by Andrea Sponziello on 14/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//  tutorial: https://github.com/milanpanchal/IBDesignables/blob/master/IBDesignables/SAMCustomView.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface ChatCustomView : UIView

@property (nonatomic) IBInspectable CGFloat cornerRadius;
@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;

@end
