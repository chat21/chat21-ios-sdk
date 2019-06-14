//
//  ChatManager.m
//  Chat21
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
#import "ChatLocal.h"
#import "ChatService.h"
#import "ChatDiskImageCache.h"

@import Firebase;

static ChatManager *sharedInstance = nil;

@implementation ChatManager

-(id)init {
    if (self = [super init]) {
        self.handlers = [[NSMutableDictionary alloc] init];
        self.imageCache = [[ChatDiskImageCache alloc] init];
    }
    return self;
}

//+(void)configure {
//    sharedInstance = [[super alloc] init];
//    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
//    // default values
//    sharedInstance.tenant = @"chat";
//    sharedInstance.baseURL = @"https://us-central1-chat-v2-dev.cloudfunctions.net";
//    sharedInstance.archiveConversationURI = @"/api/%@/conversations/%@";
//    sharedInstance.archiveAndCloseSupportConversationURI = @"/supportapi/%@/groups/%@";
//    sharedInstance.profileImageBaseURL = @"https://firebasestorage.googleapis.com/v0/b/%@/o";
//    sharedInstance.deleteProfilePhotoURI = @"";
//    sharedInstance.groupsMode = YES;
//    sharedInstance.tabBarIndex = 0;
//    if (dictionary) {
//        if ([dictionary objectForKey:@"tenant"]) {
//            sharedInstance.tenant = [dictionary objectForKey:@"tenant"];
//        }
//        if ([dictionary objectForKey:@"groups-mode"]) {
//            sharedInstance.groupsMode = [[dictionary objectForKey:@"groups-mode"] boolValue];
//        }
//        if ([dictionary objectForKey:@"conversations-tabbar-index"]) {
//            sharedInstance.tabBarIndex = [[dictionary objectForKey:@"conversations-tabbar-index"] integerValue];
//        }
//        if ([dictionary objectForKey:@"base-url"]) {
//            sharedInstance.baseURL = [dictionary objectForKey:@"base-url"];
//        }
//        if ([dictionary objectForKey:@"archive-conversation-uri"]) {
//            sharedInstance.archiveConversationURI = [dictionary objectForKey:@"archive-conversation-uri"];
//        }
//        if ([dictionary objectForKey:@"profile-image-base-url"]) {
//            sharedInstance.profileImageBaseURL = [dictionary objectForKey:@"profile-image-base-url"];
//        }
//        if ([dictionary objectForKey:@"archive-and-support-conversation-uri"]) {
//            sharedInstance.archiveAndCloseSupportConversationURI = [dictionary objectForKey:@"archive-and-support-conversation-uri"];
//        }
//        if ([dictionary objectForKey:@"delete-profile-photo-uri"]) {
//            sharedInstance.deleteProfilePhotoURI = [dictionary objectForKey:@"delete-profile-photo-uri"];
//        }
//    }
//    sharedInstance.loggedUser = nil;
//}
//
//+(void)configureWithAppId:(NSString *)app_id {
//    sharedInstance = [[super alloc] init];
//    [FIRDatabase database].persistenceEnabled = NO;
//    sharedInstance.tenant = app_id;
//    sharedInstance.loggedUser = nil;
//    sharedInstance.groupsMode = NO;
//}
//
//+(ChatManager *)getInstance {
//    return sharedInstance;
//}

+(void)configure {
//    ChatManager *sharedInstance = [ChatManager getInstance];
    [ChatManager configureServices];
    [ChatManager configureCustomInfo];

    ChatManager *inst = [ChatManager getInstance];
    NSLog(@"tenant %@", inst.tenant);
//    sharedInstance.loggedUser = nil;
}

