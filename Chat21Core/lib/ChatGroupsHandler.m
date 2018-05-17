//
//  ChatGroupsHandler.m
//  Smart21
//
//  Created by Andrea Sponziello on 02/05/15.
//
//

#import "ChatGroupsHandler.h"
//#import "SHPFirebaseTokenDC.h"
//#import "SHPUser.h"
#import "ChatUtil.h"
#import <Firebase/Firebase.h>
#import "ChatGroup.h"
#import "ChatGroupsDB.h"
#import "ChatManager.h"
#import "ChatUser.h"
#import "ChatGroupsSubscriber.h"

@implementation ChatGroupsHandler

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user {
    if (self = [super init]) {
//        self.firebaseRef = firebaseRef;
        self.rootRef = [[FIRDatabase database] reference];
        self.tenant = tenant;
        self.loggeduser = user;
        self.me = user.userId;
        self.groups = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)addSubscriber:(id<ChatGroupsSubscriber>)subscriber {
    if (!self.subscribers) {
        self.subscribers = [[NSMutableArray alloc] init];
    }
    [self.subscribers addObject:subscriber];
}

-(void)removeSubscriber:(id<ChatGroupsSubscriber>)subscriber {
    if (!self.subscribers) {
        return;
    }
    [self.subscribers removeObject:subscriber];
}

-(void)notifySubscribers:(ChatGroup *)group {
    NSLog(@"ChatConversationHandler: This group was added or changed: %@. Notifying to subscribers...", group.name);
    for (id<ChatGroupsSubscriber> subscriber in self.subscribers) {
        [subscriber groupAddedOrChanged:group];
    }
}

//-(id)initWithFirebaseRef:(NSString *)firebaseRef tenant:(NSString *)tenant user:(SHPUser *)user {
//    if (self = [super init]) {
//        NSLog(@"OOO");
//        self.firebaseRef = firebaseRef;
//        self.tenant = tenant;
//        self.loggeduser = user;
//        self.me = user.username;
////        self.groups = [[NSMutableArray alloc] init];
//    }
//    return self;
//}

-(void)dispose{
//    [self.groupsRef removeObserverWithHandle:self.groups_ref_handle_added];
//    [self.groupsRef removeObserverWithHandle:self.groups_ref_handle_changed];
//    [self.groupsRef removeObserverWithHandle:self.groups_ref_handle_removed];
    [self.groupsRef removeAllObservers];
}

-(void)connect {
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    NSString *groups_path = [ChatUtil groupsPath];
    self.groupsRef = [rootRef child:groups_path];
    
    self.groups_ref_handle_added = [self.groupsRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"NEW GROUP SNAPSHOT: %@", snapshot);
        ChatGroup *group = [ChatManager groupFromSnapshotFactory:snapshot];
        [self insertOrUpdateGroup:group completion:^{
            // nothing
        }];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    self.groups_ref_handle_changed =
    [self.groupsRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"UPDATED GROUP SNAPSHOT: %@", snapshot);
        ChatGroup *group = [ChatManager groupFromSnapshotFactory:snapshot];
        [self insertOrUpdateGroup:group completion:^{
            // nothing
        }];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(void)insertInMemory:(ChatGroup *)group {
    if (group && group.groupId) {
        [self.groups setObject:group forKey:group.groupId];
    }
    else {
        NSLog(@"ERROR: CAN'T INSERT A GROUP WITH NIL ID");
    }
}

//+(void)createGroupFromPushNotification:(ChatGroup *)group {
////    NSLog(@"Groups in memory before push:");
////    [self printAllGroupsInMemory];
////    [self insertInMemory:group];
////    NSLog(@"Groups in memory after push:");
////    [self printAllGroupsInMemory];
//    ChatGroupsDB *db = [ChatGroupsDB getSharedInstance];
//    // TEST
////    NSArray *groups_before = [db getAllGroupsForUser:[ChatManager getInstance].loggedUser.userId];
////    NSLog(@"GROUPS BEFORE PUSH");
////    for (ChatGroup *g in groups_before) {
////        NSLog(@"name: %@ [%@]", g.name, g.groupId);
////    }
//    
//    [db insertGroupOnlyIfNotExistsSyncronized:group completion:^{
//        // TODO print all groups from db before
//        NSLog(@"Group %@ [%@] created by push notification", group.name, group.groupId);
//        // TODO print all groups from db after
////        NSLog(@"GROUPS AFTER PUSH");
////        NSArray *groups_after = [db getAllGroupsForUser:[ChatManager getInstance].loggedUser.userId];
////        for (ChatGroup *g in groups_after) {
////            NSLog(@"name: %@ [%@]", g.name, g.groupId);
////        }
//    }];
//}


-(void)printAllGroupsInMemory {
    for (id k in self.groups) {
        ChatGroup *g = self.groups[k];
        NSLog(@"group id: %@, name: %@, members: %@", g.groupId, g.name, [ChatGroup membersDictionary2String:g.members]);
    }
}

-(ChatGroup *)groupById:(NSString *)groupId {
    return self.groups[groupId];
}

-(void)insertOrUpdateGroup:(ChatGroup *)group completion:(void(^)()) callback {
    NSLog(@"INSERTING OR UPDATING GROUP WITH NAME: %@", group.name);
    group.user = self.me;
    [self insertInMemory:group];
    [[ChatGroupsDB getSharedInstance] insertOrUpdateGroupSyncronized:group completion:^{
        [self notifySubscribers:group];
        callback();
    }];
}

-(void)restoreGroupsFromDB {
    NSArray *groups_array = [[ChatGroupsDB getSharedInstance] getAllGroupsForUser:self.me];
    if (!self.groups) {
        self.groups = [[NSMutableDictionary alloc] init];
    }
    for (ChatGroup *g in groups_array) {
        [self.groups setValue:g forKey:g.groupId];
    }
}

//-(void)updateGroup:(ChatGroup *)group1 withGroup:(ChatGroup *)group2 {
//    group1.createdOn = group2.createdOn;
//    group1.members = group2.members;
//    group1.key = group2.key;
//    group1.groupId = group2.groupId;
//    group1.user = group2.user;
//    group1.name = group2.name;
//    group1.owner = group2.owner;
////    group1.iconURL = group2.iconURL;
//}

@end
