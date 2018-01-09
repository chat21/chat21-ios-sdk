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
    }
    return self;
}

-(void)dispose {
    [self.conversationsRef removeAllObservers];
    [self removeAllObservers];
    self.conversations_ref_handle_added = 0;
    self.conversations_ref_handle_changed = 0;
    self.conversations_ref_handle_removed = 0;
}

-(void)printAllConversations {
    NSLog(@"***** CONVERSATIONS DUMP **************************");
    self.conversations = [[[ChatDB getSharedInstance] getAllConversations] mutableCopy];
    for (ChatConversation *c in self.conversations) {
        NSLog(@"user: %@ id:%@ converswith:%@ sender:%@ recipient:%@",c.user, c.conversationId, c.conversWith, c.sender, c.recipient);
    }
    NSLog(@"******************************* END.");
}

-(NSMutableArray *)restoreConversationsFromDB {
    self.conversations = [[[ChatDB getSharedInstance] getAllConversationsForUser:self.me] mutableCopy];
    for (ChatConversation *c in self.conversations) {
        NSLog(@"restored conv user: %@, id: %@, last_message_text: %@",c.user, c.conversationId, c.last_message_text);
        if (c.conversationId) {
            FIRDatabaseReference *conversation_ref = [self.conversationsRef child:c.conversationId];
            c.ref = conversation_ref;
        }
        else {
            NSLog(@"ERROR restoring conv c: %@ id: %@, groupName: %@ groupId: %@ last_message_text: %@",c, c.conversationId, c.groupName, c.groupId, c.last_message_text);
        }
        
    }
    return self.conversations;
}

-(void)connect {
    // if already connected, return.
    if (self.conversations_ref_handle_added) {
        return;
    }
    
    NSLog(@"Connecting conversations' handler.");
    ChatManager *chat = [ChatManager getInstance];
    NSString *conversations_path = [ChatUtil conversationsPathForUserId:self.loggeduser.userId];
    NSLog(@"firebase_conversations_ref: %@", conversations_path);
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    self.conversationsRef = [rootRef child: conversations_path];
    [self.conversationsRef keepSynced:YES];
    NSLog(@"creating conversations_ref_handle_ADDED...");
    
    self.conversations_ref_handle_added = [[self.conversationsRef queryOrderedByChild:@"timestamp"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"NEW CONVERSATION SNAPSHOT: %@", snapshot);
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
        [self insertOrUpdateConversationOnDB:conversation];
        [self restoreConversationsFromDB];
//        [self finishedReceivingConversation:conversation];
        [self notifyEvent:ChatEventConversationAdded conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    NSLog(@"creating conversations_ref_handle_CHANGED...");
    
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
        // CONVERSATIONS NON INSERISCE IN MEMORIA MA RECUPERA TUTTE LE CONV DAL DB
        // AD OGNI NUOVO ARRIVO/AGGIORNAMENTO
        [self insertOrUpdateConversationOnDB:conversation];
        [self restoreConversationsFromDB];
//        [self finishedReceivingConversation:conversation];
        [self notifyEvent:ChatEventConversationChanged conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
    self.conversations_ref_handle_removed =
    [self.conversationsRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        NSLog(@"************************* CONVERSATION REMOVED ****************************");
        NSLog(@"REMOVED CONVERSATION snapshot............... %@", snapshot);
        ChatConversation *conversation = [ChatConversation conversationFromSnapshotFactory:snapshot me:self.loggeduser];
        if ([self.currentOpenConversationId isEqualToString:conversation.conversationId] && conversation.is_new == YES) {
            // changes (forces) the "is_new" flag to FALSE;
            conversation.is_new = NO;
            FIRDatabaseReference *conversation_ref = [self.conversationsRef child:conversation.conversationId];
            NSLog(@"UPDATING IS_NEW=NO FOR CONVERSATION %@", conversation_ref);
            [chat updateConversationIsNew:conversation_ref is_new:conversation.is_new];
        }
        // CONVERSATIONS NON INSERISCE IN MEMORIA MA RECUPERA TUTTE LE CONV DAL DB
        // AD OGNI NUOVO ARRIVO/AGGIORNAMENTO
        [self removeConversationOnDB:conversation];
        [self restoreConversationsFromDB];
//        [self finishedReceivingConversation:conversation];
        [self notifyEvent:ChatEventConversationDeleted conversation:conversation];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

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
