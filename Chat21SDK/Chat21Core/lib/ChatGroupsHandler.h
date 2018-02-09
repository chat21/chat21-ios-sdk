//
//  ChatGroupsHandler.h
//  Smart21
//
//  Created by Andrea Sponziello on 02/05/15.
//
//

#import <Foundation/Foundation.h>
#import "ChatGroupsSubscriber.h"

@import Firebase;

@class FirebaseCustomAuthHelper;
@class Firebase;
@class ChatUser;
@class ChatGroup;

@interface ChatGroupsHandler : NSObject

@property (strong, nonatomic) ChatUser * _Nullable loggeduser;
@property (strong, nonatomic) NSString *me;
@property (strong, nonatomic) FirebaseCustomAuthHelper *authHelper;
@property (strong, nonatomic) NSMutableDictionary *groups;
//@property (strong, nonatomic) NSMutableDictionary *groupsDictionary; // easy search by group_id

//@property (strong, nonatomic) NSMutableArray *groups;
@property (strong, nonatomic) NSString *firebaseToken;
@property (strong, nonatomic) FIRDatabaseReference *groupsRef;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_changed;
@property (assign, nonatomic) FIRDatabaseHandle groups_ref_handle_removed;
//@property (strong, nonatomic) NSString *firebaseRef;
@property (nonatomic, strong) FIRDatabaseReference *rootRef;
@property (strong, nonatomic) NSString *tenant;
@property (strong, nonnull) NSMutableArray<id<ChatGroupsSubscriber>> *subscribers;

//-(id)initWithFirebaseRef:(NSString *)firebaseRef tenant:(NSString *)tenant user:(SHPUser *)user;
-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user;
-(void)restoreGroupsFromDB;
-(void)connect;
-(void)dispose;
-(ChatGroup *)groupById:(NSString *)groupId;
//-(void)insertOrUpdateGroup:(ChatGroup *)group;
-(void)insertOrUpdateGroup:(ChatGroup *)group completion:(void(^)()) callback;
-(void)insertInMemory:(ChatGroup *)group;
-(void)addSubscriber:(id<ChatGroupsSubscriber>)subscriber;
-(void)removeSubscriber:(id<ChatGroupsSubscriber>)subscriber;
@end
