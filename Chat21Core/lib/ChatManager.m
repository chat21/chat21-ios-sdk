//
//  ChatManager.m
//  Soleto
//
//  Created by Andrea Sponziello on 20/12/14.
//
//

#import "ChatManager.h"
#import "ChatConversationHandler.h"
#import "ChatConversationsHandler.h"
#import "ChatPresenceHandler.h"
#import "ChatGroupsHandler.h"
#import "ChatGroup.h"
#import "ChatConversation.h"
#import "ChatDB.h"
#import "ChatContactsDB.h"
#import "ChatGroupsDB.h"
#import "ChatPresenceHandler.h"
#import "ChatUtil.h"
#import "ChatConversationsVC.h"
#import "ChatUser.h"
#import "ChatContactsSynchronizer.h"
#import "ChatConnectionStatusHandler.h"
#import "ChatMessage.h"

@import Firebase;

static ChatManager *sharedInstance = nil;

@implementation ChatManager

-(id)init {
    if (self = [super init]) {
        self.handlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(void)configure {
    sharedInstance = [[super alloc] init];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
    sharedInstance.tenant = [dictionary objectForKey:@"app-id"];
    sharedInstance.groupsMode = [[dictionary objectForKey:@"groups-mode"] boolValue];
    sharedInstance.tabBarIndex = [[dictionary objectForKey:@"tabbar-index"] integerValue];
    sharedInstance.loggedUser = nil;
}

+(void)configureWithAppId:(NSString *)app_id {
    sharedInstance = [[super alloc] init];
    [FIRDatabase database].persistenceEnabled = NO;
    sharedInstance.tenant = app_id;
    sharedInstance.loggedUser = nil;
    sharedInstance.groupsMode = NO;
}

+(ChatManager *)getInstance {
    return sharedInstance;
}

-(void)addConversationHandler:(ChatConversationHandler *)handler {
    NSLog(@"Adding handler with key: %@", handler.conversationId);
    [self.handlers setObject:handler forKey:handler.conversationId];
}

-(void)removeConversationHandler:(NSString *)conversationId {
    NSLog(@"Removing conversation handler with key: %@", conversationId);
    [self.handlers removeObjectForKey:conversationId];
}

-(ChatConversationsHandler *)getConversationsHandler {
    if (!self.conversationsHandler) {
        NSLog(@"Conversations Handler not found. Creating & initializing a new one.");
        self.conversationsHandler = [self createConversationsHandler];
        NSLog(@"Restoring DB archived conversations...");
        [self.conversationsHandler restoreConversationsFromDB];
        NSLog(@"%lu archived conversations restored", (unsigned long)self.conversationsHandler.conversations.count);
        NSLog(@"Connecting handler...");
        [self.conversationsHandler connect];
    }
    return self.conversationsHandler;
}

-(ChatConversationHandler *)getConversationHandlerForRecipient:(ChatUser *)recipient {
    ChatConversationHandler *handler = [self.handlers objectForKey:recipient.userId];
    if (!handler) {
        NSLog(@"Conversation Handler not found. Creating & initializing a new one with recipient-id %@", recipient.userId);
        handler = [[ChatConversationHandler alloc] initWithRecipient:recipient.userId recipientFullName:recipient.fullname];
        [self addConversationHandler:handler];
        NSLog(@"Restoring DB archived conversations.");
        [handler restoreMessagesFromDB];
        NSLog(@"Archived messages count %lu", (unsigned long)handler.messages.count);
        NSLog(@"Connecting handler to firebase.");
        [handler connect];
    }
    return handler;
}

-(ChatConversationHandler *)getConversationHandlerForGroup:(ChatGroup *)group {
    ChatConversationHandler *handler = [self.handlers objectForKey:group.groupId];
    if (!handler) {
        NSLog(@"Conversation Handler not found. Creating & initializing a new one with group-id %@", group.groupId);
        // GROUP_MOD
        handler = [[ChatConversationHandler alloc] initWithGroupId:group.groupId groupName:group.name];
        [self addConversationHandler:handler];
        NSLog(@"Restoring DB archived conversations.");
        [handler restoreMessagesFromDB];
        NSLog(@"Archived messages count %lu", (unsigned long)handler.messages.count);
        NSLog(@"Connecting handler to firebase.");
        [handler connect];
    }
    return handler;
}

-(ChatConversationsHandler *)createConversationsHandler {
    ChatConversationsHandler *handler = [[ChatConversationsHandler alloc] initWithTenant:self.tenant user:self.loggedUser];
    NSLog(@"Setting new handler %@ to Conversations Manager.", handler);
    self.conversationsHandler = handler;
    return handler;
}

-(ChatPresenceHandler *)createPresenceHandler {
    ChatPresenceHandler *handler = [[ChatPresenceHandler alloc] initWithTenant:self.tenant user:self.loggedUser];
    NSLog(@"Setting new handler %@ to Conversations Manager.", handler);
    self.presenceHandler = handler;
    return handler;
}

-(void)initConnectionStatusHandler {
    ChatConnectionStatusHandler *handler = self.connectionStatusHandler;
    if (!handler) {
        NSLog(@"ConnectionStatusHandler not found. Creating & initializing a new one.");
        handler = [self createConnectionStatusHandler];
        self.connectionStatusHandler = handler;
        NSLog(@"Connecting connectionStatusHandler to firebase.");
        [self.connectionStatusHandler connect];
    }
}

-(ChatConnectionStatusHandler *)createConnectionStatusHandler {
    ChatConnectionStatusHandler *handler = [[ChatConnectionStatusHandler alloc] init];
    NSLog(@"Setting new ConnectionStatusHandler %@.", handler);
    self.connectionStatusHandler = handler;
    return handler;
}

-(void)initPresenceHandler {
    ChatPresenceHandler *handler = self.presenceHandler;
    if (!handler) {
        NSLog(@"Presence Handler not found. Creating & initializing a new one.");
        handler = [self createPresenceHandler];
        self.presenceHandler = handler;
        NSLog(@"Connecting handler to firebase.");
        [self.presenceHandler setupMyPresence];
    }
}

-(ChatContactsSynchronizer *)createContactsSynchronizerForUser:(ChatUser *)user {
    ChatContactsSynchronizer *syncronizer = [[ChatContactsSynchronizer alloc] initWithTenant:self.tenant user:user];
    NSLog(@"Setting new ChatContactsSynchronizer %@", syncronizer);
    self.contactsSynchronizer = syncronizer;
    return syncronizer;
}

-(void)startWithUser:(ChatUser *)user {
    [self dispose];
    self.loggedUser = user;
    ChatDB *chatDB = [ChatDB getSharedInstance];
    [chatDB createDBWithName:user.userId];
    ChatContactsDB *contactsDB = [ChatContactsDB getSharedInstance];
    [contactsDB createDBWithName:user.userId];
    ChatGroupsDB *groupsDB = [ChatGroupsDB getSharedInstance];
    [groupsDB createDBWithName:user.userId];
    [self initConnectionStatusHandler];
    [self startAuthStatusListner];
}

-(void)initGroupsHandler {
    if (!self.groupsHandler) {
        ChatGroupsHandler *handler = self.groupsHandler;
        NSLog(@"Groups Handler not found. Creating & initializing a new one.");
        handler = [self createGroupsHandlerForUser:self.loggedUser];
        [handler restoreGroupsFromDB]; // not thread-safe, call this method before firebase synchronization start
        [handler connect]; // firebase synchronization starts
    }
}

-(void)initContactsSynchronizer {
    if (!self.contactsSynchronizer) {
        NSLog(@"Contacts Synchronizer not found. Creating & initializing a new one.");
        self.contactsSynchronizer = [self createContactsSynchronizerForUser:self.loggedUser];
        [self.contactsSynchronizer startSynchro];
    } else {
        [self.contactsSynchronizer startSynchro];
    }
}

-(void)startAuthStatusListner {
    if (!self.authStateDidChangeListenerHandle) {
        self.authStateDidChangeListenerHandle =
        [[FIRAuth auth]
         addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
             NSLog(@"Firebase stato autenticazione cambiato! Auth: %@ user: %@", auth.currentUser, user);
             if (user) {
                 NSLog(@"Signed in.");
                 [self initPresenceHandler];
                 [self initContactsSynchronizer];
                 if (self.groupsMode) {
                     [self initGroupsHandler];
                 }
             }
             else {
                 // practically never called because of dispose() method removes this handle (and dispose is called just
                 // during the logout action.
                 NSLog(@"Signed out.");
                 if (self.authStateDidChangeListenerHandle) {
                     [[FIRAuth auth] removeAuthStateDidChangeListener:self.authStateDidChangeListenerHandle];
                     self.authStateDidChangeListenerHandle = nil;
                 }
             }
         }];
    }
}

//-(void)testFirebase {
//
//    // TEST SCRITTURA FIREBASE + PERMESSI
//    FIRDatabaseReference *_ref1 = [[FIRDatabase database] reference];
//    [[_ref1 child:@"apps/mobichat/users/andrea_leo/messages/C"] setValue:@{@"testo": @"successo scrittura"} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
//        if (error) {
//            NSLog(@"Error saving testo: %@", error);
//        }
//        else {
//            NSLog(@"testo SAVED!");
//        }
//    }];
//
//    //    [[FIRAuth auth] createUserWithEmail:@"andrea.sponziello@frontiere21.it"
//    //                               password:@"123456"
//    //                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
//    //                                 NSLog(@"Utente creato: andrea.sponziello@gmail.com/pallino");
//    //                             }];
//    //
//    //    [[FIRAuth auth] signInWithEmail:@"andrea.sponziello@frontiere21.it"
//    //                           password:@"123456"
//    //                         completion:^(FIRUser *user, NSError *error) {
//    //                             NSLog(@"Autenticato: %@ - %@/emailverified: %d", error, user.email, user.emailVerified);
//    //                             if (!user.emailVerified) {
//    //                                 NSLog(@"Email non verificata. Invio email verifica...");
//    //                                 [user sendEmailVerificationWithCompletion:^(NSError * _Nullable error) {
//    //                                     NSLog(@"Email verifica inviata.");
//    //                                 }];
//    //                             }
//    //                             // TEST CONNECTION
//    //                             FIRDatabaseReference *_ref = [[FIRDatabase database] reference];
//    //                             //                             FIRUser *currentUser = [FIRAuth auth].currentUser;
//    //                             [[_ref child:@"yesmister3"] setValue:@"andrea" withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
//    //
//    //                                 NSLog(@"completato! %@", ref);
//    //
//    //                             }];
//    //
//    //                             [[_ref child:@"test"] setValue:@{@"username": @"Lampatu"}];
//    //                             [[_ref child:@"test2"] setValue:@{@"valore": @"Andrea"}];
//    //                             [[_ref child:@"NADAL"] setValue:@{@"Vince": @"Wimbledon"}];
//    //
//    //                             [[_ref child:@"test"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//    //                                 NSLog(@"snapshot: %@", snapshot);
//    //                             } withCancelBlock:^(NSError * _Nonnull error) {
//    //                                 NSLog(@"error: %@", error.localizedDescription);
//    //                             }];
//    //
//    //                             [[_ref child:@"test10"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//    //                                 NSLog(@"snapshot: %@", snapshot);
//    //                             } withCancelBlock:^(NSError * _Nonnull error) {
//    //                                 NSLog(@"error: %@", error.localizedDescription);
//    //                             }];
//    //
//    //                             [[_ref child:@"yesmister"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//    //                                 NSLog(@"snapshot: %@", snapshot);
//    //                             } withCancelBlock:^(NSError * _Nonnull error) {
//    //                                 NSLog(@"error: %@", error.localizedDescription);
//    //                             }];
//    //
//    //                         }];
//    //
//    //    [[FIRAuth auth]
//    //     addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
//    //         NSLog(@"Firebase autenticatooooo! auth: %@ user: %@", auth, user);
//    //     }];
//}

//-(void)setupConnectionStatus {
//    NSLog(@"Connection status.");
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    FIRDatabaseReference *connectedRef = [rootRef child:url];
//
//    // event
//    if (!self.connectedRefHandle) {
//        self.connectedRefHandle = [connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
//            NSLog(@"snapshot %@ - %d", snapshot, [snapshot.value boolValue]);
//            if([snapshot.value boolValue]) {
//                NSLog(@".connected.");
////                if (self.conversationsVC) {
////                    [self.conversationsVC setUIStatusConnected];
////                }
//            } else {
//                NSLog(@".not connected.");
////                if (self.conversationsVC) {
////                    [self.conversationsVC setUIStatusDisconnected];
////                }
//            }
//        }];
//    }
//}

//-(void)isStatusConnectedWithCompletionBlock:(void (^)(BOOL connected, NSError* error))callback {
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    FIRDatabaseReference *connectedRef = [rootRef child:url];
//
//    // once
//    [connectedRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        // Get user value
//        NSLog(@"SNAPSHOT ONCE %@ - %d", snapshot, [snapshot.value boolValue]);
//        if([snapshot.value boolValue]) {
//            NSLog(@"..connected once..");
//            callback(YES, nil);
//        }
//        else {
//            NSLog(@"..not connected once..");
//            callback(NO, nil);
//        }
//    } withCancelBlock:^(NSError * _Nonnull error) {
//        NSLog(@"%@", error.localizedDescription);
//        callback(NO, error);
//    }];
//}

// IL METODO DISPOSE NON ESEGUE IL LOGOUT PERCHè PUO' ESSERE RICHIAMATO ANCHE PER DISPORRE UNA CHAT
// CON UTENTE CONNESSO, COME NEL CASO DI CAMBIO UTENTE.
-(void)dispose {
    NSLog(@"ChatManager.dispose()");
    [self removeInstanceId];
    [self.conversationsHandler dispose];
    self.conversationsHandler = nil;
    if (self.handlers) {
        for (NSString *conv_id in self.handlers) {
            ChatConversationHandler *handler = [self.handlers objectForKey:conv_id];
            [handler dispose];
        }
        [self.handlers removeAllObjects];
    }
    if (self.authStateDidChangeListenerHandle) {
        NSLog(@"disposing self.authStateDidChangeListenerHandle...");
        [[FIRAuth auth] removeAuthStateDidChangeListener:self.authStateDidChangeListenerHandle];
        self.authStateDidChangeListenerHandle = nil;
    }
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *connectedRef = [[[FIRDatabase database] reference] child:url];
//    if (self.connectedRefHandle) {
//        [connectedRef removeObserverWithHandle:self.connectedRefHandle];
//    }
    if (self.presenceHandler) {
        [self.presenceHandler goOffline];
        self.presenceHandler = nil;
    }
    if (self.connectionStatusHandler) {
        [self.connectionStatusHandler dispose];
        self.connectionStatusHandler = nil;
    }
    if (self.groupsHandler) {
        [self.groupsHandler dispose];
        self.groupsHandler = nil;
    }
    if (self.contactsSynchronizer) {
        [self.contactsSynchronizer dispose];
        self.contactsSynchronizer = nil;
    }
    self.loggedUser = nil;
}

// === GROUPS ===

-(NSString *)newGroupId {
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    NSString *groups_path = [ChatUtil groupsPath];
    FIRDatabaseReference *group_ref = [[rootRef child:groups_path] childByAutoId];
    return group_ref.key;
}

-(void)createFirebaseGroup:(ChatGroup*)group withCompletionBlock:(void (^)(NSString *groupId, NSError *))completionBlock {
    // create firebase reference
    
    NSLog(@"Creating firebase group with ID: %@", group.groupId);
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    NSString *groups_path = [ChatUtil mainGroupsPath];
    FIRDatabaseReference *group_ref = [[rootRef child:groups_path] child:group.groupId];
    NSLog(@"groupRef %@", group_ref);
    NSLog(@"group.groupId %@", group.groupId);
    NSLog(@"group.owner %@", group.owner);
    NSLog(@"group.date %@", group.createdOn);
    //    NSLog(@"group.iconID %@", group.iconID);
    NSLog(@"members >");
    for (NSString *user in group.members) {
        NSLog(@"sanitized member: %@", user);
    }
    
    NSDictionary *group_dict = [group asDictionary];
    
    // save group to firebase
    NSLog(@"Saving group to Firebase...");
    [group_ref setValue:group_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"setValue callback. %@", group_dict);
        if (error) {
            NSLog(@"Command: \"Create Group %@ on Firebase\" failed with error: %@", group.name, error);
            completionBlock(nil, error);
        } else {
            NSLog(@"Command: \"Create Group %@ on Firebase\" was successfull.", group.name);
            completionBlock(group.groupId, nil);
        }
    }];
}

