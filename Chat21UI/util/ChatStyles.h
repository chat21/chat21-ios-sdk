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

@property(strong, nonatomic) UIColor *ballonLeftBackgroundColor;
@property(strong, nonatomic) UIColor *ballonRightBackgroundColor;

+(ChatStyles *)sharedInstance;

@end
