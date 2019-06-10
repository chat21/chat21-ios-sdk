//
//  ChatDB.h
//  Soleto
//
//  Created by Andrea Sponziello on 05/12/14.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ChatMessage;
@class ChatConversation;
@class ChatGroup;
//@class ChatUser;

@interface ChatDB : NSObject
{
    NSString *databasePath;
}

@property (assign, nonatomic) BOOL logQuery;

+(ChatDB*)getSharedInstance;
//-(BOOL)createDB;
-(BOOL)createDBWithName:(NSString *)name;

// messages
//-(void)insertMessageIfNotExists:(ChatMessage *)message;
//-(BOOL)insertMessage:(ChatMessage *)message;

// SYNC OK
-(void)updateMessageSynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(void)) callback;
//-(BOOL)updateMessage:(NSString *)messageId withStatus:(int)status;
// SYNC TODO
-(BOOL)updateMessage:(NSString *)messageId status:(int)status text:(NSString *)text snapshotAsJSONString:(NSString *)snapshotAsJSONString;
// SYNC OK
-(void)removeAllMessagesForConversationSynchronized:(NSString *)conversationId completion:(void(^)(void)) callback;
// SYNC OK
-(void)insertMessageIfNotExistsSyncronized:(ChatMessage *)message completion:(void(^)(void)) callback;
// SYNC OK
-(void)getMessageByIdSyncronized:(NSString *)messageId completion:(void(^)(ChatMessage *)) callback;

-(NSArray*)getAllMessages;
-(NSArray*)getAllMessagesForConversation:(NSString *)conversationId start:(int)start count:(int)count;
-(NSArray*)getAllMessagesForConversation:(NSString *)conversationId;
//-(ChatMessage *)getMessageById:(NSString *)messageId;


// conversations

// SYNC OK
-(void)insertOrUpdateConversationSyncronized:(ChatConversation *)conversation completion:(void(^)(void)) callback;
//-(BOOL)insertOrUpdateConversation:(ChatConversation *)conversation;
//-(BOOL)insertConversation:(ChatConversation *)conversation;
//-(BOOL)updateConversation:(ChatConversation *)conversation;
// SYNC OK
- (void)removeConversationSynchronized:(NSString *)conversationId completion:(void(^)(void)) callback;
//-(BOOL)removeConversation:(NSString *)conversationId;
-(NSArray*)getAllConversations;
- (NSArray*)getAllConversationsForUser:(NSString *)user archived:(BOOL)archived limit:(int)limit;
- (void)getConversationByIdSynchronized:(NSString *)conversationId completion:(void(^)(ChatConversation *)) callback;
//-(ChatConversation *)getConversationById:(NSString *)conversationId;


@end
