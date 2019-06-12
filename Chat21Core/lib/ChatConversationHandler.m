//
//  ChatConversationHandler.m
//  Soleto
//
//  Created by Andrea Sponziello on 19/12/14.
//

#import "ChatConversationHandler.h"
#import "ChatMessage.h"
#import "FirebaseCustomAuthHelper.h"
#import "ChatUtil.h"
#import "ChatDB.h"
#import "ChatConversation.h"
#import "ChatManager.h"
#import "ChatGroup.h"
#import "ChatUser.h"
#import <libkern/OSAtomic.h>
#import "ChatMessageMetadata.h"
#import "ChatImageDownloadManager.h"

@interface ChatConversationHandler () {
    dispatch_queue_t serialMessagesMemoryQueue;
}
@end

@implementation ChatConversationHandler

-(id)init {
    if (self = [super init]) {
        [self basicInit];
    }
    return self;
}

-(void)basicInit {
    serialMessagesMemoryQueue = dispatch_queue_create("messagesQueue", DISPATCH_QUEUE_SERIAL);
    self.lastEventHandle = 1;
    self.imageDownloader = [[ChatImageDownloadManager alloc] init];
}

-(id)initWithRecipient:(NSString *)recipientId recipientFullName:(NSString *)recipientFullName {
    if (self = [super init]) {
        [self basicInit];
        self.channel_type = MSG_CHANNEL_TYPE_DIRECT;
        self.recipientId = recipientId;
        self.recipientFullname = recipientFullName;
        self.user = [ChatManager getInstance].loggedUser;
        self.senderId = self.user.userId;
        self.conversationId = recipientId; //[ChatUtil conversationIdWithSender:user.userId receiver:recipient]; //conversationId;
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithGroupId:(NSString *)groupId groupName:(NSString *)groupName {
    if (self = [super init]) {
        [self basicInit];
        self.channel_type = MSG_CHANNEL_TYPE_GROUP;
        self.recipientId = groupId;
        self.recipientFullname = groupName;
        self.user = [ChatManager getInstance].loggedUser;
        self.senderId = self.user.userId;
        self.conversationId = groupId;
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dispose {
    [self.messagesRef removeAllObservers];
    [self removeAllObservers];
    self.messages_ref_handle = 0;
    self.updated_messages_ref_handle = 0;
}

-(void)restoreMessagesFromDB {
    NSLog(@"RESTORING ALL MESSAGES FOR CONVERSATION %@", self.conversationId);
    NSArray *inverted_messages = [[[ChatDB getSharedInstance] getAllMessagesForConversation:self.conversationId start:0 count:200] mutableCopy];
//    NSLog(@"DB MESSAGES NUMBER: %lu", (unsigned long) inverted_messages.count);
    NSLog(@"Restoring last 40 messages...");
    NSEnumerator *enumerator = [inverted_messages reverseObjectEnumerator];
    for (id element in enumerator) {
        [self.messages addObject:element];
    }
    
    // set as status:"failed" all the messages in status: "sending"
    for (ChatMessage *m in self.messages) {
        if (m.status == MSG_STATUS_SENDING || m.status == MSG_STATUS_UPLOADING) {
            m.status = MSG_STATUS_FAILED;
        }
    }
}

-(void)connect {
    // if already connected return
    if (self.messages_ref_handle) {
        return;
    }
    self.messagesRef = [ChatUtil conversationMessagesRef:self.recipientId];
    self.conversationOnSenderRef = [ChatUtil conversationRefForUser:self.senderId conversationId:self.conversationId];
    self.conversationOnReceiverRef = [ChatUtil conversationRefForUser:self.recipientId conversationId:self.conversationId];
    
    NSInteger lasttime = 0;
    if (self.messages && self.messages.count > 0) {
        ChatMessage *message = [self.messages lastObject];
        NSLog(@"****** MOST RECENT MESSAGE TIME %@ %@", message, message.date);
        lasttime = message.date.timeIntervalSince1970 * 1000; // objc returns time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. * 1000 translates seconds in millis and the query is ok.
    } else {
        lasttime = 0;
    }
//    int i = 0;
//    __block int count = i;
    self.messages_ref_handle = [[[[self.messagesRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] queryLimitedToLast:40] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        // IMPORTANT: this query ignores messages without a timestamp.
        // IMPORTANT: This callback is called also for newly locally created messages still not sent.
        NSLog(@"NEW MESSAGE SNAPSHOT: %@", snapshot);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSLog(@"Asynch message processing pipeline started....");
            if (![self isValidMessageSnapshot:snapshot]) {
                NSLog(@"New Message handler. Discarding invalid snapshot: %@", snapshot);
                return;
            }
            else {
                NSLog(@"New Message handler. Valid snapshot.");
            }
            ChatMessage *message = [ChatMessage messageFromfirebaseSnapshotFactory:snapshot];
            message.conversationId = self.conversationId; // DB query is based on this attribute!!! (conversationID = Recipient)
            ChatManager *chatm = [ChatManager getInstance];
            if (chatm.onMessageNew) {
                message = chatm.onMessageNew(message);
                if (message == nil) {
                    return;
                }
            }
            // This callback is also called for newly locally created messages (not still sent, called also with network off).
            // Then, for every "new" message received (also locally generated) we update onversation status to "read" (is_new = false).
            // Updates status only of messages not sent by me
            if (message.status < MSG_STATUS_RECEIVED && ![message.sender isEqualToString:self.senderId]) {
                // VERIFY... "message.status < MSG_STATUS_RECEIVED" IN ORDER TO AVOID THE COST OF RE-UPDATING CONTINUOUSLY THE STATE OF MESSAGES THAT ALREADY HAVE THE "RECEIVED" STATE (IT MAY BE THE SYNCHRONIZATION OF A NEW DEVICE THAT MUST NO LONGER COMMUNICATE ANYTHING TO THE SENDER BUT ONLY DOWNLOAD THE MESSAGES IN THE STATE IN WHICH THEY ARE FOUND).
                // NOT RECEIVED = NEW!
                if (message.isDirect) {
                    [message updateStatusOnFirebase:MSG_STATUS_RECEIVED]; // firebase
                } else {
                    // TODO: implement received status for group's messages
                }
            }
            // updates or inserts new messages
            // This check is necessary to avoid this message notified as "new" (...playing sound etc.)
            [self insertMessageIfNotExists:message completion:^{
                NSLog(@"New message saved. Notiying to subscribers...");
                [self notifyEvent:ChatEventMessageAdded message:message];
            }];
        });
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    self.updated_messages_ref_handle = [self.messagesRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"UPDATED MESSAGE SNAPSHOT: %@", snapshot);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (![self isValidMessageSnapshot:snapshot]) {
                NSLog(@"Message Updated. Discarding invalid snapshot: %@", snapshot);
                return;
            }
            else {
                NSLog(@"Message Updated. Valid snapshot: %@", snapshot);
            }
            ChatMessage *message = [ChatMessage messageFromfirebaseSnapshotFactory:snapshot];
            ChatManager *chatm = [ChatManager getInstance];
            if (chatm.onMessageUpdate) {
                NSLog(@"onMessageUpdate found. Executing.");
                message = chatm.onMessageUpdate(message);
                if (message == nil) {
                    NSLog(@"onMessageUpdate returned null. Stopping update pipeline.");
                    return;
                }
                NSLog(@"onMessageUpdate successfully ended.");
            }
            if (message.status == MSG_STATUS_SENDING || message.status == MSG_STATUS_SENT || message.status == MSG_STATUS_RETURN_RECEIPT) {
                 [[ChatDB getSharedInstance] getMessageByIdSyncronized:message.messageId completion:^(ChatMessage *saved_message) {
                     if (saved_message) {
                         // [self updateMessageStatusOnDB:message.messageId withStatus:message.status completion: {
                         //   [self updateMessageStatusInMemory:message.messageId withStatus:message.status];
                         //   [self notifyEvent:ChatEventMessageChanged message:message];
                         // }];
                         [self updateMessageStatusSynchronized:message.messageId withStatus:message.status completion:^{
                             [self notifyEvent:ChatEventMessageChanged message:message];
                         }];
                     }
                     else {
                         [self insertMessageIfNotExists:message completion:^{
                             [self notifyEvent:ChatEventMessageAdded message:message];
                         }];
                     }
                 }];
            }
        });
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(void)insertMessageIfNotExists:(ChatMessage *)message completion:(void(^)(void)) callback {
    [[ChatDB getSharedInstance] insertMessageIfNotExistsSyncronized:message completion:^{
        // TODO URGENT! Serial queue needed to avoid conflicting in writing on the same, shared, object!
        [self insertMessageInMemoryIfNotExists:message completion:^{
            if (callback != nil) callback();
        }];
    }];
}

-(BOOL)isValidMessageSnapshot:(FIRDataSnapshot *)snapshot {
    // TODO VALIDATE ALSO THE OPTIONAL "ATTRIBUTES" SECTION. IF EXISTS MUST BE A "DICTIONARY"
    if (snapshot.value[MSG_FIELD_TYPE] == nil) {
        NSLog(@"MSG:TYPE is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_TEXT] == nil) {
        NSLog(@"MSG:TEXT is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_SENDER] == nil) {
        NSLog(@"MSG:SENDER is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[MSG_FIELD_TIMESTAMP] == nil) {
        NSLog(@"MSG:TIMESTAMP is mandatory. Discarding message.");
        return NO;
    }
//    else if (snapshot.value[MSG_FIELD_STATUS] == nil) {
//        NSLog(@"MSG:STATUS is mandatory. Discarding message.");
//        return NO;
//    }
    
    return YES;
}

-(ChatMessage *)newBaseMessage {
    ChatMessage *message = [[ChatMessage alloc] init];
    FIRDatabaseReference *messageRef = [self.messagesRef childByAutoId]; // CHILD'S AUTOGEN UNIQUE ID
    message.messageId = messageRef.key;
    message.sender = self.senderId;
    message.senderFullname = self.user.fullname;
    NSDate *now = [[NSDate alloc] init];
    message.date = now;
    message.status = MSG_STATUS_SENDING;
    message.conversationId = self.conversationId; // = intelocutor-id, for local-db queries
    NSString *langID = [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
    message.lang = langID;
    return message;
}

-(void)appendImagePlaceholderMessageWithImage:(UIImage *)image attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    // TODO: validate metadata > specialize for image: ChatMessageImageMetadata to simplify validation
    ChatMessage *message = [self newBaseMessage];
    
    // save image
//    NSString * uuid = [[NSUUID UUID] UUIDString];
    NSString *image_file_name = message.imageFilename;
    [self saveImageToRecipientMediaFolderAsPNG:image imageFileName:image_file_name];
    ChatMessageMetadata *imageMetadata = [[ChatMessageMetadata alloc] init];
    imageMetadata.width = image.size.width;
    imageMetadata.height = image.size.height;
    
    message.status = MSG_STATUS_UPLOADING;
    message.text = [[NSString alloc] initWithFormat:@"Uploading image: %@...", image_file_name];
    message.mtype = MSG_TYPE_IMAGE;
    message.metadata = imageMetadata;
    message.attributes = [attributes mutableCopy];
    message.recipient = self.recipientId;
    message.recipientFullName = self.recipientFullname;
    message.channel_type = self.channel_type;
    [self createLocalMessage:message completion:^(NSString *messageId, NSError *error) {
        message.messageId = messageId;
        [self notifyEvent:ChatEventMessageAdded message:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(message, nil);
        });
    }];
}

-(void)sendImagePlaceholderMessage:(ChatMessage *)message completion:(void (^)(ChatMessage *, NSError *))callback {
    [[ChatDB getSharedInstance] updateMessage:message.messageId status:MSG_STATUS_SENDING text:message.text snapshotAsJSONString:message.snapshotAsJSONString];
    [self updateMessageInMemory:message.messageId status:MSG_STATUS_SENDING text:message.text imageURL:message.metadata.src];
    [self notifyEvent:ChatEventMessageChanged message:message];
    [self sendMessage:message completion:^(ChatMessage *message, NSError *error) {
        callback(message, error);
    }];
}

-(void)sendTextMessage:(NSString *)text completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    [self sendTextMessage:text
                  subtype:nil
               attributes:nil
               completion:^(ChatMessage *m, NSError *error) {
                   callback(m, error);
               }
     ];
}

-(void)sendTextMessage:(NSString *)text subtype:(NSString *)subtype attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    [self sendMessageType:MSG_TYPE_TEXT
                  subtype:nil
                     text:text
                 imageURL:nil
                 metadata:nil
               attributes:attributes
               completion:^(ChatMessage *m, NSError *error) {
                   callback(m, error);
               }
    ];
}

-(void)sendMessageType:(NSString *)type subtype:(NSString *)subtype text:(NSString *)text imageURL:(NSString *)imageURL metadata:(ChatMessageMetadata *)metadata attributes:(NSDictionary *)attributes completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    ChatMessage *message = [self newBaseMessage];
    NSLog(@"Created base message type: %@ with id: %@", message.mtype, message.messageId);
    if (text) {
        message.text = text;
    }
    if (imageURL) {
        message.metadata.src = imageURL;
    }
    message.mtype = type;
    if (subtype) {
        message.subtype = subtype;
    }
    if (metadata) {
        message.metadata = metadata;
    }
    message.attributes = [attributes mutableCopy];
    message.recipient = self.recipientId;
    message.recipientFullName = self.recipientFullname;
    message.channel_type = self.channel_type;
    [self createLocalMessage:message completion:^(NSString *messageId, NSError *error) {
        NSLog(@"Sending message type: %@ with id: %@", message.mtype, message.messageId);
        [self sendMessage:message completion:^(ChatMessage *message, NSError *error) {
            callback(message, error);
        }];
    }];
}

-(void)resendMessageWithId:(NSString *)messageId completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    [[ChatDB getSharedInstance] getMessageByIdSyncronized:messageId completion:^(ChatMessage *message) {
        if (message) {
            NSLog(@"Message %@ found.", messageId);
            message.status = MSG_STATUS_SENDING;
            [self updateMessageStatusSynchronized:message.messageId withStatus:message.status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                [self sendMessage:message completion:^(ChatMessage *message, NSError *error) {
                    callback(message, nil);
                }];
            }];
        }
        else {
            NSLog(@"Error. Message %@ not found.", messageId);
            callback(nil, nil);
        }
    }];
}

