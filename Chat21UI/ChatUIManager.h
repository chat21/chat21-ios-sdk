//
//  ChatUIManager.h
//  tilechat
//
//  Created by Andrea Sponziello on 06/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ChatUser;
@class ChatMessagesVC;

@interface ChatUIManager : NSObject

@property (nonatomic, copy) void (^pushProfileCallback)(ChatUser *user, ChatMessagesVC *vc);

+(ChatUIManager *)getInstance;
-(void)openConversationsViewAsModal:(UIViewController *)vc withCompletionBlock:(void (^)())completionBlock;
-(void)openConversationMessagesViewAsModalWith:(ChatUser *)recipient viewController:(UIViewController *)vc withCompletionBlock:(void (^)())completionBlock;
-(void)openSelectContactViewAsModal:(UIViewController *)vc withCompletionBlock:(void (^)(ChatUser *contact, BOOL canceled))completionBlock;
-(UINavigationController *)selectContactViewController;
-(UINavigationController *)conversationsViewController;
-(UINavigationController *)messagesViewController;

// this methods work only with a tabbed application and Chat-Info.plist > tabbar-index property correctly configured to the tab index containing the ConversationsView
+(void)moveToConversationViewWithUser:(ChatUser *)user;
+(void)moveToConversationViewWithUser:(ChatUser *)user sendMessage:(NSString *)message;
+(void)moveToConversationViewWithGroup:(NSString *)groupid;
+(void)moveToConversationViewWithGroup:(NSString *)groupid sendMessage:(NSString *)message;
+(void)moveToConversationViewWithUser:(ChatUser *)user orGroup:(NSString *)groupid sendMessage:(NSString *)message attributes:(NSDictionary *)attributes;

+(void)showNotificationWithMessage:(NSString *)message image:(UIImage *)image sender:(NSString *)sender senderFullname:(NSString *)senderFullname;

@end