+(void)configureServices {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Services" ofType:@"plist"]];
    // default values
    ChatManager *sharedInstance = [ChatManager getInstance];
    sharedInstance.baseURL = @"https://us-central1-chat-v2-dev.cloudfunctions.net";
    sharedInstance.archiveConversationURI = @"/api/%@/conversations/%@";
    sharedInstance.archiveAndCloseSupportConversationURI = @"/supportapi/%@/groups/%@";
    sharedInstance.deleteProfilePhotoURI = @"";
    if (dictionary) {
        if ([dictionary objectForKey:@"base-url"]) {
            sharedInstance.baseURL = [dictionary objectForKey:@"base-url"];
        }
        if ([dictionary objectForKey:@"archive-conversation-uri"]) {
            sharedInstance.archiveConversationURI = [dictionary objectForKey:@"archive-conversation-uri"];
        }
        if ([dictionary objectForKey:@"archive-and-support-conversation-uri"]) {
            sharedInstance.archiveAndCloseSupportConversationURI = [dictionary objectForKey:@"archive-and-support-conversation-uri"];
        }
        if ([dictionary objectForKey:@"delete-profile-photo-uri"]) {
            sharedInstance.deleteProfilePhotoURI = [dictionary objectForKey:@"delete-profile-photo-uri"];
        }
        if ([dictionary objectForKey:@"profile-image-base-url"]) {
            sharedInstance.profileImageBaseURL = [dictionary objectForKey:@"profile-image-base-url"];
        }
    }
}

+(void)configureCustomInfo {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
    // default values
    ChatManager *sharedInstance = [ChatManager getInstance];
    sharedInstance.tenant = @"chat";
    sharedInstance.groupsMode = YES;
    sharedInstance.tabBarIndex = 0;
    if (dictionary) {
        if ([dictionary objectForKey:@"tenant"]) {
            sharedInstance.tenant = [dictionary objectForKey:@"tenant"];
        }
        if ([dictionary objectForKey:@"groups-mode"]) {
            sharedInstance.groupsMode = [[dictionary objectForKey:@"groups-mode"] boolValue];
        }
        if ([dictionary objectForKey:@"conversations-tabbar-index"]) {
            sharedInstance.tabBarIndex = [[dictionary objectForKey:@"conversations-tabbar-index"] integerValue];
        }
    }
}

+(ChatManager *)getInstance {
    static ChatManager *sharedInstance = nil;
    static dispatch_once_t pred;

    if (sharedInstance) return sharedInstance;
    dispatch_once(&pred, ^{
        sharedInstance = [[ChatManager alloc] init];
    });
    return sharedInstance;
}




-(void)addConversationHandler:(ChatConversationHandler *)handler {
//    NSLog(@"Adding handler with key: %@", handler.conversationId);
    [self.handlers setObject:handler forKey:handler.conversationId];
}

-(void)removeConversationHandler:(NSString *)conversationId {
    NSLog(@"Removing conversation handler with key: %@", conversationId);
    [self.handlers removeObjectForKey:conversationId];
}

-(ChatConversationsHandler *)getAndStartConversationsHandler {
    if (!self.conversationsHandler) {
        self.conversationsHandler = [self createConversationsHandler];
        [self.conversationsHandler restoreConversationsFromDB];
        [self.conversationsHandler connect];
        // activate connections for every conversation with "new" messages
//        for (ChatConversation *conv in self.conversationsHandler.conversations) {
//            if (conv.is_new) {
//                [self startConversationHandler:conv];
//            }
//        }
    }
    return self.conversationsHandler;
}

//-(void)startConversationHandler:(ChatConversation *)conv {
//    if (conv.isDirect) {
//        NSString *recipientId = conv.conversWith;
//        NSString *recipientFullname = conv.conversWith_fullname;
//        ChatUser *recipient = [[ChatUser alloc] init:recipientId fullname:recipientFullname];
//        ChatConversationHandler *handler;
//        handler = [self getConversationHandlerForRecipient:recipient];
//        [handler connect];
//    }
//    else {
//        NSString *groupId = conv.recipient;
//        NSString *groupName = conv.recipientFullname;
//        ChatGroup *group = [[ChatGroup alloc] initWithGroupId:groupId name:groupName];
//        ChatConversationHandler *handler;
//        handler = [self getConversationHandlerForGroup:group];
//        [handler connect];
//    }
//}

-(ChatConversationHandler *)getConversationHandlerForRecipient:(ChatUser *)recipient {
    ChatConversationHandler *handler = [self.handlers objectForKey:recipient.userId];
    if (!handler) {
        NSLog(@"Conversation Handler not found. Creating & initializing a new one with recipient-id %@", recipient.userId);
        handler = [[ChatConversationHandler alloc] initWithRecipient:recipient.userId recipientFullName:recipient.fullname];
        [self addConversationHandler:handler];
        [handler restoreMessagesFromDB];
        NSLog(@"Restored messages (recipient: %@) count: %lu", recipient.userId, (unsigned long)handler.messages.count);
    }
    return handler;
}

