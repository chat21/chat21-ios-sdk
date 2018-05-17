//
//  ChatConversationHandler.h
//  Soleto
//
//  Created by Andrea Sponziello on 19/12/14.
//
//

#import <Foundation/Foundation.h>
#import "ChatEventType.h"

@import Firebase;

@class FAuthData;
@class FirebaseCustomAuthHelper;
@class Firebase;
@class ChatUser;
@class ChatGroup;
@class ChatMessage;
@class ChatMessageMetadata;
@class ChatImageDownloadManager;

@interface ChatConversationHandler : NSObject //<ChatGroupsDelegate>

@property (strong, nonatomic) ChatUser *user;
@property (strong, nonatomic) NSString *recipientId;
@property (strong, nonatomic) NSString *recipientFullname;
//@property (strong, nonatomic) NSString *groupName;
//@property (strong, nonatomic) NSString *groupId;

@property (strong, nonatomic) NSString *senderId;

@property (strong, nonatomic) NSString *conversationId;
@property (strong, nonatomic) NSMutableArray<ChatMessage *> *messages;
@property (strong, nonatomic) NSString *firebaseToken;
@property (strong, nonatomic) FIRDatabaseReference *messagesRef;
@property (strong, nonatomic) FIRDatabaseReference *conversationOnSenderRef;
@property (strong, nonatomic) FIRDatabaseReference *conversationOnReceiverRef;
@property (assign, nonatomic) FIRDatabaseHandle messages_ref_handle;
@property (assign, nonatomic) FIRDatabaseHandle updated_messages_ref_handle;
@property (strong, nonatomic) FirebaseCustomAuthHelper *authHelper;
@property (strong, nonatomic) NSString *channel_type;
@property (strong, nonatomic) ChatImageDownloadManager *imageDownloader;

// observer
@property (strong, nonatomic) NSMutableDictionary *eventObservers;
@property (assign, atomic) volatile int64_t lastEventHandle;
-(NSUInteger)observeEvent:(ChatMessageEventType)eventType withCallback:(void (^)(ChatMessage *message))callback;
-(void)removeObserverWithHandle:(NSUInteger)event_handle;
-(void)removeAllObservers;

@property (assign, nonatomic) double lastSentReadNotificationTime;

-(id)initWithRecipient:(NSString *)recipientId recipientFullName:(NSString *)recipientFullName;
-(id)initWithGroupId:(NSString *)groupId groupName:(NSString *)groupName;
-(void)connect;
-(void)dispose;
-(void)sendTextMessage:(NSString *)text completion:(void(^)(ChatMessage *message, NSError *error)) callback;
//-(void)sendTextMessage:(NSString *)text subtype:(NSString *)subtype attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback;
-(void)sendTextMessage:(NSString *)text subtype:(NSString *)subtype attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback;
//-(void)appendImagePlaceholderMessageWithFilename:(NSString *)imageFilename metadata:(ChatMessageMetadata *)metadata attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error))callback;
-(void)appendImagePlaceholderMessageWithImage:(UIImage *)image attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback;
-(void)sendImagePlaceholderMessage:(ChatMessage *)message completion:(void (^)(ChatMessage *, NSError *))callback;
-(void)sendMessageType:(NSString *)type subtype:(NSString *)subtype text:(NSString *)text imageURL:(NSString *)imageURL metadata:(ChatMessageMetadata *)metadata attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback;
-(void)restoreMessagesFromDB;
-(NSString *)mediaFolderPath;
+(NSString *)mediaFolderPathOfRecipient:(NSString *)recipiendId;
-(void)saveImageToRecipientMediaFolderAsPNG:(UIImage *)image imageFileName:(NSString *)imageFileName;
-(void)uploadImage:(UIImage *)image fileName:(NSString *)fileName completion:(void(^)(NSURL *downloadURL, NSError *error)) callback progressCallback:(void(^)(double fraction))progressCallback;
-(void)updateMessageStatus:(int)status forMessage:(ChatMessage *)message;
//+(NSMutableDictionary *)firebaseMessageFor:(ChatMessage *)message;

@end