-(void)sendMessage:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error)) callback {
    ChatManager *chatm = [ChatManager getInstance];
    if (chatm.onBeforeMessageSend) {
        message = chatm.onBeforeMessageSend(message);
    }
    
    // custom handler can return a status = failed
    if (message.status == MSG_STATUS_SENDING) {
        if ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
            NSLog(@"Sending Group message. User: %@", [FIRAuth auth].currentUser.uid);
            [self sendMessageToGroup:message completion:^(ChatMessage *m, NSError *error) {
                callback(m, error);
            }];
        } else {
            NSLog(@"Sending Direct message. User: %@", [FIRAuth auth].currentUser.uid);
            [self sendDirect:message completion:^(ChatMessage *m, NSError *error) {
                callback(m, error);
            }];
        }
    }
    else { // status != sending stops sending pipeline
        [self updateMessageStatusSynchronized:message.messageId withStatus:message.status completion:^{
            [self notifyEvent:ChatEventMessageChanged message:message];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(message, nil);
            });
        }];
    }
}

//-(void)sendMessage:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error)) callback {
//    ChatManager *chatm = [ChatManager getInstance];
//    if (chatm.onBeforeMessageSend) {
//        message = chatm.onBeforeMessageSend(message);
//    }
//
//    // custom handler can return a status = failed
//    // if status == sending
//    if ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
//        NSLog(@"Sending Group message. User: %@", [FIRAuth auth].currentUser.uid);
//        [self sendMessageToGroup:message completion:^(ChatMessage *m, NSError *error) {
//            callback(m, error);
//        }];
//    } else {
//        NSLog(@"Sending Direct message. User: %@", [FIRAuth auth].currentUser.uid);
//        [self sendDirect:message completion:^(ChatMessage *m, NSError *error) {
//            callback(m, error);
//        }];
//    // else (status != sending stops sending pipeline
////        [self updateMessageStatusSynchronized:message.messageId withStatus:message.status completion:^{
////            [self notifyEvent:ChatEventMessageChanged message:message];
////            dispatch_async(dispatch_get_main_queue(), ^{
////                callback(message, error);
////            });
////        }];
//        // notify subscribers
//    // end
//    }
//}