-(ChatGroupsHandler *)createGroupsHandlerForUser:(ChatUser *)user {
    //    ChatGroupsHandler *handler = [[ChatGroupsHandler alloc] initWithFirebaseRef:self.firebaseRef tenant:self.tenant user:user];
    ChatGroupsHandler *handler = [[ChatGroupsHandler alloc] initWithTenant:self.tenant user:user];
    NSLog(@"Setting new handler %@ to Groups Manager.", handler);
    self.groupsHandler = handler;
    return handler;
}

+(ChatGroup *)groupFromSnapshotFactory:(FIRDataSnapshot *)snapshot {
    NSString *owner = snapshot.value[GROUP_OWNER];
    NSMutableDictionary *members = snapshot.value[GROUP_MEMBERS];
    NSString *name = snapshot.value[GROUP_NAME];
    NSNumber *createdOn_timestamp = snapshot.value[GROUP_CREATEDON];
    
    ChatGroup *group = [[ChatGroup alloc] init];
    group.key = snapshot.key;
    //    group.ref = snapshot.ref;
    group.owner = owner;
    group.name = name;
    group.members = members; //[ChatUtil groupMembersAsArray:members];
    group.groupId = snapshot.key;
    group.createdOn = [NSDate dateWithTimeIntervalSince1970:createdOn_timestamp.doubleValue/1000]; //[NSDate dateWithTimeIntervalSince1970:createdOn_timestamp.longValue];
    
    return group;
}

