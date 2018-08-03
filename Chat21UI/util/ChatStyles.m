//
//  ChatStyles.m
//  tiledesk
//
//  Created by Andrea Sponziello on 03/08/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatStyles.h"

static ChatStyles *sharedInstance = nil;

@implementation ChatStyles

-(id)init
{
    if (self = [super init])
    {
        self.ballonLeftBackgroundColor = [UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1.0];
        self.ballonRightBackgroundColor = [UIColor colorWithRed:0.407 green:0.768 blue:0.972 alpha:1.0];
    }
    return self;
}

+(ChatStyles *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

@end