-(void)createLocalMessage:(ChatMessage *)message completion:(void(^)(NSString *messageId, NSError *error))callback {
    // save message locally
    [[ChatDB getSharedInstance] insertMessageIfNotExistsSyncronized:message completion:^{
        // TODO URGENT! Serial queue needed to avoid conflicting in writing on the same, shared, object!
        [self insertMessageInMemoryIfNotExists:message completion:^{
            [self notifyEvent:ChatEventMessageAdded message:message];
            callback(message.messageId, nil);
        }];
    }];
}

-(void)sendDirect:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error))callback {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef child:message.messageId];
    
    // save message to firebase
    NSMutableDictionary *message_dict = [message asFirebaseMessage];
    NSLog(@"Sending message to Firebase: %@ %@ %d", message.text, message.messageId, message.status);
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"messageRef.setValue callback. %@", message_dict);
        if (error) {
            NSLog(@"Data could not be saved because of an occurred error: %@", error);
            int status = MSG_STATUS_FAILED;
//            [self updateMessageStatus:status forMessage:message];
//            callback(message, error);
            [self updateMessageStatusSynchronized:message.messageId withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(message, error);
                });
            }];
        } else {
            NSLog(@"Data saved successfully. Updating status & reloading tableView.");
            int status = MSG_STATUS_SENT;
            NSAssert([ref.key isEqualToString:message.messageId], @"REF.KEY %@ different by MESSAGE.ID %@",ref.key, message.messageId);
//            [self updateMessageStatus:status forMessage:message];
//            callback(message, error);
            [self updateMessageStatusSynchronized:message.messageId withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(message, error);
                });
            }];
        }
    }];
}