-(ChatConversationHandler *)getConversationHandlerForGroup:(ChatGroup *)group {
    ChatConversationHandler *handler = [self.handlers objectForKey:group.groupId];
    if (!handler) {
        handler = [[ChatConversationHandler alloc] initWithGroupId:group.groupId groupName:group.name];
        [self addConversationHandler:handler];
        [handler restoreMessagesFromDB];
        NSLog(@"Restored messages (group: %@) count: %lu", group.groupId, (unsigned long)handler.messages.count);
//        [handler connect];
    }
    return handler;
}

-(ChatConversationsHandler *)createConversationsHandler {
    ChatConversationsHandler *handler = [[ChatConversationsHandler alloc] initWithTenant:self.tenant user:self.loggedUser];
    self.conversationsHandler = handler;
    return handler;
}

-(ChatPresenceHandler *)createPresenceHandler {
    ChatPresenceHandler *handler = [[ChatPresenceHandler alloc] initWithTenant:self.tenant user:self.loggedUser];
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
        handler = [self createPresenceHandler];
        self.presenceHandler = handler;
        NSLog(@"Presence handler ok.");
        [self.presenceHandler setupMyPresence];
    }
}

-(ChatContactsSynchronizer *)createContactsSynchronizerForUser:(ChatUser *)user {
    ChatContactsSynchronizer *syncronizer = [[ChatContactsSynchronizer alloc] initWithTenant:self.tenant user:user];
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
        handler = [self createGroupsHandlerForUser:self.loggedUser];
        [handler restoreGroupsFromDB]; // not thread-safe, call this method before firebase synchronization start
        [handler connect]; // firebase synchronization starts
    }
}

-(void)initContactsSynchronizer {
    if (!self.contactsSynchronizer) {
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
            if (completionBlock != nil) {
                completionBlock(error);
            }
        } else {
            NSLog(@"Command: \"Create Contact %@/%@ on Firebase\" was successfull.",user.userId, user.fullname);
            if (completionBlock != nil) {
                completionBlock(nil);
            }
        }
    }];
}

-(void)createGroup:(ChatGroup *)group withCompletionBlock:(void (^)(ChatGroup *group, NSError* error))callback {
    //    SHPUser *me = self.context.loggedUser;
    NSString *me = self.loggedUser.userId;
    
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
            [[ChatDB getSharedInstance] insertOrUpdateConversationSyncronized:groupConversation completion:^{
//                NSLog(@">>>>> -Group Failed- Conversation insertOrUpdate operation is %d", result);
                [self.conversationsHandler restoreConversationsFromDB];
                callback(group, error);
            }];
        } else {
            // we have the group-id
            NSLog(@"Group created with ID: %@", _groupId);
            NSLog(@"Group created with ID: %@", group.groupId);
            
            [self.groupsHandler insertOrUpdateGroup:group completion:^{
                NSLog(@"DB.Group id: %@", group.groupId);
                ChatGroup *group_on_db = [[ChatManager getInstance] groupById:group.groupId];
                NSLog(@"GROUP. name: %@, id: %@", group_on_db.name, group_on_db.groupId);
                callback(group, nil);
            }];
        }
    }];
}

-(NSString *)groupCreatedMessageForMemberInGroup:(ChatGroup *)group {
    return [NSString stringWithFormat:[ChatLocal translate:@"You created the group"], [group.name capitalizedString]];
}

-(void)addMember:(NSString *)member_id toGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock {
    NSLog(@"Adding member %@ to group %@...", member_id, group.groupId);
    NSString *member_relative_path = [group memberPath:member_id];
    NSString *groups_path = [ChatUtil mainGroupsPath];
    NSString *member_path = [groups_path stringByAppendingFormat:@"/%@/%@", group.groupId, member_relative_path];
    NSMutableDictionary *fanOut = [[NSMutableDictionary alloc] init];
    fanOut[member_path] = @(true);
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    [rootRef updateChildValues:fanOut withCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
        completionBlock(error);
    }];
}

