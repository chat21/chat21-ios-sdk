//
//  ChatUser.m
//  bppmobile
//
//  Created by Andrea Sponziello on 01/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatUser.h"

@implementation ChatUser

-(id)init {
    if (self = [super init])  {
        self.imageurl = @"";
        self.lastname = @"";
        self.firstname = @"";
        self.userId = nil;
    }
    return self;
}

-(id)init:(NSString *)userid fullname:(NSString *)fullname {
    if (self = [super init])  {
        self.imageurl = @"";
        self.lastname = @"";
        self.firstname = @"";
        _fullname = fullname;
        self.userId = userid;
    }
    return self;
}

// Fullname custom getter
- (NSString*) fullname {
    if (!_fullname) {
        NSString *__firstName = self.firstname ? self.firstname : @"";
        NSString *__lastName = self.lastname ? self.lastname : @"";
        NSString *fullname = [NSString stringWithFormat:@"%@ %@", __firstName, __lastName];
        return fullname;
    }
    else {
        return _fullname;
    }
}

-(NSDictionary *)asDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.userId) {
        [dict setObject:self.userId forKey:FIREBASE_USER_ID];
    }
    if (self.firstname) {
        [dict setObject:self.firstname forKey:FIREBASE_USER_FIRSTNAME];
    }
    if (self.lastname) {
        [dict setObject:self.lastname forKey:FIREBASE_USER_LASTNAME];
    }
    if (self.email) {
        [dict setObject:self.email forKey:FIREBASE_USER_EMAIL];
    }
    if (self.imageurl) {
        [dict setObject:self.imageurl forKey:FIREBASE_USER_IMAGEURL];
    }
    
    return dict;
}

-(NSDate *)createdonAsDate {
    return [NSDate dateWithTimeIntervalSince1970:self.createdon];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToUser:other];
}

- (BOOL)isEqualToUser:(ChatUser *)user {
    if (self == user)
        return YES;
    if (![(id)[self lastname] isEqual:[user lastname]])
        return NO;
    if (![[self firstname] isEqual:[user firstname]])
        return NO;
    if (![[self email] isEqual:[user email]])
        return NO;
//    if (![[self imageurl] isEqual:[user imageurl]])
//        return NO;
    if (![[self userId] isEqual:[user userId]])
        return NO;
    return YES;
}

@end
