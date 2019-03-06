//
//  ChatStyles.h
//  tiledesk
//
//  Created by Andrea Sponziello on 03/08/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatStyles : NSObject

// messages
@property(strong, nonatomic) UIFont *ballonFont;
// left ballon
@property(strong, nonatomic) UIColor *ballonLeftBackgroundColor;
@property(strong, nonatomic) UIColor *ballonLeftTextColor;
@property(strong, nonatomic) UIColor *ballonLeftLinkColor;
@property(strong, nonatomic) UIColor *linkLeftHLBackgroundColor;
@property(strong, nonatomic) UIColor *linkLeftHLTextColor;

// right ballon
@property(strong, nonatomic) UIColor *ballonRightBackgroundColor;
@property(strong, nonatomic) UIColor *ballonRightTextColor;
@property(strong, nonatomic) UIColor *ballonRightLinkColor;
@property(strong, nonatomic) UIColor *linkRightHLBackgroundColor;
@property(strong, nonatomic) UIColor *linkRightHLTextColor;

// conversation
@property(strong, nonatomic) UIColor *lastMessageTextColor;
@property(strong, nonatomic) UIColor *lastMessageIsNewTextColor;
@property(strong, nonatomic) UIColor *infoMessageTextColor;

+(ChatStyles *)sharedInstance;

@end
