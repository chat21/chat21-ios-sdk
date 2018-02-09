//
//  FirebaseCustomAuthHelper.m
//  Soleto
//
//  Created by Andrea Sponziello on 13/11/14.
//

#import "FirebaseCustomAuthHelper.h"
//#import <Firebase/Firebase.h>

@import Firebase;

@implementation FirebaseCustomAuthHelper

- (id) initWithFirebaseRef:(FIRDatabaseReference *)ref token:(NSString *)token {
    self = [super init];
    if (self) {
        NSLog(@" ref: %@ token: %@", ref, token);
        self.ref = ref;
        self.token = token;
    }
    return self;
}

- (void) authenticate:(void (^)(NSError *, FAuthData *authData))callback {
    NSLog(@"authenticate: WARNING! NOT IMPLEMENTED!");
//    [self.ref authWithCustomToken:self.token withCompletionBlock:^(NSError *error, FAuthData *authData) {
////        NSLog(@"End Login:\nError:%@\nauth:%@\nuid:%@\nprovider:%@\ntoken:%@\nproviderData:%@", error, authData.auth, authData.uid, authData.provider, authData.token, authData.providerData);
//        NSLog(@"email: %@", [authData.auth objectForKey:@"email"]);
//        NSLog(@"uid: %@", [authData.auth objectForKey:@"uid"]);
//        NSLog(@"username: %@", [authData.auth objectForKey:@"username"]);
//        if (error) {
//            NSLog(@"Login Failed! %@", error);
//        } else {
//            NSLog(@"Login succeeded! %@", authData);
//            callback(error, authData);
//        }
//    }];
}

@end