//-(void)updateMessageStatus:(int)status forMessage:(ChatMessage *)message {
//    [self updateMessageStatusInMemory:message.messageId withStatus:status];
//    [self updateMessageStatusOnDB:message.messageId withStatus:status];
//    [self notifyEvent:ChatEventMessageChanged message:message];
//}

-(void)sendMessageToGroup:(ChatMessage *)message completion:(void(^)(ChatMessage *message, NSError *error))callback {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef child:message.messageId];
//    FIRDatabaseReference *messageRef = [self.messagesRef childByAutoId]; // CHILD'S AUTOGEN UNIQUE ID
//    message.messageId = messageRef.key;
//    // save message locally
//    [self insertMessageInMemory:message];
//    [self insertMessageOnDBIfNotExists:message];
//    [self notifyEvent:ChatEventMessageAdded message:message];
    // save message to firebase
    NSMutableDictionary *message_dict = [message asFirebaseMessage];
    NSLog(@"(Group) Sending message to Firebase:(%@) %@ %@ %d dict: %@",messageRef, message.text, message.messageId, message.status, message_dict);
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"messageRef.setValue callback. %@", message_dict);
        if (error) {
            NSLog(@"Data could not be saved with error: %@", error);
            int status = MSG_STATUS_FAILED;
//            [self updateMessageStatusInMemory:ref.key withStatus:status];
//            [self updateMessageStatusOnDB:message.messageId withStatus:status];
//            [self notifyEvent:ChatEventMessageChanged message:message];
//            callback(message, error);
            [self updateMessageStatusSynchronized:ref.key withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(callback != nil) callback(message, error);
                });
            }];
        } else {
            NSLog(@"Data saved successfully. Updating status & reloading tableView.");
            int status = MSG_STATUS_SENT;
//            [self updateMessageStatusInMemory:ref.key withStatus:status];
//            [self updateMessageStatusOnDB:message.messageId withStatus:status];
//            [self notifyEvent:ChatEventMessageChanged message:message];
//            callback(message, error);
            [self updateMessageStatusSynchronized:ref.key withStatus:status completion:^{
                [self notifyEvent:ChatEventMessageChanged message:message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(callback != nil) callback(message, error);
                });
            }];
        }
    }];
}

