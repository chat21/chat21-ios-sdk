//
//  ChatUIManager.m
//  tilechat
//
//  Created by Andrea Sponziello on 06/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatUIManager.h"
#import "ChatConversationsVC.h"
#import "ChatMessagesVC.h"
#import "ChatManager.h"
#import "NotificationAlertView.h"
#import "ChatSelectUserLocalVC.h"

static ChatUIManager *sharedInstance = nil;
static NotificationAlertView *notificationAlertInstance = nil;

@implementation ChatUIManager

+(ChatUIManager *)getInstance {
    if (!sharedInstance) {
        sharedInstance = [[ChatUIManager alloc] init];
    }
    return sharedInstance;
}

-(void)openConversationsViewAsModal:(UIViewController *)vc withCompletionBlock:(void (^)())completionBlock {
    UINavigationController * nc = [self conversationsViewController];
    ChatConversationsVC *conversationsVc = (ChatConversationsVC *)[[nc viewControllers] objectAtIndex:0];
    conversationsVc.isModal = YES;
    conversationsVc.dismissModalCallback = completionBlock;
    [vc presentViewController:nc animated:YES completion:^{
        //
    }];
}

-(void)openConversationMessagesViewAsModalWith:(ChatUser *)recipient viewController:(UIViewController *)vc withCompletionBlock:(void (^)())completionBlock {
    UINavigationController * nc = [self messagesViewController];
    ChatMessagesVC *messagesVc = (ChatMessagesVC *)[[nc viewControllers] objectAtIndex:0];
    messagesVc.recipient = recipient;
    messagesVc.isModal = YES;
    messagesVc.dismissModalCallback = completionBlock;
    [vc presentViewController:nc animated:YES completion:^{
        //
    }];
}

-(UINavigationController *)conversationsViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Chat" bundle:nil];
    UINavigationController *chatNC = [sb instantiateViewControllerWithIdentifier:@"ChatNavigationController"];
    NSLog(@"conversationsViewController instance %@", chatNC);
    return chatNC;
}

-(UINavigationController *)messagesViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Chat" bundle:nil];
    UINavigationController *chatNC = [sb instantiateViewControllerWithIdentifier:@"MessagesNavigationController"];
    return chatNC;
}

-(void)openSelectContactViewAsModal:(UIViewController *)vc withCompletionBlock:(void (^)(ChatUser *contact, BOOL canceled))completionBlock {
    UINavigationController * nc = [self selectContactViewController];
    ChatSelectUserLocalVC *selectContactVC = (ChatSelectUserLocalVC *)[[nc viewControllers] objectAtIndex:0];
//    selectContactVC.isModal = YES;
    selectContactVC.completionCallback = completionBlock;
    [vc presentViewController:nc animated:YES completion:^{
        // NO CALLBACK AFTER PRESENT ACTION
    }];
}

-(UINavigationController *)selectContactViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Chat" bundle:nil];
    UINavigationController *NC = [sb instantiateViewControllerWithIdentifier:@"SelectContactNavController"];
    return NC;
}

// only for tabbed applications
+(void)moveToConversationViewWithUser:(ChatUser *)user {
    [ChatUIManager moveToConversationViewWithUser:user orGroup:nil sendMessage:nil attributes:nil];
}

// only for tabbed applications
+(void)moveToConversationViewWithUser:(ChatUser *)user sendMessage:(NSString *)message {
    [ChatUIManager moveToConversationViewWithUser:user orGroup:nil sendMessage:message attributes:nil];
}

// only for tabbed applications
+(void)moveToConversationViewWithGroup:(NSString *)groupid {
    [ChatUIManager moveToConversationViewWithUser:nil orGroup:groupid sendMessage:nil attributes:nil];
}

// only for tabbed applications
+(void)moveToConversationViewWithGroup:(NSString *)groupid sendMessage:(NSString *)message {
    [ChatUIManager moveToConversationViewWithUser:nil orGroup:groupid sendMessage:message attributes:nil];
}

// only for tabbed applications
+(void)moveToConversationViewWithUser:(ChatUser *)user orGroup:(NSString *)groupid sendMessage:(NSString *)message attributes:(NSDictionary *)attributes {
    NSInteger chat_tab_index = [ChatManager getInstance].tabBarIndex;
    NSLog(@"processRemoteNotification: messages_tab_index %ld", (long)chat_tab_index);
    // move to the converstations tab
    if (chat_tab_index >= 0) {
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UITabBarController *tabController = (UITabBarController *)window.rootViewController;
        NSArray *controllers = [tabController viewControllers];
        UIViewController *currentVc = [controllers objectAtIndex:tabController.selectedIndex];
        [currentVc dismissViewControllerAnimated:NO completion:nil];
        UINavigationController *conversationsNC = [controllers objectAtIndex:chat_tab_index];
        ChatConversationsVC *conversationsVC = conversationsNC.viewControllers[0];
        NSLog(@"openConversationWithRecipient:%@ orGroup: %@ sendText:%@", user.userId, groupid, message);
        tabController.selectedIndex = chat_tab_index;
        [conversationsVC openConversationWithUser:user orGroup:groupid sendMessage:message attributes:attributes];
    } else {
        NSLog(@"No Chat Tab configured");
    }
}

+(NotificationAlertView*)getNotificationAlertInstance {
    if (!notificationAlertInstance) {
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"notification_view" owner:self options:nil];
        NotificationAlertView *view = [subviewArray objectAtIndex:0];
        [view initViewWithHeight:60];
        notificationAlertInstance = view;
    }
    return notificationAlertInstance;
}

+(void)showNotificationWithMessage:(NSString *)message image:(UIImage *)image sender:(NSString *)sender senderFullname:(NSString *)senderFullname {
    
    NotificationAlertView *alert = [ChatUIManager getNotificationAlertInstance];
    alert.messageLabel.text = message;
    alert.senderLabel.text = senderFullname ? senderFullname : sender;
    alert.userImage.image = image;
    alert.sender = sender;
    [alert animateShow];
}

@end
