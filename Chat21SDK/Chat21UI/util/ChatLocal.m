//
//  ChatLocal.m
//  chat21
//
//  Created by Andrea Sponziello on 05/02/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatLocal.h"

@implementation ChatLocal

+(NSString *)translate:(NSString *)key {
    return NSLocalizedStringFromTable(key, @"Chat", nil);
}

@end
