//
//  ChatConversationSubscriber.h
//  tilechat
//
//  Created by Andrea Sponziello on 20/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

@class ChatMessage;

@protocol ChatConversationSubscriber
@required
-(void)messageAdded:(ChatMessage *)message;
-(void)messageChanged:(ChatMessage *)message;
-(void)messageDeleted:(ChatMessage *)message;
@end

