//
//  ChatContactsSynchronizer.h
//  chat21
//
//  Created by Andrea Sponziello on 09/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatSynchDelegate.h"

@import Firebase;
@class ChatUser;

@interface ChatContactsSynchronizer : NSObject

@property (strong, nonatomic) ChatUser * _Nullable loggeduser;
@property (nonatomic, strong) FIRDatabaseReference * _Nullable rootRef;
@property (strong, nonatomic) NSString * _Nullable tenant;
@property (strong, nonatomic) FIRDatabaseReference * _Nullable contactsRef;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_changed;
@property (assign, nonatomic) FIRDatabaseHandle contact_ref_handle_removed;
@property (strong, nonatomic) NSTimer * _Nullable synchTimer;
@property (assign, nonatomic) BOOL synchronizing;
@property (strong, nonnull) NSMutableArray<id<ChatSynchDelegate>> *synchSubscribers;

-(id _Nonnull )initWithTenant:(NSString *_Nonnull)tenant user:(ChatUser *_Nonnull)user;
-(void)startSynchro;
//-(void)stopSynchro;
//+(void)insertOrUpdateContactOnDB:(ChatUser *)user;
+(ChatUser *_Nullable)contactFromDictionaryFactory:(NSDictionary *_Nonnull)snapshot;
-(void)dispose;
-(void)addSynchSubscriber:(id<ChatSynchDelegate>_Nonnull)subscriber;
-(void)removeSynchSubscriber:(id<ChatSynchDelegate>_Nonnull)subscriber;
+(ChatUser *_Nonnull)contactFromSnapshotFactory:(FIRDataSnapshot *_Nonnull)snapshot;

@end
