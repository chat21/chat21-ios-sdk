//
//  ChatSelectUserLocalVC.h
//
//  Created by Andrea Sponziello on 13/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatSynchDelegate.h"

@class ChatImageCache;
@class ChatGroup;
@class ChatUser;
@class ChatDiskImageCache;
@class ChatUserCellConfigurator;

@interface ChatSelectUserLocalVC : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, ChatSynchDelegate>

@property (strong, nonatomic) ChatUser *userSelected;
@property (strong, nonatomic) NSArray<ChatUser *> *users;
//@property (strong, nonatomic) NSMutableArray<ChatUser *> *recentUsers;
//@property (strong, nonatomic) NSMutableArray *allUsers;
//@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, copy) void (^completionCallback)(ChatUser *contact, BOOL canceled);
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSString *searchBarPlaceholder;
@property (strong, nonatomic) NSString *textToSearch;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) NSString *lastUsersTextSearch;
@property (strong, nonatomic) ChatGroup *group;
@property (assign, nonatomic) BOOL synchronizing;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) ChatUserCellConfigurator *cellConfigurator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

//-(void)networkError;
- (IBAction)CancelAction:(id)sender;

@end

