//
//  ChatCustomView.m
//
//  Created by Andrea Sponziello on 14/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//  tutorial: https://github.com/milanpanchal/IBDesignables/blob/master/IBDesignables/SAMCustomView.m

#import "ChatCustomView.h"

@implementation ChatCustomView

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
}

//-(void)layoutSubviews {
//    [self layoutSubviews];
//    self.layer.cornerRadius = self.cornerRadius;
//}

@end
