//
//  ChatManager.h
//  Soleto
//
//  Created by Andrea Sponziello on 20/12/14.
//
//

#import <Foundation/Foundation.h>

@import Firebase;
@import UIKit;

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
@class ChatDiskImageCache;
@class ChatMessage;

@interface ChatManager : NSObject

// plist properties
@property (nonatomic, strong) NSString *tenant;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *archiveConversationURI;
@property (nonatomic, strong) NSString *archiveAndCloseSupportConversationURI;
@property (nonatomic, strong) NSString *profileImageBaseURL;
@property (nonatomic, strong) NSString *deleteProfilePhotoURI;

@property (nonatomic, strong) ChatUser *loggedUser;
@property (nonatomic, strong) NSMutableDictionary<NSString*, ChatConversationHandler*> *handlers;
@property (nonatomic, strong) ChatConversationsHandler *conversationsHandler;
@property (nonatomic, strong) ChatPresenceHandler *presenceHandler;
@property (nonatomic, strong) ChatConnectionStatusHandler *connectionStatusHandler;
@property (nonatomic, strong) ChatGroupsHandler *groupsHandler;
@property (nonatomic, strong) ChatContactsSynchronizer *contactsSynchronizer;
@property (nonatomic, strong) ChatDiskImageCache *imageCache;
//@property (nonatomic, strong) ChatConversationsVC * conversationsVC;
@property (strong, nonatomic) FIRAuthStateDidChangeListenerHandle authStateDidChangeListenerHandle;
//@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;
@property (assign, nonatomic) BOOL groupsMode;
@property (assign, nonatomic) NSInteger tabBarIndex;

//+(void)configureWithAppId:(NSString *)app_id;
+(void)configure;
+(ChatManager *)getInstance;
-(void)getContactLocalDB:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;
-(void)getUserInfoRemote:(NSString *)userid withCompletion:(void(^)(ChatUser *user))callback;

-(void)addConversationHandler:(ChatConversationHandler *)handler;
-(ChatConversationsHandler *)getAndStartConversationsHandler;
-(ChatConversationHandler *)getConversationHandlerForRecipient:(ChatUser *)recipient;
-(ChatConversationHandler *)getConversationHandlerForGroup:(ChatGroup *)group;
//-(void)startConversationHandler:(ChatConversation *)conv;

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
//-(void)removeConversationFromDB:(NSString *)conversationId;
-(void)updateConversationIsNew:(FIRDatabaseReference *)conversationRef is_new:(int)is_new;

// === CONTACTS ===
-(void)createContactFor:(ChatUser *)user withCompletionBlock:(void (^)(NSError *))completionBlock;

-(void)removeInstanceId;
-(void)loadGroup:(NSString *)group_id completion:(void (^)(ChatGroup* group, BOOL error))callback;

-(FIRStorageReference *)uploadProfileImage:(UIImage *)image profileId:(NSString *)profileId completion:(void(^)(NSString *downloadURL, NSError *error))callback progressCallback:(void(^)(double fraction))progressCallback;
-(void)deleteProfileImage:(NSString *)profileId completion:(void(^)(NSError *error))callback;

// profile image
// paths
+(NSString *)filePathOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileImagePathOf:(NSString *)profileId;
// URLs
+(NSString *)profileImageURLOf:(NSString *)profileId;
+(NSString *)profileThumbImageURLOf:(NSString *)profileId;
+(NSString *)fileURLOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileBaseURL:(NSString *)profileId;

@property (nonatomic, copy) ChatMessage *(^onBeforeMessageSend)(ChatMessage *msg);
@property (nonatomic, copy) ChatMessage *(^onMessageNew)(ChatMessage *msg);
@property (nonatomic, copy) ChatMessage *(^onMessageUpdate)(ChatMessage *msg);
@property (nonatomic, copy) ChatConversation *(^onCoversationArrived)(ChatConversation *conv);
@property (nonatomic, copy) ChatConversation *(^onCoversationUpdated)(ChatConversation *conv);

@end

