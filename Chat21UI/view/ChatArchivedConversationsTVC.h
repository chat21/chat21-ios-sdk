//
//  ChatArchivedConversationsTVC.h
//  tiledesk
//
//  Created by Andrea Sponziello on 16/07/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ChatConversationsHandler;
@class CellConfigurator;
@class ChatDiskImageCache;

static const int SECTION_ARCHIVED_CONVERSATIONS_INDEX = 0;

@interface ChatArchivedConversationsTVC : UITableViewController

@property (strong, nonatomic) NSString *selectedConversationId;
@property (strong, nonatomic) NSString *selectedRecipientId;
@property (strong, nonatomic) NSString *selectedRecipientFullname;
@property (strong, nonatomic) NSString *selectedGroupId;
@property (strong, nonatomic) NSString *selectedGroupName;
@property (assign, nonatomic) BOOL isModal;
@property (strong, nonatomic) ChatDiskImageCache *imageCache;
@property (strong, nonatomic) ChatConversationsHandler *conversationsHandler;
@property (strong, nonatomic) CellConfigurator *cellConfigurator;

// subscribers
@property (assign, nonatomic) NSUInteger added_handle;
@property (assign, nonatomic) NSUInteger changed_handle;
@property (assign, nonatomic) NSUInteger read_status_changed_handle;
@property (assign, nonatomic) NSUInteger deleted_handle;

@end
