//
//  ChatSelectGroupLocalTVC.h
//  bppmobile
//
//  Created by Andrea Sponziello on 26/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatGroupsDB.h"
#import "ChatModalCallerDelegate.h"

@class ChatImageCache;
@class ChatGroup;
@class ChatUser;

@interface ChatSelectGroupLocalTVC : UITableViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;

@property (strong, nonatomic) NSMutableArray<ChatGroup *> *groups;
@property (strong, nonatomic) id <ChatModalCallerDelegate> modalCallerDelegate;

- (IBAction)CancelAction:(id)sender;

@end
