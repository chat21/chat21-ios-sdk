//
//  ChatConversationsHandler.h
//  Soleto
//
//  Created by Andrea Sponziello on 29/12/14.
//

#import <Foundation/Foundation.h>
//#import "SHPConversationsViewDelegate.h"
#import "ChatEventType.h"

@import Firebase;

@class ChatUser;
@class ChatConversation;

@interface ChatConversationsHandler : NSObject

@property (strong, nonatomic) ChatUser *loggeduser;
@property (strong, nonatomic) NSString *me;
//@property (strong, nonatomic) FirebaseCustomAuthHelper *authHelper;
@property (strong, nonatomic) NSMutableArray<ChatConversation *> *conversations;
@property (strong, nonatomic) NSMutableArray<ChatConversation *> *archivedConversations;
@property (strong, nonatomic) NSString *firebaseToken;
@property (strong, nonatomic) FIRDatabaseReference *conversationsRef;
@property (strong, nonatomic) FIRDatabaseReference *archivedConversationsRef;
@property (assign, nonatomic) FIRDatabaseHandle conversations_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle conversations_ref_handle_changed;
@property (assign, nonatomic) FIRDatabaseHandle conversations_ref_handle_removed;
@property (assign, nonatomic) FIRDatabaseHandle archived_conversations_ref_handle_added;
@property (assign, nonatomic) FIRDatabaseHandle archived_conversations_ref_handle_removed;
//@property (assign, nonatomic) id <SHPConversationsViewDelegate> delegateView;
@property (strong, nonatomic) NSString *currentOpenConversationId;
@property (nonatomic, strong) FIRDatabaseReference *rootRef;
@property (strong, nonatomic) NSString *tenant;

// observer
@property (strong, nonatomic) NSMutableDictionary *eventObservers; // ( event_enum : DictionaryOfCallbacks (event_handle : event_callback) )
@property (assign, atomic) volatile int64_t lastEventHandler;
-(NSUInteger)observeEvent:(ChatConversationEventType)eventType withCallback:(void (^)(ChatConversation *conversation))callback;
-(void)removeObserverWithHandle:(NSUInteger)event_handler;
-(void)removeAllObservers;

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user;
-(void)connect;
-(void)dispose;
-(void)restoreConversationsFromDB;
-(void)updateLocalConversation:(ChatConversation *)conversation completion:(void(^)(void)) callback;
//-(void)removeLocalConversation:(ChatConversation *)conversation;
-(void)removeLocalConversation:(ChatConversation *)conversation completion:(void(^)(void)) callback;

@end