-(void)createContactFor:(ChatUser *)user withCompletionBlock:(void (^)(NSError *))completionBlock {
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    
    FIRDatabaseReference *contactsRef;
    @try {
        contactsRef = [[rootRef child: [ChatUtil contactsPath]] child:user.userId];
    }
    @catch(NSException *exception) {
        NSLog(@"Contact not created. Error: %@", exception);
        return;
    }
    
    NSDictionary *contact_dict = [user asDictionary];
    NSInteger now = [[NSDate alloc] init].timeIntervalSince1970 * 1000;
    [contact_dict setValue:@(now) forKey:@"timestamp"];
    NSLog(@"Saving contact to Firebase...");
    [contactsRef updateChildValues:contact_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"contact setValue callback. %@", contact_dict);
        if (error) {
            NSLog(@"Command: \"Create Contact %@/%@ on Firebase\" failed with error: %@",user.userId, user.fullname, error);
            completionBlock(error);
        } else {
            NSLog(@"Command: \"Create Contact %@/%@ on Firebase\" was successfull.",user.userId, user.fullname);
            completionBlock(nil);
        }
    }];
}

-(void)createGroup:(ChatGroup *)group withCompletionBlock:(void (^)(ChatGroup *group, NSError* error))callback {
    //    SHPUser *me = self.context.loggedUser;
    NSString *me = self.loggedUser.userId;
    //    NSString *sanitized_username_for_firebase = [userId stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//    ChatGroup *group = [[ChatGroup alloc] init];
//    group.groupId = [self newGroupId];
//    group.name = name;
//    group.user = me; //me.username; // for DB partioning
//    group.members = [ChatGroup membersArray2Dictionary:membersIDs];
//    group.owner = me; //sanitized_username_for_firebase;
//    group.createdOn = [[NSDate alloc] init];
    
    //    ChatManager *chat = [ChatManager getSharedInstance];
    [self createFirebaseGroup:group withCompletionBlock:^(NSString *_groupId, NSError *error) {
        if (error) {
            // create new conversation for this group on local DB
            // a local DB conversation entry is created to manage, locally, the group creation workflow.
            // ex. success/failure on creation - add/removing members - change group title etc.
            NSString *group_conv_id = _groupId; //[ChatUtil conversationIdForGroup:_groupId];
//            NSLog(@"group_conv_id created for me (%@): %@",me, group_conv_id);
            NSString *conversation_message_for_admin = [[NSString alloc] initWithFormat:@"Errore nella crazione del gruppo \"%@\". Tocca per riprovare.", group.name];
            ChatConversation *groupConversation = [[ChatConversation alloc] init];
            groupConversation.conversationId = group_conv_id;
            groupConversation.user = me; //.username;
            groupConversation.key = group_conv_id;
            groupConversation.recipient = nil;
            groupConversation.recipientFullname = group.name; // compare nella cella al posto di "conversWith"
            groupConversation.channel_type = MSG_CHANNEL_TYPE_GROUP;
            groupConversation.last_message_text = conversation_message_for_admin;
            //    groupConversation.sender = self.me;
            NSDate *now = [[NSDate alloc] init];
            groupConversation.date = now;
            groupConversation.status = CONV_STATUS_FAILED;
            BOOL result = [[ChatDB getSharedInstance] insertOrUpdateConversation:groupConversation];
            NSLog(@">>>>> -Group Failed- Conversation insertOrUpdate operation is %d", result);
            [self.conversationsHandler restoreConversationsFromDB];
            callback(group, error);
        } else {
            // we have the group-id
            NSLog(@"Group created with ID: %@", _groupId);
            NSLog(@"Group created with ID: %@", group.groupId);
            
            [self.groupsHandler insertOrUpdateGroup:group completion:^{
                NSLog(@"DB.Group id: %@", group.groupId);
                ChatGroup *group_on_db = [[ChatManager getInstance] groupById:group.groupId];
                NSLog(@"GROUP. name: %@, id: %@", group_on_db.name, group_on_db.groupId);
                callback(group, nil);
                // create new conversation for this group on local DB
                // a local DB conversation entry is created to manage, locally, the group creation workflow.
                // ex. success/failure on creation - add/removing members - change group title etc.
//                NSString *group_conv_id = _groupId; //[ChatUtil conversationIdForGroup:_groupId];
//                NSLog(@"group_conv_id created (%@): %@",me, group_conv_id);
//                NSString *conversation_message_for_admin = [self groupCreatedMessageForMemberInGroup:group];
//                NSString *conversation_message_for_member = [self groupInvitedMessageForMemberInGroup:group];
//                ChatConversation *groupConversation = [[ChatConversation alloc] init];
//                groupConversation.conversationId = group_conv_id;
//                groupConversation.user = me; //.username;
//                groupConversation.key = group_conv_id;
//                groupConversation.recipient = _groupId;
//                groupConversation.recipientFullname = group.name; // compare nella cella al posto di "conversWith"
////                groupConversation.last_message_text = conversation_message_for_admin;
//                NSDate *now = [[NSDate alloc] init];
//                groupConversation.date = now;
//                groupConversation.status = CONV_STATUS_JUST_CREATED;
//                [[ChatDB getSharedInstance] insertOrUpdateConversation:groupConversation];
//                [self.conversationsHandler restoreConversationsFromDB];
                
//                NSLog(@"creating a remote Firebase conversation for every member...");
//                // POSSIBLY UPDATE AS A FAN OUT ON CONVERSATIONS
//                NSLog(@"group created by (owner): %@", me); //sanitized_username_for_firebase);
//                for (NSString *member_id in membersIDs) {
//                    NSLog(@"Group Conversation for %@, admin: %@", member_id, me); //sanitized_username_for_firebase);
//                    if (![member_id isEqualToString:me]) {
//                        ChatConversation *memberInvitedConversation = [self buildInviteConversationForMember:member_id message:conversation_message_for_member inGRoup:group createdOn:now];
//                        [self createOrUpdateConversation:memberInvitedConversation];
//                        NSLog(@"Added conversation on Firebase for member: %@ with message: %@", member_id, memberInvitedConversation.last_message_text);
//                    }
//                }
                
//                // ADDING CONVERSATION FOR ADMIN MEMBER
//                NSString *conversation_message_for_admin = [self groupCreatedMessageForMemberInGroup:group];
//                ChatConversation *adminInvitedConversation = [self buildInviteConversationForMember:me message:conversation_message_for_admin inGRoup:group createdOn:now];
//                [self createOrUpdateConversation:adminInvitedConversation];
//                NSLog(@"added group conversation on Firebase for admin: %@", me);
            }];
        }
    }];
}

