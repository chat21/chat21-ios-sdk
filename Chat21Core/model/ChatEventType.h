//
//  ChatEventType.h
//  tilechat
//
//  Created by Andrea Sponziello on 21/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#ifndef ChatEventType_h
#define ChatEventType_h

#import <Foundation/Foundation.h>
//#import "FIRDatabaseSwiftNameSupport.h"

/**
 * This enum is the set of events that you can observe in a Conversation.
 */
typedef NS_ENUM(NSInteger, ChatMessageEventType) {
    ChatEventMessageAdded,
    ChatEventMessageDeleted,
    ChatEventMessageChanged,
};// CHAT_SWIFT_NAME(DataEventType);

typedef NS_ENUM(NSInteger, ChatConversationEventType) {
    ChatEventConversationAdded,
    ChatEventConversationDeleted,
    ChatEventConversationChanged,
};// CHAT_SWIFT_NAME(DataEventType);

typedef NS_ENUM(NSInteger, ChatConnectionStatusEventType) {
    ChatConnectionStatusEventConnected,
    ChatConnectionStatusEventDisconnected
};// CHAT_SWIFT_NAME(DataEventType);

#endif /* ChatEventType_h */