//+(NSMutableDictionary *)firebaseMessageFor:(ChatMessage *)message {
//    // firebase message dictionary
//    NSMutableDictionary *message_dict = [[NSMutableDictionary alloc] init];
//    // always
//    [message_dict setObject:message.text forKey:MSG_FIELD_TEXT];
//    [message_dict setObject:message.channel_type forKey:MSG_FIELD_CHANNEL_TYPE];
//    if (message.senderFullname) {
//        [message_dict setObject:message.senderFullname forKey:MSG_FIELD_SENDER_FULLNAME];
//    }
//
//    if (message.subtype) {
//        [message_dict setObject:message.subtype forKey:MSG_FIELD_SUBTYPE];
//    }
//
//    if (message.recipientFullName) {
//        [message_dict setObject:message.recipientFullName forKey:MSG_FIELD_RECIPIENT_FULLNAME];
//    }
//
//    if (message.mtype) {
//        [message_dict setObject:message.mtype forKey:MSG_FIELD_TYPE];
//    }
//
//    if (message.attributes) {
//        [message_dict setObject:message.attributes forKey:MSG_FIELD_ATTRIBUTES];
//    }
//
//    if (message.imageMetadata) {
//        [message_dict setObject:message.imageMetadata forKey:MSG_FIELD_ATTRIBUTES];
//    }
//
//    if (message.lang) {
//        [message_dict setObject:message.lang forKey:MSG_FIELD_LANG];
//    }
//    return message_dict;
//}