//-(void)createGroup:(NSString *)groupId name:(NSString *)name owner:(NSString *)owner members:(NSMutableArray *)membersIDs {
//    //    SHPUser *me = self.context.loggedUser;
//    NSString *me = self.loggedUser.userId;
//    //    NSString *sanitized_username_for_firebase = [userId stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//    ChatGroup *group = [[ChatGroup alloc] init];
//    group.groupId = groupId;
//    group.name = name;
//    group.user = me; //me.username; // for DB partioning
//    group.members = [ChatGroup membersArray2Dictionary:membersIDs];
//    group.owner = me; //sanitized_username_for_firebase;
//    group.createdOn = [[NSDate alloc] init];
//
//    //    ChatManager *chat = [ChatManager getSharedInstance];
//    [self createFirebaseGroup:group withCompletionBlock:^(NSString *_groupId, NSError *error) {
//        if (error) {
//            // create new conversation for this group on local DB
//            // a local DB conversation entry is created to manage, locally, the group creation workflow.
//            // ex. success/failure on creation - add/removing members - change group title etc.
//            NSString *group_conv_id = _groupId; //[ChatUtil conversationIdForGroup:_groupId];
//            NSLog(@"group_conv_id created for me (%@): %@",me, group_conv_id);
//            NSString *conversation_message_for_admin = [[NSString alloc] initWithFormat:@"Errore nella crazione del gruppo \"%@\". Tocca per riprovare.", group.name];
//            ChatConversation *groupConversation = [[ChatConversation alloc] init];
//            groupConversation.conversationId = group_conv_id;
//            groupConversation.user = me; //.username;
//            groupConversation.key = group_conv_id;
//            groupConversation.groupId = nil;
//            groupConversation.groupName = group.name; // compare nella cella al posto di "conversWith"
//            NSLog(@"GROUP NAME: %@", groupConversation.groupName);
//            groupConversation.last_message_text = conversation_message_for_admin;
//            //    groupConversation.sender = self.me;
//            NSDate *now = [[NSDate alloc] init];
//            groupConversation.date = now;
//            groupConversation.status = CONV_STATUS_FAILED;
//            BOOL result = [[ChatDB getSharedInstance] insertOrUpdateConversation:groupConversation];
//            NSLog(@">>>>> -Group Failed- Conversation insertOrUpdate operation is %d", result);
//            [self.conversationsHandler restoreConversationsFromDB];
//        } else {
//            // we have the group-id
//            NSLog(@"Group created with ID: %@", _groupId);
//            NSLog(@"Group created with ID: %@", group.groupId);
//
//            [self.groupsHandler insertOrUpdateGroup:group completion:^{
//                NSLog(@"DB.Group created locally.");
//                NSLog(@"DB.Group id: %@", group.groupId);
//                NSLog(@"DB.Group name: %@", group.name);
//                NSLog(@"DB.Group members: %@", [ChatUtil groupMembersAsStringForUI:group.members]);
//
//                NSLog(@"VERIFYING IF GROUP %@ IS IN DB...", groupId);
//                ChatGroup *group_on_db = [[ChatManager getInstance] groupById:groupId];
//                NSLog(@"GROUP. name: %@, id: %@", group_on_db.name, group_on_db.groupId);
//
//                // create new conversation for this group on local DB
//                // a local DB conversation entry is created to manage, locally, the group creation workflow.
//                // ex. success/failure on creation - add/removing members - change group title etc.
//                NSString *group_conv_id = _groupId; //[ChatUtil conversationIdForGroup:_groupId];
//                NSLog(@"group_conv_id created (%@): %@",me, group_conv_id);
//                NSString *conversation_message_for_admin = [self groupCreatedMessageForMemberInGroup:group];
//                NSString *conversation_message_for_member = [self groupInvitedMessageForMemberInGroup:group];
//                ChatConversation *groupConversation = [[ChatConversation alloc] init];
//                groupConversation.conversationId = group_conv_id;
//                groupConversation.user = me; //.username;
//                groupConversation.key = group_conv_id;
//                groupConversation.groupId = _groupId;
//                groupConversation.groupName = group.name; // compare nella cella al posto di "conversWith"
//                groupConversation.last_message_text = conversation_message_for_admin;
//                NSDate *now = [[NSDate alloc] init];
//                groupConversation.date = now;
//                groupConversation.status = CONV_STATUS_JUST_CREATED;
//                BOOL result = [[ChatDB getSharedInstance] insertOrUpdateConversation:groupConversation];
//                NSLog(@">>>>> Conversation insertOrUpdate is %d", result);
//                [self.conversationsHandler restoreConversationsFromDB];
//
//                NSLog(@"creating a remote Firebase conversation for every member...");
//                // POSSIBLY UPDATE AS A FAN OUT ON CONVERSATIONS
//                NSLog(@"group created by (owner): %@", me); //sanitized_username_for_firebase);
//                for (NSString *member_id in membersIDs) {
//                    NSLog(@"Group Conversation for %@, admin: %@", member_id, me); //sanitized_username_for_firebase);
//                    if (![member_id isEqualToString:me]) {
//                        ChatConversation *memberInvitedConversation = [self buildInviteConversationForMember:member_id message:conversation_message_for_member inGRoup:group createdOn:now];
//                        [self createOrUpdateConversation:memberInvitedConversation];
//                        NSLog(@"Added conversation on Firebase for member: %@ with message: %@", member_id, memberInvitedConversation.last_message_text);
//                    }
//                }
//                // ADDING CONVERSATION FOR ADMIN MEMBER
//                ChatConversation *adminInvitedConversation = [self buildInviteConversationForMember:me message:conversation_message_for_admin inGRoup:group createdOn:now];
//                [self createOrUpdateConversation:adminInvitedConversation];
//                NSLog(@"added group conversation on Firebase for admin: %@", me);
//                // sending notifications
//                //            [self sendNotificationsToGroup:group];
//            }];
//        }
//    }];
//}