-(void)removeMember:(NSString *)member_id fromGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock {
    NSString *member_relative_path = [group memberPath:member_id];
    NSString *groups_path = [ChatUtil mainGroupsPath];
    NSString *member_path = [groups_path stringByAppendingFormat:@"/%@/%@", group.groupId, member_relative_path];
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *member_ref = [rootRef child:member_path];
    [member_ref removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
        completionBlock(error);
    }];
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

-(void)removeConversation:(ChatConversation *)conversation {
    NSString *conversationId = conversation.conversationId;
    NSLog(@"Removing conversation from local DB...");
//    [self removeConversationFromDB:conversationId];
    ChatDB *db = [ChatDB getSharedInstance];
    [db removeConversationSynchronized:conversationId completion:^{
        [db removeAllMessagesForConversationSynchronized:conversationId completion:^{
            NSLog(@"Removing conversation with ref %@...", conversation.ref);
            FIRDatabaseReference *conversationRef = conversation.ref;
            [conversationRef removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *firebaseRef) {
                NSLog(@"Conversation %@ removed from firebase with error: %@", firebaseRef, error);
            }];
        }];
    }];
}

-(void)updateConversationIsNew:(FIRDatabaseReference *)conversationRef is_new:(int)is_new {
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
    NSString *FCMToken = [FIRMessaging messaging].FCMToken;
    NSLog(@"Removing instanceId (FCMToken: %@) on path: %@",FCMToken, user_path);
    [[[[[[FIRDatabase database] reference] child:user_path] child:@"instances"] child:FCMToken] removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
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
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(user);
        });
    }];
}

-(void)getUserInfoRemote:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback {
    NSLog(@"Get remote contact.");
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *userInfoRef = [[rootRef child: [ChatUtil contactsPath]] child:userid];
    
    [userInfoRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        ChatUser *user = [ChatContactsSynchronizer contactFromSnapshotFactory:snapshot];
        if (user) {
            NSLog(@"FIREBASE CONTACT, id: %@ firstname: %@ fullname: %@",user.userId, user.firstname, user.fullname);
            callback(user);
        }
        callback(nil);
    } withCancelBlock:^(NSError *error) {
         NSLog(@"%@", error.description);
    }];
}

-(void)registerForNotifications:(NSData *)devToken {
    NSString *FCMToken = [FIRMessaging messaging].FCMToken;
    NSLog(@"FCMToken: %@", FCMToken);
    if (FCMToken == nil) {
        NSLog(@"ERROR: FCMToken is nil");
        return;
    }
    [FIRMessaging messaging].APNSToken = devToken;
    NSLog(@"[FIRMessaging messaging].APNSToken: %@", [FIRMessaging messaging].APNSToken);
    ChatUser *loggedUser = self.loggedUser;
    if (loggedUser) {
        NSLog(@"userId: %@ ", loggedUser.userId);
        NSString *user_path = [ChatUtil userPath:loggedUser.userId];
        NSLog(@"userPath: %@", user_path);
        NSLog(@"Writing instanceId (FCMToken) %@ on path: %@", FCMToken, user_path);
        
        NSMutableDictionary *device_data = [[NSMutableDictionary alloc] init];
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey];
        [device_data setObject:appName forKey:@"app_name"];
        [device_data setObject:[[UIDevice currentDevice] model] forKey:@"device_model"];
        [device_data setObject:[[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode] forKey:@"language"];
        [device_data setObject:@"iOS" forKey:@"platform"];
        [device_data setObject:[[UIDevice currentDevice] systemVersion] forKey:@"platform_version"];
        
        [[[[[[FIRDatabase database] reference] child:user_path] child:@"instances"] child:FCMToken] setValue:device_data withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (error) {
                NSLog(@"Error saving instanceId (FCMToken) on user_path %@: %@", error, user_path);
            }
            else {
                NSLog(@"instanceId (FCMToken) %@ saved", FCMToken);
            }
        }];
    }
    else {
        NSLog(@"No user is signed in for push notifications.");
    }
}

