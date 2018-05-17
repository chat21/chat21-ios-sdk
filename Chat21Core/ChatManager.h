//
//  ChatManager.h
//  Soleto
//
//  Created by Andrea Sponziello on 20/12/14.
//
//

#import <Foundation/Foundation.h>

//static NSString* const NOTIFICATION_TYPE_MEMBER_ADDED_TO_GROUP = @"group_member_added";
//static NSString* const GROUP_OWNER = @"owner";
//static NSString* const GROUP_CREATEDON = @"createdOn";
//static NSString* const GROUP_NAME = @"name";
//static NSString* const GROUP_MEMBERS = @"members";
//static NSString* const GROUP_ICON_URL = @"iconURL";

@import Firebase;

// static NSString *GROUPS_BASE_URL = @"/groups";

@class ChatConversationHandler;
@class ChatConversationsHandler;
@class ChatGroupsHandler;
@class SHPUser;
@class ChatGroup;
@class FDataSnapshot;
@class ChatConversation;
@class ChatPresenceHandler;
@class ChatConversationsVC;
@class ChatUser;
@class ChatContactsSynchronizer;
@class ChatSpeaker;
@class ChatConversationHandler;
@class ChatConnectionStatusHandler;

@interface ChatManager : NSObject

@property (nonatomic, strong) NSString *tenant;
@property (nonatomic, strong) ChatUser *loggedUser;
@property (nonatomic, strong) NSMutableDictionary<NSString*, ChatConversationHandler*> *handlers;
@property (nonatomic, strong) ChatConversationsHandler *conversationsHandler;
@property (nonatomic, strong) ChatPresenceHandler *presenceHandler;
@property (nonatomic, strong) ChatConnectionStatusHandler *connectionStatusHandler;
@property (nonatomic, strong) ChatGroupsHandler *groupsHandler;
@property (nonatomic, strong) ChatContactsSynchronizer *contactsSynchronizer;
//@property (nonatomic, strong) ChatConversationsVC * conversationsVC;
@property (strong, nonatomic) FIRAuthStateDidChangeListenerHandle authStateDidChangeListenerHandle;
//@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;
@property (assign, nonatomic) BOOL groupsMode;
@property (assign, nonatomic) NSInteger tabBarIndex;

+(void)configureWithAppId:(NSString *)app_id;
+(void)configure;
+(ChatManager *)getInstance;
-(void)getContactLocalDB:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;
-(void)getUserInfoRemote:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;

-(void)addConversationHandler:(ChatConversationHandler *)handler;
-(ChatConversationsHandler *)getConversationsHandler;
-(ChatConversationHandler *)getConversationHandlerForRecipient:(ChatUser *)recipient;
-(ChatConversationHandler *)getConversationHandlerForGroup:(ChatGroup *)group;

-(ChatConversationsHandler *)createConversationsHandler;
-(ChatPresenceHandler *)createPresenceHandler;
-(ChatGroupsHandler *)createGroupsHandlerForUser:(ChatUser *)user;
-(ChatContactsSynchronizer *)createContactsSynchronizerForUser:(ChatUser *)user;

//-(void)createGroupFromPushNotificationWithName:(NSString *)groupName groupId:(NSString *)groupId;
-(void)registerForNotifications:(NSData *)devToken;

-(void)startWithUser:(ChatUser *)user;
-(void)dispose;

// === GROUPS ===

// se errore aggiorna conversazione-gruppo locale (DB, creata dopo) con messaggio errore, stato "riprova" e menù "riprova" (vedi creazione gruppo whatsapp in modalità "aereo").

-(NSString *)newGroupId;
-(void)addMember:(NSString *)user_id toGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
-(void)removeMember:(NSString *)user_id fromGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
+(ChatGroup *)groupFromSnapshotFactory:(FIRDataSnapshot *)snapshot;
-(ChatGroup *)groupById:(NSString *)groupId;
-(void)createGroup:(ChatGroup *)group withCompletionBlock:(void (^)(ChatGroup *group, NSError* error))callback;
-(void)updateGroupName:(NSString *)name forGroup:(ChatGroup *)group withCompletionBlock:(void (^)(NSError *))completionBlock;
-(NSDictionary *)allGroups;

// === CONVERSATIONS ===

//-(void)createOrUpdateConversation:(ChatConversation *)conversation;
-(void)removeConversation:(ChatConversation *)conversation;
-(void)removeConversationFromDB:(NSString *)conversationId;
-(void)updateConversationIsNew:(FIRDatabaseReference *)conversationRef is_new:(int)is_new;

// === CONTACTS ===
-(void)createContactFor:(ChatUser *)user withCompletionBlock:(void (^)(NSError *))completionBlock;

-(void)removeInstanceId;
-(void)loadGroup:(NSString *)group_id completion:(void (^)(ChatGroup* group, BOOL error))callback;

//-(void)isStatusConnectedWithCompletionBlock:(void (^)(BOOL connected, NSError* error))callback;

@end