//-(NSString *)groupInvitedMessageForMemberInGroup:(ChatGroup *)group {
//    return [NSString stringWithFormat:NSLocalizedString(@"You was added to group", nil), [group.name capitalizedString]];
//}

-(NSString *)groupCreatedMessageForMemberInGroup:(ChatGroup *)group {
    return [NSString stringWithFormat:NSLocalizedString(@"You created the group", nil), [group.name capitalizedString]];
}

-(void)addMember:(NSString *)member_id toGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock {
    NSLog(@"Adding member %@ to group %@...", member_id, group.groupId);
    
//    NSDate *now = [[NSDate alloc] init];
//    NSString *message = [self groupInvitedMessageForMemberInGroup:group];
//    ChatConversation *conversation = [self buildInviteConversationForMember:member_id message:message inGRoup:group createdOn:now];
//    NSDictionary *conversation_dict = [conversation asDictionary];
//    NSLog(@"convid %@", conversation.conversationId);
//    NSString *conversation_path = [ChatUtil conversationPathForUser:member_id conversationId:conversation.conversationId];
//    NSLog(@"conversation path %@", conversation_path);
//
//    NSString *member_relative_path = [group memberPath:member_id];
//    NSLog(@"member relative path %@", member_relative_path);
//    NSString *groups_path = [ChatUtil mainGroupsPath];
//    NSString *member_path = [groups_path stringByAppendingFormat:@"/%@/%@", group.groupId, member_relative_path];
//    NSLog(@"member path %@", member_path);
//
//    NSMutableDictionary *fanOut = [[NSMutableDictionary alloc] init];
//    fanOut[conversation_path] = conversation_dict;
//    fanOut[member_path] = @(true);
//    NSLog(@"fanOut dict: %@", fanOut);
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    [rootRef updateChildValues:fanOut withCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
//        //        [self sendInvitedNotificationToMember:member_id ofGroup:group];
//        completionBlock(error);
//    }];
}

-(void)removeMember:(NSString *)member_id fromGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock {
    NSLog(@"Removing member %@ from group %@...", member_id, group.groupId);
    NSString *member_relative_path = [group memberPath:member_id];
    NSLog(@"member relative path %@", member_relative_path);
    NSString *groups_path = [ChatUtil mainGroupsPath];
    NSString *member_path = [groups_path stringByAppendingFormat:@"/%@/%@", group.groupId, member_relative_path];
    NSLog(@"member path %@", member_path);
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    
    //    FIRDatabaseReference *member_ref = [group memberReference:user_id];
    FIRDatabaseReference *member_ref = [rootRef child:member_path];
    NSLog(@"member_ref %@", member_ref);
    
    [member_ref removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
        completionBlock(error);
    }];
    //    return member_ref;
}

