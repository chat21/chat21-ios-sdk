//
//  ChatUser.h
//
//  Created by Andrea Sponziello on 01/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const FIREBASE_USER_ID = @"uid";
static NSString* const FIREBASE_USER_FIRSTNAME = @"firstname";
static NSString* const FIREBASE_USER_LASTNAME = @"lastname";
static NSString* const FIREBASE_USER_IMAGEURL = @"imageurl";
static NSString* const FIREBASE_USER_TIMESTAMP = @"timestamp";
static NSString* const FIREBASE_USER_EMAIL = @"email";

@interface ChatUser : NSObject

@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *firstname;
@property(nonatomic, strong) NSString *lastname;
@property(nonatomic, strong) NSString *fullname;
@property(nonatomic, strong) NSString *imageurl;
@property(nonatomic, strong) NSString *email;
//@property(nonatomic, strong) NSString *password;
@property(nonatomic, assign) NSInteger createdon;
@property(nonatomic, strong) NSDate *createdonAsDate;


-(NSDictionary *)asDictionary;
-(id)init:(NSString *)userid fullname:(NSString *)fullname;

@end
