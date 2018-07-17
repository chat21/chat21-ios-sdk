//
//  ChatConversationsHandler.m
//  Soleto
//
//  Created by Andrea Sponziello on 29/12/14.
//
//

#import "ChatConversationsHandler.h"
#import "ChatUtil.h"
#import "ChatConversation.h"
//#import "SHPConversationsViewDelegate.h"
#import "ChatDB.h"
#import "ChatManager.h"
#import "ChatUser.h"
#import <libkern/OSAtomic.h>

@implementation ChatConversationsHandler

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user {
    if (self = [super init]) {
//        self.lastEventHandler = 1;
        //        self.firebaseRef = firebaseRef;
        self.rootRef = [[FIRDatabase database] reference];
        self.tenant = tenant;
        self.loggeduser = user;
        self.me = user.userId;
        self.conversations = [[NSMutableArray alloc] init];
        self.archivedConversations = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dispose {
    [self.conversationsRef removeAllObservers];
    [self.archivedConversationsRef removeAllObservers];
    [self removeAllObservers];
    self.conversations_ref_handle_added = 0;
    self.conversations_ref_handle_changed = 0;
    self.conversations_ref_handle_removed = 0;
}

-(void)printAllConversations {
    NSLog(@"***** CONVERSATIONS DUMP **************************");
    NSMutableArray *conversations = [[[ChatDB getSharedInstance] getAllConversations] mutableCopy];
    for (ChatConversation *c in conversations) {
        NSLog(@"id: %@, user: %@ date: %@",c.conversationId, c.user, c.date);
    }
    NSLog(@"******************************* END.");
}

-(void)restoreConversationsFromDB {
    self.conversations = [[[ChatDB getSharedInstance] getAllConversationsForUser:self.me archived:NO limit:0] mutableCopy];
    for (ChatConversation *c in self.conversations) {
        if (c.conversationId) {
            FIRDatabaseReference *conversation_ref = [self.conversationsRef child:c.conversationId];
            c.ref = conversation_ref;
        }
    }
    
    self.archivedConversations = [[[ChatDB getSharedInstance] getAllConversationsForUser:self.me archived:YES limit:150] mutableCopy];
    for (ChatConversation *c in self.archivedConversations) {
        if (c.conversationId) {
            FIRDatabaseReference *conversation_ref = [self.archivedConversationsRef child:c.conversationId];
            c.ref = conversation_ref;
        }
    }
}

//-(NSMutableArray *)restoreArchivedConversationsFromDB {
//    self.archivedConversations = [[[ChatDB getSharedInstance] getAllArchivedConversationsForUser:self.me] mutableCopy];
//    for (ChatConversation *c in self.archivedConversations) {
//        if (c.conversationId) {
//            FIRDatabaseReference *conversation_ref = [self.archivedConversationsRef child:c.conversationId];
//            c.ref = conversation_ref;
//        }
//    }
//    return self.archivedConversations;
//}

-(void)connect {
    [self connect_conversations];
    [self connect_archived_conversations];
}

-(void)connect_conversations {
    // if already connected, return.
    if (self.conversations_ref_handle_added) {
        return;
    }
    ChatManager *chat = [ChatManager getInstance];
    NSString *conversations_path = [ChatUtil conversationsPathForUserId:self.loggeduser.userId];
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    self.conversationsRef = [rootRef child: conversations_path];
    [self.conversationsRef keepSynced:YES];
    
    // TEST
    [self printAllConversations];
    
    NSInteger lasttime = 0;
    NSMutableArray *conversations = self.conversations;
    if (conversations && conversations.count > 0) {
        ChatConversation *conversation = [conversations firstObject];
        lasttime = conversation.date.timeIntervalSince1970 * 1000; // objc return time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. * 1000 translates seconds in millis and the query is ok.
    } else {
        lasttime = 0;
    }
    
    self.conversations_ref_handle_added = [[[self.conversationsRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"NEW CONVERSATION SNAPSHOT: %@", snapshot);
        if (![self isValidConversationSnapshot:snapshot]) {
            NSLog(@"Invalid conversation snapshot, discarding.");
            return;
        }
        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
        if ([self.currentOpenConversationId isEqualToString:conversation.conversationId] && conversation.is_new == YES) {
            // changes (forces) the "is_new" flag to FALSE;
            conversation.is_new = NO;
            FIRDatabaseReference *conversation_ref = [self.conversationsRef child:conversation.conversationId];
            NSLog(@"UPDATING IS_NEW=NO FOR CONVERSATION %@", conversation_ref);
            [chat updateConversationIsNew:conversation_ref is_new:conversation.is_new];
        }
        if (conversation.status == CONV_STATUS_FAILED) {
            // a remote conversation can't be in failed status. force to last_message status
            // if the sender WRONGLY set the conversation STATUS to 0 this will block the access to the conversation.
            // IN FUTURE SERVER-SIDE HANDLING OF MESSAGE SENDING, WILL BE THE SERVER-SIDE SCRIPT RESPONSIBLE OF SETTING THE CONV STATUS AND THIS VERIFICATION CAN BE REMOVED.
            conversation.status = CONV_STATUS_LAST_MESSAGE;
        }
        conversation.archived = NO;
        [self insertConversationInMemory:conversation];
        [self insertOrUpdateConversationOnDB:conversation];
        [self notifyEvent:ChatEventConversationAdded conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    self.conversations_ref_handle_changed =
    [self.conversationsRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"CHANGED CONVERSATION snapshot............... %@", snapshot);
        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
        if ([self.currentOpenConversationId isEqualToString:conversation.conversationId] && conversation.is_new == YES) {
            // changes (forces) the "is_new" flag to FALSE;
            conversation.is_new = NO;
            FIRDatabaseReference *conversation_ref = [self.conversationsRef child:conversation.conversationId];
            NSLog(@"UPDATING IS_NEW=NO FOR CONVERSATION %@", conversation_ref);
            [chat updateConversationIsNew:conversation_ref is_new:conversation.is_new];
        }
        conversation.archived = NO;
        [self updateConversationInMemory:conversation];
        [self insertOrUpdateConversationOnDB:conversation];
        NSDictionary *found_conversation_values = [self findConversationInMemoryById:conversation.conversationId];
        ChatConversation *found_conversation = found_conversation_values[@"conversation"];
        int found_index = ((NSNumber *) found_conversation_values[@"index"]).intValue;
        conversation.indexInMemory = found_index;
        if ([conversation.date isEqualToDate:found_conversation.date]) {
            [self notifyEvent:ChatEventConversationReadStatusChanged conversation:conversation];
        }
        else {
            [self notifyEvent:ChatEventConversationChanged conversation:conversation];
        }
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    self.conversations_ref_handle_removed =
    [self.conversationsRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"************************* CONVERSATION REMOVED ****************************");
        NSLog(@"REMOVED CONVERSATION snapshot............... %@", snapshot);
        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
        [self removeConversationInMemory:conversation];
        [self removeConversationOnDB:conversation];
        [self notifyEvent:ChatEventConversationDeleted conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(NSDictionary *)findConversationInMemoryById:(NSString *)conversationId {
    for (int i = 0; i < self.conversations.count; i++) {
        if ([self.conversations[i].conversationId isEqualToString:conversationId]) {
            
            return @{
                     @"conversation": self.conversations[i],
                     @"index": @(i)
                    };
        }
    }
    return nil;
}

-(void)connect_archived_conversations {
    // if already connected, return.
    if (self.archived_conversations_ref_handle_added) { //conversations_ref_handle_added) {
        return;
    }
    NSString *archived_conversations_path = [ChatUtil archivedConversationsPathForUserId:self.loggeduser.userId];
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    self.archivedConversationsRef = [rootRef child: archived_conversations_path];
    [self.archivedConversationsRef keepSynced:YES];

    NSInteger lasttime = 0;
    NSMutableArray *conversations = self.archivedConversations;
    if (conversations && conversations.count > 0) {
        ChatConversation *conversation = [conversations firstObject];
        lasttime = conversation.date.timeIntervalSince1970 * 1000; // objc return time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. * 1000 translates seconds in millis and the query is ok.
    } else {
        lasttime = 0;
    }
    
    self.archived_conversations_ref_handle_added = [[[self.archivedConversationsRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"NEW ARCHIVED CONVERSATION SNAPSHOT: %@", snapshot);
        if (![self isValidConversationSnapshot:snapshot]) {
            NSLog(@"Invalid conversation snapshot, discarding.");
            return;
        }
        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
        if (conversation.status == CONV_STATUS_FAILED) {
            // a remote conversation can't be in failed status. force to last_message status
            // if the sender WRONGLY set the conversation STATUS to 0 this will block the access to the conversation.
            // IN FUTURE SERVER-SIDE HANDLING OF MESSAGE SENDING, WILL BE THE SERVER-SIDE SCRIPT RESPONSIBLE OF SETTING THE CONV STATUS AND THIS VERIFICATION CAN BE REMOVED.
            conversation.status = CONV_STATUS_LAST_MESSAGE;
        }
        // TODO set conversation.archived = YES
        conversation.archived = YES;
        [self insertArchivedConversationInMemory:conversation];
        [self insertOrUpdateConversationOnDB:conversation];
        [self notifyEvent:ChatEventArchivedConversationAdded conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];

//    self.archived_conversations_ref_handle_removed =
//    [self.archivedConversationsRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
//        NSLog(@"************************* CONVERSATION REMOVED ****************************");
//        NSLog(@"REMOVED CONVERSATION snapshot............... %@", snapshot);
//        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
//        if ([self.currentOpenConversationId isEqualToString:conversation.conversationId] && conversation.is_new == YES) {
//            // changes (forces) the "is_new" flag to FALSE;
//            conversation.is_new = NO;
//            FIRDatabaseReference *conversation_ref = [self.archivedConversationsRef child:conversation.conversationId];
//            NSLog(@"UPDATING IS_NEW=NO FOR CONVERSATION %@", conversation_ref);
//            [chat updateConversationIsNew:conversation_ref is_new:conversation.is_new];
//        }
//        [self removeArchivedConversationInMemory:conversation];
//        [self removeArchivedConversationOnDB:conversation];
//    } withCancelBlock:^(NSError *error) {
//        NSLog(@"%@", error.description);
//    }];
}

-(BOOL)isValidConversationSnapshot:(FIRDataSnapshot *)snapshot {
    if (snapshot.value[CONV_RECIPIENT_KEY] == nil) {
        NSLog(@"CONV:RECIPIENT is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[CONV_LAST_MESSAGE_TEXT_KEY] == nil) {
        NSLog(@"CONV:TEXT is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[CONV_SENDER_KEY] == nil) {
        NSLog(@"CONV:SENDER is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[CONV_TIMESTAMP_KEY] == nil) {
        NSLog(@"MSG:TIMESTAMP is mandatory. Discarding message.");
        return NO;
    }
    else if (snapshot.value[CONV_STATUS_KEY] == nil) {
        NSLog(@"MSG:TIMESTAMP is mandatory. Discarding message.");
        return NO;
    }
    //    else if (snapshot.value[MSG_FIELD_STATUS] == nil) {
    //        NSLog(@"MSG:STATUS is mandatory. Discarding message.");
    //        return NO;
    //    }
    
    return YES;
}

-(void)insertConversationOnDBIfNotExists:(ChatMessage *)message {
    [[ChatDB getSharedInstance] insertMessageIfNotExists:message];
}

// MEMORY DB - CONVERSATIONS

-(void)insertConversationInMemory:(ChatConversation *)conversation {
    [self insertConversationInMemory:conversation fromConversations:self.conversations];
}

-(void)updateConversationInMemory:(ChatConversation *)conversation {
    [self updateConversationInMemory:conversation fromConversations:self.conversations];
}

-(int)removeConversationInMemory:(ChatConversation *)conversation {
    return [self removeConversationInMemory:conversation fromConversations:self.conversations];
}

// MEMORY DB - ARCHIVED-CONVERSATIONS

-(void)insertArchivedConversationInMemory:(ChatConversation *)conversation {
    [self insertConversationInMemory:conversation fromConversations:self.archivedConversations];
}

-(void)updateArchivedConversationInMemory:(ChatConversation *)conversation {
    [self updateConversationInMemory:conversation fromConversations:self.archivedConversations];
}

-(int)removeArchivedConversationInMemory:(ChatConversation *)conversation {
    return [self removeConversationInMemory:conversation fromConversations:self.archivedConversations];
}

// MEMORY DB

-(void)insertConversationInMemory:(ChatConversation *)conversation fromConversations:(NSMutableArray<ChatConversation *> *)conversations {
    BOOL found = NO;
    for (ChatConversation* conv in conversations) {
        if([conv.conversationId isEqualToString: conversation.conversationId]) {
            NSLog(@"conv found, skipping insert");
            found = YES;
            break;
        }
    }
    
    if (found) {
        return;
    }
    else {
        [conversations insertObject:conversation atIndex:0];
    }
}

-(void)updateConversationInMemory:(ChatConversation *)conversation fromConversations:(NSMutableArray<ChatConversation *> *)conversations {
    for (int i = 0; i < conversations.count; i++) {
        ChatConversation *conv = conversations[i];
        if([conv.conversationId isEqualToString: conversation.conversationId]) {
            NSLog(@"conv found, date new conv: %@, date old conv: %@", conversation.date, conv.date);
            if ([conv.date isEqualToDate:conversation.date]) {
                conversations[i] = conversation; // replace conversation in the same position
                return;
            }
            else {
                [conversations removeObjectAtIndex:i]; // remove conversation...
                [conversations insertObject:conversation atIndex:0]; // ...then put it on top
                return;
            }
        }
    }
}

-(int)removeConversationInMemory:(ChatConversation *)conversation fromConversations:(NSMutableArray<ChatConversation *> *)conversations {
    for (int i = 0; i < conversations.count; i++) {
        ChatConversation *conv = conversations[i];
        if([conv.conversationId isEqualToString: conversation.conversationId]) {
            [conversations removeObjectAtIndex:i];
            return i;
        }
    }
    return -1;
}

-(void)updateLocalConversation:(ChatConversation *)conversation {
    [self updateConversationInMemory:conversation];
    [self insertOrUpdateConversationOnDB:conversation];
}

-(int)removeLocalConversation:(ChatConversation *)conversation {
    [self removeConversationOnDB:conversation];
    return [self removeConversationInMemory:conversation];
}

//-(int)removeConversationFromMemory:(ChatConversation *)conversation {
//    for (int i = 0; i < self.conversations.count; i++) {
//        ChatConversation *conv = self.conversations[i];
//        if ([conv.conversationId isEqualToString: conversation.conversationId]) {
//            [self.conversations removeObjectAtIndex:i];
//            return i;
//        }
//    }
//    return -1;
//}

-(void)insertOrUpdateConversationOnDB:(ChatConversation *)conversation {
    conversation.user = self.me;
    [[ChatDB getSharedInstance] insertOrUpdateConversation:conversation];
}

-(void)removeConversationOnDB:(ChatConversation *)conversation {
    conversation.user = self.me;
    [[ChatDB getSharedInstance] removeConversation:conversation.conversationId];
}

//-(void)finishedReceivingConversation:(ChatConversation *)conversation {
//    NSLog(@"Finished receiving conversation %@ on delegate: %@",conversation.last_message_text, self.delegateView);
//    // callbackToSubscribers()
//    if (self.delegateView) {
//        [self.delegateView finishedReceivingConversation:conversation];
//    }
//}

//-(void)finishedRemovingConversation:(ChatConversation *)conversation {
//    NSLog(@"Finished removing conversation %@ on delegate: %@",conversation.last_message_text, self.delegateView);
//    // callbackToSubscribers()
//    if (self.delegateView) {
//        [self.delegateView finishedRemovingConversation:conversation];
//    }
//}

// observer

-(void)notifyEvent:(ChatConversationEventType)event conversation:(ChatConversation *)conversation {
    if (!self.eventObservers) {
        return;
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(event)];
    if (!eventCallbacks) {
        return;
    }
    for (NSNumber *event_handle_key in eventCallbacks.allKeys) {
        void (^callback)(ChatConversation *conversation) = [eventCallbacks objectForKey:event_handle_key];
        callback(conversation);
    }
}

// v2

-(NSUInteger)observeEvent:(ChatConversationEventType)eventType withCallback:(void (^)(ChatConversation *conversation))callback {
    if (!self.eventObservers) {
        self.eventObservers = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(eventType)];
    if (!eventCallbacks) {
        eventCallbacks = [[NSMutableDictionary alloc] init];
        [self.eventObservers setObject:eventCallbacks forKey:@(eventType)];
    }
    NSUInteger callback_handle = (NSUInteger) OSAtomicIncrement64Barrier(&_lastEventHandler);
    [eventCallbacks setObject:callback forKey:@(callback_handle)];
    return callback_handle;
}

-(void)removeObserverWithHandle:(NSUInteger)event_handler {
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
        [eventCallbacks removeObjectForKey:@(event_handler)];
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
