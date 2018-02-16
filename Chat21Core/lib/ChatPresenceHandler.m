//
//  ChatPresenceHandler.m
//  Chat21
//
//  Created by Andrea Sponziello on 02/01/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatPresenceHandler.h"
#import "ChatUtil.h"
#import "ChatUser.h"
#import "ChatManager.h"

@import Firebase;

@implementation ChatPresenceHandler

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user {
    if (self = [super init]) {
//        self.firebaseRef = firebaseRef;
        self.rootRef = [[FIRDatabase database] reference];
        self.tenant = tenant;
        self.loggeduser = user;
    }
    return self;
}

+(FIRDatabaseReference *)lastOnlineRefForUser:(NSString *)userid {
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *lastOnlineRefURL = [[NSString alloc] initWithFormat:@"apps/%@/presence/%@/lastOnline",tenant, userid];
    FIRDatabaseReference *lastOnlineRef = [[[FIRDatabase database] reference] child:lastOnlineRefURL];
    return lastOnlineRef;
}

+(FIRDatabaseReference *)onlineRefForUser:(NSString *)userid {
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *myConnectionsRefURL = [[NSString alloc] initWithFormat:@"apps/%@/presence/%@/connections",tenant, userid];
    FIRDatabaseReference *connectionsRef = [[[FIRDatabase database] reference] child:myConnectionsRefURL];
    return connectionsRef;
}

-(void)setupMyPresence {
    // since I can connect from multiple devices, we store each connection instance separately
    // any time that connectionsRef's value is null (i.e. has no children) I am offline
    NSString *userid = self.loggeduser.userId;
    FIRDatabaseReference *myConnectionsRef = [ChatPresenceHandler onlineRefForUser:userid];
    FIRDatabaseReference *lastOnlineRef = [ChatPresenceHandler lastOnlineRefForUser:userid];
    
//    NSString *connectedRefURL = [[NSString alloc] initWithFormat:@"%@/.info/connected", self.firebaseRef];
    NSString *connectedRefURL = @"/.info/connected";
    FIRDatabaseReference *connectedRef = [[[FIRDatabase database] reference] child:connectedRefURL];
    if (self.connectionsRefHandle) {
        [connectedRef removeObserverWithHandle:self.connectionsRefHandle];
    }
    self.connectionsRefHandle = [connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        if([snapshot.value boolValue]) {
            // connection established (or I've reconnected after a loss of connection)
            
            // add this device to my connections list
            // this value could contain info about the device or a timestamp instead of just true
            if (!self.deviceConnectionRef) {
                if (self.deviceConnectionKey) {
                    self.deviceConnectionRef = [myConnectionsRef child:self.deviceConnectionKey];
                }
                else {
                    self.deviceConnectionRef = [myConnectionsRef childByAutoId];
                    self.deviceConnectionKey = self.deviceConnectionRef.key;
                }
                [self.deviceConnectionRef setValue:@YES];
                // when this device disconnects, remove it
                [self.deviceConnectionRef onDisconnectRemoveValue];
                // when I disconnect, update the last time I was seen online
                [lastOnlineRef onDisconnectSetValue:[FIRServerValue timestamp]];
            } else {
                NSLog(@"This is an error. self.deviceConnectionRef already set. Cannot be set again.");
            }
        }
    }];
}

-(void)onlineStatusForUser:(NSString *)userid withCallback:(void (^)(BOOL status))callback {
    // apps/{TENANT}/presence/{USERID}/connections
    FIRDatabaseReference *onlineRef = [ChatPresenceHandler onlineRefForUser:userid];
    [onlineRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        if(snapshot.exists) {
            NSLog(@"ONLINE: %@", snapshot);
            callback(YES);
//            self.online = YES;
//            [self onlineStatus];
        } else {
            callback(NO);
//            self.online = NO;
//            [self onlineStatus];
        }
    }];
}
-(void)lastOnlineDateForUser:(NSString *)userid withCallback:(void (^)(NSDate *lastOnlineDate))callback {
    // apps/{TENANT}/presence/{USERID}/lastOnline
    FIRDatabaseReference *lastOnlineRef = [ChatPresenceHandler lastOnlineRefForUser:userid];
    [lastOnlineRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        NSDate *lastOnlineDate = [self snapshotDate:snapshot];
        callback(lastOnlineDate);
    }];
}

-(NSDate *)snapshotDate:(FIRDataSnapshot *)snapshot {
    if (!snapshot.exists) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:[snapshot.value longValue]/1000];
}

-(void)goOffline {
    NSString *connectedRefURL = @"/.info/connected";
    FIRDatabaseReference *connectedRef = [[[FIRDatabase database] reference] child:connectedRefURL];
    [connectedRef removeObserverWithHandle:self.connectionsRefHandle];
    [self.deviceConnectionRef removeValue];
    self.connectionsRefHandle = 0;
    NSString *userid = self.loggeduser.userId;
    FIRDatabaseReference *lastOnlineRef = [ChatPresenceHandler lastOnlineRefForUser:userid];
    [lastOnlineRef setValue:[FIRServerValue timestamp]];
    self.deviceConnectionRef = nil;
}

@end
