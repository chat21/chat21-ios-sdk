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
        self.ballonLeftTextColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        self.ballonLeftBackgroundColor = [UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1.0];
        self.ballonLeftLinkColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        self.linkLeftHLBackgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1.0];
        self.linkLeftHLTextColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        
        self.ballonRightBackgroundColor = [UIColor colorWithRed:0.207 green:0.525 blue:0.968 alpha:1.0];
        self.ballonRightTextColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        self.ballonRightLinkColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        self.linkRightHLBackgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
        self.linkRightHLTextColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        
        self.ballonFont = [UIFont fontWithName:@"Arial" size:20];
        self.lastMessageTextColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        self.lastMessageIsNewTextColor = [UIColor blackColor];
        self.lastMessageTextColor = self.lastMessageTextColor;
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
