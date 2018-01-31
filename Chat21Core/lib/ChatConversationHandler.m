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

@implementation ChatConversationHandler

-(id)init {
    if (self = [super init]) {
        self.lastEventHandle = 1;
    }
    return self;
}

-(id)initWithRecipient:(NSString *)recipientId recipientFullName:(NSString *)recipientFullName {
    if (self = [super init]) {
        self.lastEventHandle = 1;
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
        self.lastEventHandle = 1;
//        self.groupId = groupId;
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

//// ChatGroupsDelegate delegate
//-(void)groupAddedOrChanged:(ChatGroup *)group {
//    NSLog(@"Group added or changed delegate. Group name: %@", group.name);
//    if (![group.groupId isEqualToString:self.groupId]) {
//        return;
//    }
//    if ([group isMember:self.user.userId]) {
//        [self connect];
//        [self.delegateView groupConfigurationChanged:group];
//    }
//    else {
//        [self dispose];
//        [self.delegateView groupConfigurationChanged:group];
//    }
//}

-(void)dispose {
    [self.messagesRef removeAllObservers];
    [self removeAllObservers];
    self.messages_ref_handle = 0;
    self.updated_messages_ref_handle = 0;
}

-(void)restoreMessagesFromDB {
    NSLog(@"RESTORING ALL MESSAGES FOR CONVERSATION %@", self.conversationId);
    NSArray *inverted_messages = [[[ChatDB getSharedInstance] getAllMessagesForConversation:self.conversationId start:0 count:40] mutableCopy];
    NSLog(@"DB MESSAGES NUMBER: %lu", (unsigned long) inverted_messages.count);
    NSLog(@"Last 40 messages restored...");
    NSEnumerator *enumerator = [inverted_messages reverseObjectEnumerator];
    for (id element in enumerator) {
        [self.messages addObject:element];
    }
    
    // set as status:"failed" all the messages in status: "sending"
    for (ChatMessage *m in self.messages) {
        if (m.status == MSG_STATUS_SENDING) {
            m.status = MSG_STATUS_FAILED;
        }
    }
}

//-(void)updateMemoryFromDB {
//    NSLog(@"UPDATE DB > MEMORY ALL MESSAGES FOR CONVERSATION %@", self.conversationId);
//    int count = (int) self.messages.count + 1;
//    [self.messages removeAllObjects];
//    NSArray *inverted_messages = [[[ChatDB getSharedInstance] getAllMessagesForConversation:self.conversationId start:0 count:count] mutableCopy];
//    NSLog(@"DB MESSAGES NUMBER: %lu", (unsigned long) inverted_messages.count);
//    NSLog(@"Last %d messages restored...", count);
//    NSLog(@"Reversing array...");
//    NSEnumerator *enumerator = [inverted_messages reverseObjectEnumerator];
//    for (id element in enumerator) {
//        [self.messages addObject:element];
//    }
//}

//-(void)firebaseLogin {
//    SHPFirebaseTokenDC *dc = [[SHPFirebaseTokenDC alloc] init];
//    dc.delegate = self;
//    [dc getTokenWithParameters:nil withUser:self.user];
//}

//-(void)didFinishFirebaseAuthWithToken:(NSString *)token error:(NSError *)error {
//    if (token) {
//        NSLog(@"Auth Firebase ok. Token: %@", token);
//        self.firebaseToken = token;
//        [self setupConversation];
//    } else {
//        NSLog(@"Auth Firebase error: %@", error);
//    }
//    [self.delegateView didFinishInitConversationHandler:self error:error];
//}

-(void)connect {
    // if already connected return
    if (self.messages_ref_handle) {
        return;
    }
    
    NSLog(@"Setting up references' connections with firebase using token: %@", self.firebaseToken);
    if (self.messages_ref_handle) {
        NSLog(@"Trying to re-open messages_ref_handle %ld while already open. Returning.", self.messages_ref_handle);
        return;
    }
    self.messagesRef = [ChatUtil conversationMessagesRef:self.recipientId];
    self.conversationOnSenderRef = [ChatUtil conversationRefForUser:self.senderId conversationId:self.conversationId];
    self.conversationOnReceiverRef = [ChatUtil conversationRefForUser:self.recipientId conversationId:self.conversationId];
    
    NSInteger lasttime = 0;
    if (self.messages && self.messages.count > 0) {
        ChatMessage *message = [self.messages lastObject];
        NSLog(@"****** MOST RECENT MESSAGE TIME %@ %@", message, message.date);
        lasttime = message.date.timeIntervalSince1970 * 1000; // objc return time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. * 1000 translates seconds in millis and the query is ok.
    } else {
        lasttime = 0;
    }
    
    self.messages_ref_handle = [[[self.messagesRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        // IMPORTANT: this query ignores messages without a timestamp.
        // IMPORTANT: This callback is called also for newly locally created messages not still sent.
//        NSLog(@"NEW MESSAGE SNAPSHOT: %@", snapshot);
        if (![self isValidMessageSnapshot:snapshot]) {
            NSLog(@"Discarding invalid snapshot: %@", snapshot);
            return;
        } else {
//            NSLog(@"Snapshot valid.");
        }
        ChatMessage *message = [ChatMessage messageFromSnapshotFactory:snapshot];
        message.conversationId = self.conversationId; // DB query is based on this attribute!!! (conversationID = Recipient)
        
        // IMPORTANT (REPEATED)! This callback is called ALSO (and NOT ONLY) for newly locally created messages not still sent (called also with network off!).
        // Then, for every "new" message received (also locally generated) we update the conversation data & his status to "read" (is_new: NO).
        
        // updates status only of messages not sent by me
        // HO RICEVUTO UN MESSAGGIO NUOVO
//        NSLog(@"self.senderId: %@", self.senderId);
        if (message.status < MSG_STATUS_RECEIVED && ![message.sender isEqualToString:self.senderId]) { // CONTROLLO "message.status < MSG_STATUS_RECEIVED" IN MODO DA EVITARE IL COSTO DI RI-AGGIORNARE CONTINUAMENTE LO STATO DI MESSAGGI CHE HANNO GIA LO STATO RECEIVED (MAGARI E' LA SINCRONIZZAZIONE DI UN NUOVO DISPOSITIVO CHE NON DEVE PIU' COMUNICARE NULLA AL MITTENTE MA SOLO SCARICARE I MESSAGGI NELLO STATO IN CUI SI TROVANO).
            // NOT RECEIVED = NEW!
//            NSLog(@"NEW MESSAGE!!!!! %@ group %@", message.text, message.recipientGroupId);
//            if (!message.recipientGroupId) {
            if (message.isDirect) {
                [message updateStatusOnFirebase:MSG_STATUS_RECEIVED]; // firebase
            } else {
                // TODO: implement received status for group's messages
            }
        }
        // updates or insert new messages
        // Note: we always got the last message sent. So this check is necessary to avoid this notified as new (...playing sound etc.)
        ChatMessage *message_archived = [[ChatDB getSharedInstance] getMessageById:message.messageId];
        if (!message_archived) {
            [self insertMessageInMemory:message]; // memory
            [self insertMessageOnDBIfNotExists:message];
            [self notifyEvent:ChatEventMessageAdded message:message];
        }
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
//    self.updated_messages_ref_handle = [[self.messagesRef queryLimitedToLast:10] observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
//        NSLog(@">>>> new UPDATED message snapshot %@", snapshot);
//    } withCancelBlock:^(NSError *error) {
//        NSLog(@"%@", error.description);
//    }];
    
    self.updated_messages_ref_handle = [self.messagesRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"UPDATED MESSAGE SNAPSHOT: %@", snapshot);
        if (![self isValidMessageSnapshot:snapshot]) {
            NSLog(@"Discarding invalid snapshot: %@", snapshot);
            return;
        } else {
//            NSLog(@"Snapshot valid.");
        }
        ChatMessage *message = [ChatMessage messageFromSnapshotFactory:snapshot];
        if (message.status == MSG_STATUS_SENDING) {
            NSLog(@"Queed message updated. Data saved successfully.");
            int status = MSG_STATUS_SENT;
            [self updateMessageStatusInMemory:message.messageId withStatus:status];
            [self updateMessageStatusOnDB:message.messageId withStatus:status];
//            [self finishedReceivingMessage:message];
            [self notifyEvent:ChatEventMessageChanged message:message];
        } else if (message.status == MSG_STATUS_RETURN_RECEIPT) {
            NSLog(@"Message update: return receipt.");
            [self updateMessageStatusInMemory:message.messageId withStatus:message.status];
            [self updateMessageStatusOnDB:message.messageId withStatus:message.status];
            [self notifyEvent:ChatEventMessageChanged message:message];
//            [self finishedReceivingMessage:message];
//            [self sendReadNotificationForMessage:message];
        }
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(BOOL)isValidMessageSnapshot:(FIRDataSnapshot *)snapshot {
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

//-(void) initFirebaseWithRef:(FIRDatabaseReference *)ref token:(NSString *)token {
//    self.authHelper = [[FirebaseCustomAuthHelper alloc] initWithFirebaseRef:ref token:token];
//    NSLog(@"ok111");
//    [self.authHelper authenticate:^(NSError *error, FAuthData *authData) {
//        NSLog(@"authData: %@", authData);
//        if (error != nil) {
//            NSLog(@"There was an error authenticating.");
//        } else {
//            NSLog(@"authentication success %@", authData);
//        }
//    }];
//}

//-(void)sendReadNotificationForMessage:(ChatMessage *)message {
//    double now = [[NSDate alloc] init].timeIntervalSince1970;
//    if (now - self.lastSentReadNotificationTime < 10) {
//        NSLog(@"TOO EARLY TO SEND A NOTIFICATION FOR THIS MESSAGE: %@", message.text);
//        return;
//    }
//    NSLog(@"SENDING READ NOTIFICATION TO: %@ FOR MESSAGE: %@", message.sender, message.text);
//    // PARSE NOTIFICATION
//    ParseChatNotification *notification = [[ParseChatNotification alloc] init];
//    notification.senderUser = self.user.userId; //[self.user.username stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//    notification.senderUserFullname = self.user.fullname;
//    notification.toUser = message.sender;
//    notification.alert = [[NSString alloc] initWithFormat:@"%@ ha ricevuto il messaggio", message.recipient];
//    notification.conversationId = message.conversationId;
//    notification.badge = @"-1";
//    ChatParsePushService *push_service = [[ChatParsePushService alloc] init];
//    [push_service sendNotification:notification];
//    // END PARSE NOTIFICATION
//    self.lastSentReadNotificationTime = now;
//}

-(ChatMessage *)newBaseMessage {
    ChatMessage *message = [[ChatMessage alloc] init];
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

-(void)sendMessageWithText:(NSString *)text type:(NSString *)type attributes:(NSDictionary *)attributes {
    ChatMessage *message = [self newBaseMessage];
    if (text) {
        message.text = text;
    }
    message.mtype = type;
    message.attributes = attributes;
//    if (self.groupId) {
    if ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
        NSLog(@"SENDING MESSAGE IN GROUP MODE. User: %@", [FIRAuth auth].currentUser.uid);
//        message.recipientGroupId = self.groupId;
        message.channel_type = MSG_CHANNEL_TYPE_GROUP;
        message.recipient = self.recipientId;
        message.recipientFullName = self.recipientFullname;
        [self sendMessageToGroup:message];
    } else {
        NSLog(@"SENDING MESSAGE DIRECT MODE. User: %@", [FIRAuth auth].currentUser.uid);
        message.channel_type = MSG_CHANNEL_TYPE_DIRECT;
        message.recipient = self.recipientId;
        message.recipientFullName = self.recipientFullname;
        [self sendDirect:message];
    }
}

-(void)sendMessage:(NSString *)text {
    [self sendMessageWithText:text type:MSG_TYPE_TEXT attributes:nil];
}

-(void)sendDirect:(ChatMessage *)message {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef childByAutoId]; // CHILD'S AUTOGEN UNIQUE ID
    message.messageId = messageRef.key;
    
    // save message locally
    [self insertMessageInMemory:message];
    [self insertMessageOnDBIfNotExists:message];
    [self notifyEvent:ChatEventMessageAdded message:message];
    
    // save message to firebase
    NSMutableDictionary *message_dict = [ChatConversationHandler firebaseMessageFor:message];
    NSLog(@"Sending message to Firebase: %@ %@ %d", message.text, message.messageId, message.status);
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"messageRef.setValue callback. %@", message_dict);
        if (error) {
            NSLog(@"Data could not be saved because of an occurred error: %@", error);
            int status = MSG_STATUS_FAILED;
            [self updateMessageStatusInMemory:ref.key withStatus:status];
            [self updateMessageStatusOnDB:message.messageId withStatus:status];
            [self notifyEvent:ChatEventMessageChanged message:message];
        } else {
            NSLog(@"Data saved successfully. Updating status & reloading tableView.");
            int status = MSG_STATUS_SENT;
            NSAssert([ref.key isEqualToString:message.messageId], @"REF.KEY %@ different by MESSAGE.ID %@",ref.key, message.messageId);
            [self updateMessageStatusInMemory:message.messageId withStatus:status];
            [self updateMessageStatusOnDB:message.messageId withStatus:status];
            [self notifyEvent:ChatEventMessageChanged message:message];
        }
    }];
}

-(void)sendMessageToGroup:(ChatMessage *)message {
    // create firebase reference
    FIRDatabaseReference *messageRef = [self.messagesRef childByAutoId]; // CHILD'S AUTOGEN UNIQUE ID
    message.messageId = messageRef.key;
    // save message locally
    [self insertMessageInMemory:message];
    [self insertMessageOnDBIfNotExists:message];
    [self notifyEvent:ChatEventMessageAdded message:message];
    // save message to firebase
    NSMutableDictionary *message_dict = [ChatConversationHandler firebaseMessageFor:message];
    NSLog(@"(Group) Sending message to Firebase:(%@) %@ %@ %d dict: %@",messageRef, message.text, message.messageId, message.status, message_dict);
    [messageRef setValue:message_dict withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSLog(@"messageRef.setValue callback. %@", message_dict);
        if (error) {
            NSLog(@"Data could not be saved with error: %@", error);
            int status = MSG_STATUS_FAILED;
            [self updateMessageStatusInMemory:ref.key withStatus:status];
            [self updateMessageStatusOnDB:message.messageId withStatus:status];
            [self notifyEvent:ChatEventMessageChanged message:message];
        } else {
            NSLog(@"Data saved successfully. Updating status & reloading tableView.");
            int status = MSG_STATUS_SENT;
            [self updateMessageStatusInMemory:ref.key withStatus:status];
            [self updateMessageStatusOnDB:message.messageId withStatus:status];
            [self notifyEvent:ChatEventMessageChanged message:message];
            
//            ChatGroup *group = [[ChatManager getInstance] groupById:self.groupId];
//
//            NSLog(@"Updating conversations of group's members...");
//
//            // updates conversations
//
//            // Sender-side conversation
//            ChatManager *chat = [ChatManager getInstance];
//
//            ChatConversation *senderConversation = [[ChatConversation alloc] init];
//            senderConversation.ref = self.conversationOnSenderRef;
//            senderConversation.last_message_text = message.text;
//            senderConversation.is_new = NO;
//            senderConversation.date = message.date;
//            senderConversation.sender = message.sender;
//            senderConversation.senderFullname = message.senderFullname;
//            senderConversation.groupName = group.name;
//            senderConversation.groupId = group.groupId;
//            senderConversation.status = CONV_STATUS_LAST_MESSAGE;
//
//            [chat createOrUpdateConversation:senderConversation];
//
//            // Recipient-side: the conversation is new. It becomes !new immediately after the "tap" in recipent-side's converations-list.
//            NSLog(@"AGGIORNO LA CONVERSAZIONE DEI MEMBRI RICEVENTI CON IS_NEW = SI");
//
//            for (NSString *memberId in group.members) {
//                NSLog(@"AGGIORNO CONVERSAZIONE DI %@", memberId);
//                FIRDatabaseReference *conversationOnMember = [ChatUtil conversationRefForUser:memberId conversationId:self.conversationId];
//
//                ChatConversation *memberConversation = [[ChatConversation alloc] init];
//                memberConversation.ref = conversationOnMember;
//                memberConversation.last_message_text = message.text;
//                memberConversation.is_new = YES;
//                memberConversation.date = message.date;
//                memberConversation.sender = message.sender;
//                memberConversation.senderFullname = message.senderFullname;
//                memberConversation.groupName = self.groupName;
//                memberConversation.groupId = self.groupId;
//                memberConversation.status = CONV_STATUS_LAST_MESSAGE;
//
//                [chat createOrUpdateConversation:memberConversation];
//            }
//            NSLog(@"Finished updating group conversations...");
        }
    }];
}

+(NSMutableDictionary *)firebaseMessageFor:(ChatMessage *)message {
    // firebase message dictionary
    NSMutableDictionary *message_dict = [[NSMutableDictionary alloc] init];
//    NSNumber *msg_timestamp = [NSNumber numberWithDouble:[message.date timeIntervalSince1970]];
    // always
//    [message_dict setObject:message.conversationId forKey:MSG_FIELD_CONVERSATION_ID];
    [message_dict setObject:message.text forKey:MSG_FIELD_TEXT];
    [message_dict setObject:message.channel_type forKey:MSG_FIELD_CHANNEL_TYPE];
//    [message_dict setObject:[FIRServerValue timestamp] forKey:MSG_FIELD_TIMESTAMP];
//    [message_dict setObject:[NSNumber numberWithInt:message.status] forKey:MSG_FIELD_STATUS];
    
//    if (message.sender) {
//        NSString *sanitezed_sender = [message.sender stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//        [message_dict setObject:sanitezed_sender forKey:MSG_FIELD_SENDER];
//    }
    
    if (message.senderFullname) {
        [message_dict setObject:message.senderFullname forKey:MSG_FIELD_SENDER_FULLNAME];
    }
    
    if (message.recipientFullName) {
        [message_dict setObject:message.recipientFullName forKey:MSG_FIELD_RECIPIENT_FULLNAME];
    }
    
    if (message.mtype) {
        [message_dict setObject:message.mtype forKey:MSG_FIELD_TYPE];
    }
    
    if (message.attributes) {
        [message_dict setObject:message.attributes forKey:MSG_FIELD_ATTRIBUTES];
    }
    
    if (message.lang) {
        [message_dict setObject:message.lang forKey:MSG_FIELD_LANG];
    }
    
    // only if one-to-one
//    if (message.recipient) {
//        NSString *sanitezed_recipient = [message.recipient stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//        [message_dict setValue:sanitezed_recipient forKey:MSG_FIELD_RECIPIENT];
//    }
    
    // only if group
//    if (message.recipientGroupId) {
//        [message_dict setValue:message.recipientGroupId forKey:MSG_FIELD_RECIPIENT_GROUP_ID];
//    }
    return message_dict;
}

// Updates a just-sent memory-message with the new status: MSG_STATUS_FAILED or MSG_STATUS_SENT
-(void)updateMessageStatusInMemory:(NSString *)messageId withStatus:(int)status {
    for (ChatMessage* msg in self.messages) {
        if([msg.messageId isEqualToString: messageId]) {
            NSLog(@"message found, updating status %d", status);
            msg.status = status;
            break;
        }
    }
}

-(void)updateMessageStatusOnDB:(NSString *)messageId withStatus:(int)status {
    [[ChatDB getSharedInstance] updateMessage:messageId withStatus:status];
}

-(void)insertMessageOnDBIfNotExists:(ChatMessage *)message {
    [[ChatDB getSharedInstance] insertMessageIfNotExists:message];
}

-(void)insertMessageInMemory:(ChatMessage *)message {
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
}

//-(void)finishedReceivingMessage:(ChatMessage *)message {
//    NSLog(@"ConversationHandler: Finished receiving message %@ on delegate: %@",message.text, self.delegateView);
//    if (self.delegateView) {
//        [self.delegateView finishedReceivingMessage:message];
//    }
//}

// observer

//-(void)addSubcriber:(id<ChatConversationSubscriber>)subscriber {
//    if (!self.subcribers) {
//        self.subcribers = [[NSMutableArray alloc] init];
//    }
//    [self.subcribers addObject:subscriber];
//}
//
//-(void)removeSubcriber:(id<ChatConversationSubscriber>)subscriber {
//    if (!self.subcribers) {
//        return;
//    }
//    [self.subcribers removeObject:subscriber];
//}

-(void)notifyEvent:(ChatMessageEventType)event message:(ChatMessage *)message {
//    for (id<ChatConversationSubscriber> subscriber in self.subcribers) {
//        [subscriber messageAdded:message];
//    }
    if (!self.eventObservers) {
        return;
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(event)];
    if (!eventCallbacks) {
        return;
    }
    for (NSNumber *event_handle_key in eventCallbacks.allKeys) {
        void (^callback)(ChatMessage *message) = [eventCallbacks objectForKey:event_handle_key];
        callback(message);
    }
}

//-(void)notifySubscribersMessageChanged:(ChatMessage *)message {
//    for (id<ChatConversationSubscriber> subscriber in self.subcribers) {
//        [subscriber messageChanged:message];
//    }
//}

//-(void)notifySubscribersMessageDeleted:(ChatMessage *)message {
//    for (id<ChatConversationSubscriber> subscriber in self.subcribers) {
//        [subscriber messageDeleted:message];
//    }
//}

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

@end
