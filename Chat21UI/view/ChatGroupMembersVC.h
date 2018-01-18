//
//  ChatGroupMembersVC.h
//  Smart21
//
//  Created by Andrea Sponziello on 05/05/15.
//
//

#import <UIKit/UIKit.h>
#import "ChatModalCallerDelegate.h"

@class ChatGroup;
@class ChatImageCache;

@interface ChatGroupMembersVC : UITableViewController <ChatModalCallerDelegate>

@property (strong, nonatomic) ChatGroup *group;
//@property (strong, nonatomic) NSMutableArray *members_array;
- (IBAction)addMember:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addMemberButton;

// IMAGES
@property (strong, nonatomic) ChatImageCache *imageCache;
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;

@end