-(FIRStorageReference *)uploadProfileImage:(UIImage *)image profileId:(NSString *)profileId completion:(void(^)(NSString *downloadURL, NSError *error))callback progressCallback:(void(^)(double fraction))progressCallback {
    NSData *data = UIImageJPEGRepresentation(image, 0.9);
//    NSData *data = UIImagePNGRepresentation(image);
    // Get a reference to the storage service using the default Firebase App
    FIRStorage *storage = [FIRStorage storage];
    // Create a root reference
    FIRStorageReference *storageRef = [storage reference];
    NSString *file_path = [ChatManager profileImagePathOf:profileId]; //self.loggedUser.profileImagePath;
    NSLog(@"profile image remote file path: %@", file_path);
    // Create a reference to the file you want to upload
    FIRStorageReference *storeRef = [storageRef child:file_path];
    NSLog(@"StoreRef: %@", storeRef);
    // Create file metadata including the content type
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/jpg";
    // Upload the file to the path
    [storeRef putData:data metadata:metadata completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error != nil) {
            NSLog(@"an error occurred! %@", error);
            callback(nil, error);
        } else {
            NSString *url = [ChatManager profileImageURLOf:profileId];
            NSLog(@"Download url: %@", url);
            callback(url, nil);
        }
    }];
    return storeRef;
}

-(void)deleteProfileImage:(NSString *)profileId completion:(void(^)(NSError *error))callback {
    [self.imageCache deleteFilesFromDiskCacheOfProfile:profileId];
    [ChatService deleteProfilePhoto:profileId completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Deletion of profile photo of %@ ended with error: %@", profileId,  error);
                callback(error);
            }
            else {
                NSLog(@"Profile photo of %@ successfully deleted.", profileId);
                callback(nil);
            }
        });
    }];
}

// **** PROFILE IMAGE URL ****

static NSString *PROFILE_PHOTO_NAME = @"photo.jpg";
static NSString *PROFILE_THUMB_PHOTO_NAME = @"thumb_photo.jpg";

+(NSString *)filePathOfProfile:(NSString *)profileId fileName:(NSString *)fileName {
    return [[NSString alloc] initWithFormat:@"profiles/%@/%@", profileId, fileName];
}

+(NSString *)profileImagePathOf:(NSString *)profileId {
    return [ChatManager filePathOfProfile:profileId fileName:PROFILE_PHOTO_NAME];
}

+(NSString *)profileImageURLOf:(NSString *)profileId {
    // http://base-url/profile/USER-ID/photo_name
    return [ChatManager fileURLOfProfile:profileId fileName:PROFILE_PHOTO_NAME];
}

+(NSString *)profileThumbImageURLOf:(NSString *)profileId {
    // http://base-url/profile/USER-ID/thumb_photo_name
    return [ChatManager fileURLOfProfile:profileId fileName:PROFILE_THUMB_PHOTO_NAME];
}

+(NSString *)fileURLOfProfile:(NSString *)profileId fileName:(NSString *)fileName {
    NSString *profile_base_url = [ChatManager profileBaseURL:profileId];
    NSString *file_url = [[NSString alloc] initWithFormat:@"%@%%2F%@?alt=media", profile_base_url, fileName];
//    NSLog(@"profile file url: %@", file_url);
    return file_url;
}

+(NSString *)profileBaseURL:(NSString *)profileId {
    NSLog(@"Someone called me.");
    // RETURNS:
    // https://firebasestorage.googleapis.com/v0/b/chat-v2-dev.appspot.com/o/profiles/PROFILE-ID
    NSDictionary *google_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"]];
//    NSDictionary *chat_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
    NSString *bucket = [google_info_dict objectForKey:@"STORAGE_BUCKET"];
//    NSString *profile_image_base_url = [chat_info_dict objectForKey:@"profile-image-base-url"];
    NSString *profile_image_base_url = [ChatManager getInstance].profileImageBaseURL;
    NSString *base_url = [[NSString alloc] initWithFormat:profile_image_base_url, bucket];
    NSString *profile_base_url = [[NSString alloc] initWithFormat:@"%@/profiles%%2F%@", base_url, profileId];
//    NSLog(@"profile_base_url: %@", profile_base_url);
    return profile_base_url;
}

// **** PROFILE IMAGE URL - END ****

@end