-(void)updateGroupName:(NSString *)name forGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock {
    NSLog(@"Updating group name %@ for group %@/%@...", name, group.name, group.groupId);
    
    FIRDatabaseReference *group_ref = group.reference;
    NSLog(@"group_ref %@", group_ref);
    
    [group_ref updateChildValues:@{GROUP_NAME:name} withCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
        completionBlock(error);
    }];
}

-(NSDictionary *)allGroups {
    return self.groupsHandler.groups;
}

// === CONVERSATIONS ===

//-(void)createOrUpdateConversation:(ChatConversation *)conversation {
//    NSMutableDictionary *conversation_dict = [conversation asDictionary];
//    [conversation.ref updateChildValues:conversation_dict];
//}

-(void)removeConversation:(ChatConversation *)conversation {
    
    NSString *conversationId = conversation.conversationId;
    NSLog(@"Removing conversation from local DB...");
    [self removeConversationFromDB:conversationId];
    
    NSLog(@"Removing conversation from with ref %@...", conversation.ref);
    FIRDatabaseReference *conversationRef = conversation.ref;
    [conversationRef removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
        NSLog(@"Conversation %@ removed from firebase.", firebaseRef);
    }];
}

-(void)removeConversationFromDB:(NSString *)conversationId {
    ChatDB *db = [ChatDB getSharedInstance];
    [db removeConversation:conversationId];
    [db removeAllMessagesForConversation:conversationId];
}

