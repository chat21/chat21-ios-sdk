//
//  ChatUpload.m
//  Chat21
//
//  Created by Andrea Sponziello on 20/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatUpload.h"

@implementation ChatUpload

// abstract
-(void)cancel {
}

// abstract
-(void)start {
}

- (NSComparisonResult)compare:(ChatUpload *)otherObject {
    return [self.creationDate compare:otherObject.creationDate];
}

@end
