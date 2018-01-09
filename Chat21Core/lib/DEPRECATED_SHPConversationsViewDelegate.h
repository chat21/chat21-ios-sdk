//
//  SHPConversationsViewDelegate.h
//  Soleto
//
//  Created by Andrea Sponziello on 30/12/14.
//
//

#import <Foundation/Foundation.h>

@class ChatConversationsHandler;
@class ChatConversation;

@protocol SHPConversationsViewDelegate <NSObject>

@required
-(void)didFinishConnect:(ChatConversationsHandler *)handler error:(NSError *)error;
-(void)finishedReceivingConversation:(ChatConversation *)conversation;
-(void)finishedRemovingConversation:(ChatConversation *)conversation;

@end