// Updates a just-sent memory-message with the new status: MSG_STATUS_FAILED or MSG_STATUS_SENT

-(void)updateMessageStatusInMemorySynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(void))callback {
    dispatch_async(serialMessagesMemoryQueue, ^{
        ChatMessage *message = [self findMessageInMemoryById:messageId];
        message.status = status;
        if (callback != nil) callback();
    });
}

//-(void)updateMessageStatusInMemory:(NSString *)messageId withStatus:(int)status {
//    ChatMessage *message = [self findMessageInMemoryById:messageId];
//    message.status = status;
//}

-(void)updateMessageInMemory:(NSString *)messageId status:(int)status text:(NSString *)text imageURL:(NSString *)imageURL {
    ChatMessage *m = [self findMessageInMemoryById:messageId];
    m.status = status;
    m.text = text;
    m.metadata.src = imageURL;
}

-(ChatMessage *)findMessageInMemoryById:(NSString *)messageId {
    for (ChatMessage* msg in self.messages) {
        if([msg.messageId isEqualToString: messageId]) {
            return msg;
        }
    }
    return nil;
}

-(void)updateMessageStatusSynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(void))callback {
    [[ChatDB getSharedInstance] updateMessageSynchronized:messageId withStatus:status completion:^{
        [self updateMessageStatusInMemorySynchronized:messageId withStatus:status completion:^{
            if (callback != nil) callback();
        }];
    }];
}

//-(void)insertMessageOnDBIfNotExists:(ChatMessage *)message {
//    [[ChatDB getSharedInstance] insertMessageIfNotExists:message];
//}

-(void)insertMessageInMemoryIfNotExists:(ChatMessage *)message completion:(void(^)(void))callback {
    dispatch_async(serialMessagesMemoryQueue, ^{
        // find message...
        BOOL found = NO;
        for (ChatMessage* msg in self.messages) {
            if([msg.messageId isEqualToString: message.messageId]) {
                NSLog(@"message found, skipping insert");
                found = YES;
                break;
            }
        }
        
        if (found) {
            return;
        }
        else {
            NSUInteger newIndex = [self.messages indexOfObject:message
                                         inSortedRange:(NSRange){0, [self.messages count]}
                                               options:NSBinarySearchingInsertionIndex
                                               usingComparator:^NSComparisonResult(id a, id b) {
                                                   NSDate *first = [(ChatMessage *)a date];
                                                   NSDate *second = [(ChatMessage *)b date];
                                                   return [first compare:second];
                                               }];
            [self.messages insertObject:message atIndex:newIndex];
        }
        if (callback != nil) callback();
    });
}

-(void)uploadImage:(UIImage *)image fileName:(NSString *)fileName completion:(void(^)(NSURL *downloadURL, NSError *error))callback progressCallback:(void(^)(double fraction))progressCallback {
    NSData *data = UIImagePNGRepresentation(image);
    // Get a reference to the storage service using the default Firebase App
    FIRStorage *storage = [FIRStorage storage];
    // Create a root reference
    FIRStorageReference *storageRef = [storage reference];
    NSString * uuid = [[NSUUID UUID] UUIDString];
    NSString *file_path = [[NSString alloc] initWithFormat:@"images/%@.png", uuid];
    NSLog(@"image remote file path: %@", file_path);
    // Create a reference to the file you want to upload
    FIRStorageReference *storeRef = [storageRef child:file_path];
    // Create file metadata including the content type
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/png";
    // Upload the file to the path
    FIRStorageUploadTask *uploadTask = [storeRef putData:data
                                                 metadata:metadata
                                               completion:^(FIRStorageMetadata *metadata,
                                                            NSError *error) {
                                                   if (error != nil) {
                                                       NSLog(@"an error occurred!");
                                                       callback(nil, error);
                                                   } else {
                                                       NSLog(@"Metadata contains file metadata such as size, content-type, and download URL");
                                                       
                                                       [storeRef downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                                                           if (error != nil) {
                                                               NSLog(@"an error occurred! %@", error);
                                                               callback(nil, error);
                                                           } else {
                                                               NSLog(@"Download url: %@", URL);
                                                               callback(URL, error);
                                                           }
                                                       }];

                                                       
                                                   }
                                               }];
