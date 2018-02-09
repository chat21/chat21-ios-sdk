//
//  ChatAuth.m
//  chat21
//
//  Created by Andrea Sponziello on 05/02/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatAuth.h"
#import "ChatUser.h"
@import Firebase;

@implementation ChatAuth

+(void)authWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(ChatUser *user, NSError *))callback {
    [[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRUser *user, NSError *error) {
        if (error) {
            NSLog(@"Firebase Auth error for email %@/%@: %@", email, password, error);
            callback(nil, error);
        }
        else {
            NSLog(@"Firebase Auth success. email: %@, emailverified: %d, userid: %@", user.email, user.emailVerified, user.uid);
            ChatUser *chatuser = [[ChatUser alloc] init];
            chatuser.userId = user.uid;
            chatuser.email = user.email;
            callback(chatuser, nil);
        }
    }];
}

@end
