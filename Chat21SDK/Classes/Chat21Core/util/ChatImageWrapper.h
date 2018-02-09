//
//  ChatImageWrapper.h
//  Salve Smart
//
//  Created by Andrea Sponziello on 05/11/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatImageWrapper : NSObject

@property (nonatomic, strong) NSDate *lastReadTime;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *key;

@end

