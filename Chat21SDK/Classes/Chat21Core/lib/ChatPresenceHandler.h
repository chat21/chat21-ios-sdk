//
//  ChatPresenceHandler.h
//  Chat21
//
//  Created by Andrea Sponziello on 02/01/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatPresenceViewDelegate.h"

@import Firebase;

@class FirebaseCustomAuthHelper;
@class Firebase;
@class ChatUser;

@interface ChatPresenceHandler : NSObject

@property (strong, nonatomic) ChatUser *loggeduser;
@property (strong, nonatomic) FirebaseCustomAuthHelper *authHelper;

@property (strong, nonatomic) NSString *firebaseToken;
//@property (assign, nonatomic) id <ChatPresenceViewDelegate> delegate;
//@property (strong, nonatomic) NSString *firebaseRef;
@property (strong, nonatomic) FIRDatabaseReference *rootRef;
@property (strong, nonatomic) NSString *tenant;
@property (assign, nonatomic) FIRDatabaseHandle connectionsRefHandle;
@property (strong, nonatomic) FIRDatabaseReference *deviceConnectionRef;
@property (strong, nonatomic) NSString *deviceConnectionKey;

//-(id)initWithFirebaseRef:(NSString *)firebaseRef tenant:(NSString *)tenant user:(SHPUser *)user;
-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user;
+(FIRDatabaseReference *)onlineRefForUser:(NSString *)userid;
+(FIRDatabaseReference *)lastOnlineRefForUser:(NSString *)userid;
-(void)setupMyPresence;
-(void)onlineStatusForUser:(NSString *)userid withCallback:(void (^)(BOOL status))callback;
-(void)lastOnlineDateForUser:(NSString *)userid withCallback:(void (^)(NSDate *lastOnlineDate))callback;
-(void)goOffline;

@end