//    FIRStorageHandle observer =
    [uploadTask observeStatus:FIRStorageTaskStatusProgress
                                                  handler:^(FIRStorageTaskSnapshot *snapshot) {
//                                                      NSLog(@"uploading %@", snapshot);
//                                                      NSLog(@"completion: %f, %lld", snapshot.progress.fractionCompleted, snapshot.progress.completedUnitCount);
                                                      progressCallback(snapshot.progress.fractionCompleted);
                                                  }];
}

//-(void)finishedReceivingMessage:(ChatMessage *)message {
//    NSLog(@"ConversationHandler: Finished receiving message %@ on delegate: %@",message.text, self.delegateView);
//    if (self.delegateView) {
//        [self.delegateView finishedReceivingMessage:message];
//    }
//}

// observer

-(void)notifyEvent:(ChatMessageEventType)event message:(ChatMessage *)message {
    if (!self.eventObservers) {
        return;
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(event)];
    if (!eventCallbacks) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSNumber *event_handle_key in eventCallbacks.allKeys) {
            void (^callback)(ChatMessage *message) = [eventCallbacks objectForKey:event_handle_key];
            callback(message);
        }
    });
}

// v2

-(NSUInteger)observeEvent:(ChatMessageEventType)eventType withCallback:(void (^)(ChatMessage *message))callback {
    if (!self.eventObservers) {
        self.eventObservers = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(eventType)];
    if (!eventCallbacks) {
        eventCallbacks = [[NSMutableDictionary alloc] init];
        [self.eventObservers setObject:eventCallbacks forKey:@(eventType)];
    }
    NSUInteger callback_handle = (NSUInteger) OSAtomicIncrement64Barrier(&_lastEventHandle);
    [eventCallbacks setObject:callback forKey:@(callback_handle)];
    return callback_handle;
}

-(void)removeObserverWithHandle:(NSUInteger)event_handle {
    if (!self.eventObservers) {
        return;
    }
    
//    // test
//    for (NSNumber *event_key in self.eventObservers) {
//        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
//        NSLog(@"Removing callback for event %@. Callback: %@",event_key, [eventCallbacks objectForKey:@(event_handler)]);
//    }
    
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeObjectForKey:@(event_handle)];
    }
    
//    for (NSNumber *event_key in self.eventObservers) {
//        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
//        NSLog(@"After removed callback for event %@. Callback: %@",event_key, [eventCallbacks objectForKey:@(event_handler)]);
//    }
}

-(void)removeAllObservers {
    if (!self.eventObservers) {
        return;
    }
    
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeAllObjects];
    }
}

+(NSString *)mediaFolderPathOfRecipient:(NSString *)recipiendId {
    // path: chatConversationsMedia/{recipient-id}/media/{image-name}
    NSURL *urlPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *mediaPath = [[[urlPath.path stringByAppendingPathComponent:@"chatConversationsMedia"] stringByAppendingPathComponent:recipiendId] stringByAppendingPathComponent:@"media"];
    return mediaPath;
}

-(NSString *)mediaFolderPath {
    return [ChatConversationHandler mediaFolderPathOfRecipient:self.recipientId];
}

-(void)saveImageToRecipientMediaFolderAsPNG:(UIImage *)image imageFileName:(NSString *)imageFileName {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *mediaPath = [self mediaFolderPath];
    if (![filemgr fileExistsAtPath:mediaPath]) {
        NSError *error;
        [filemgr createDirectoryAtPath:mediaPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"error creating mediaPath folder (%@): %@",mediaPath, error);
        }
    }
    NSString *imagePath = [mediaPath stringByAppendingPathComponent:imageFileName];
    NSLog(@"Image path: %@", imagePath);
    NSError *error;
    [UIImagePNGRepresentation(image) writeToFile:imagePath options:NSDataWritingAtomic error:&error];
    NSLog(@"error saving image to media path (%@): %@",imagePath, error);
    // test
    if ([filemgr fileExistsAtPath: imagePath ] == NO) {
        NSLog(@"Error. Image not saved.");
    }
    else {
        NSLog(@"Image saved to gallery.");
    }
    NSArray *directoryList = [filemgr contentsOfDirectoryAtPath:mediaPath error:nil];
    for (id file in directoryList) {
        NSLog(@"file: %@", file);
    }
}

@end