-(void)updateConversationIsNew:(FIRDatabaseReference *)conversationRef is_new:(int)is_new {
    NSLog(@"Updating conversation ref %@ is_new? %d", conversationRef, is_new);
    NSDictionary *conversation_dict = @{
                                        CONV_IS_NEW_KEY: [NSNumber numberWithBool:is_new]
                                        };
    [conversationRef updateChildValues:conversation_dict];
}

-(ChatGroup *)groupById:(NSString *)groupId {
    ChatGroup *group = [self.groupsHandler groupById:groupId];
    return group;
}

-(void)removeInstanceId {
    ChatUser *user = self.loggedUser;
    if (!user) {
        NSLog(@"ERROR: CAN'T REMOVE THE INSTANCE IF LOGGED USER IS NULL. Hey...did you signed out before removing InstanceID?");
        return;
    }
    NSString *user_path = [ChatUtil userPath:user.userId];
    NSLog(@"Removing instanceId (FCMToken) on path: %@", user_path);
    [[[[[FIRDatabase database] reference] child:user_path] child:@"instanceId"] removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (error) {
            NSLog(@"Error removing instanceId (FCMToken) on user_path %@: %@", error, user_path);
        }
        else {
            NSLog(@"instanceId (FCMToken) removed");
        }
    }];
}

