//
//  ChatService.h
//  tiledesk
//
//  Created by Andrea Sponziello on 08/07/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ChatConversation;

@interface ChatService : NSObject

+(void)archiveConversation:(ChatConversation *)conversation completion:(void (^)(NSError *error))callback;
+(void)archiveAndCloseSupportConversation:(ChatConversation *)conversation completion:(void (^)(NSError *error))callback;
+(void)deleteProfilePhoto:(NSString *)userId completion:(void (^)(NSError *error))callback;

@end