-(void)loadGroup:(NSString *)group_id completion:(void (^)(ChatGroup* group, BOOL error))callback {
    // if firebase.persistence = YES use this method to overcame this problem: https://github.com/firebase/firebase-ios-sdk/issues/321
    //    [self loadGroupMultipleAttempts:group_id try:1 completion:callback];
    
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    NSString *groups_path = [ChatUtil groupsPath];
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@", groups_path, group_id];
    NSLog(@"Load Group on path: %@", path);
    FIRDatabaseReference *groupRef = [rootRef child:path];
    [groupRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"NEW GROUP SNAPSHOT: %@", snapshot);
        if (!snapshot || ![snapshot exists]) {
            NSLog(@"Errore gruppo: !snapshot || !snapshot.exists");
            callback(nil, YES);
        }
        else {
            ChatGroup *group = [ChatManager groupFromSnapshotFactory:snapshot];
            ChatGroupsHandler *gh = [ChatManager getInstance].groupsHandler;
            [gh insertOrUpdateGroup:group completion:^{
                callback(group, NO);
            }];
        }
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(void)getContactLocalDB:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback {
    ChatContactsDB *db = [ChatContactsDB getSharedInstance];
    [db getContactByIdSyncronized:userid completion:^(ChatUser *user) {
        callback(user);
    }];
}

//-(void)getContact:(NSString *)userid withCompletion(void (^)(ChatUser* user))callback {
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    NSString *contact_path = [ChatUtil contactPathOfUser:self.loggedUser.userId];
//    NSLog(@"Contact path of (%@): %@", self.loggedUser.userId, contact_path);
//    FIRDatabaseReference *contactRef = [rootRef child:contact_path];
//    [contactRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
//        NSLog(@"NEW CONTACT SNAPSHOT: %@", snapshot);
//        if (!snapshot || ![snapshot exists]) {
//            NSLog(@"Errore contact snapshot: !snapshot || !snapshot.exists");
//            callback(nil);
//        }
//        else {
//            ChatUser *user = [ChatManager :snapshot];
//            ChatGroupsHandler *gh = [ChatManager getInstance].groupsHandler;
//            [gh insertOrUpdateGroup:group completion:^{
//                callback(group, NO);
//            }];
//        }
//    } withCancelBlock:^(NSError *error) {
//        NSLog(@"%@", error.description);
//    }];
//}

@end

