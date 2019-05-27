//
//  ChatConversationsVC.h
//  Soleto
//
//  Created by Andrea Sponziello on 07/11/14.
//
//

#import <UIKit/UIKit.h>
#import "ChatPresenceHandler.h"
//#import "ChatModalCallerDelegate.h"
#import "ChatUser.h"

@import Firebase;

@class ChatConversationsHandler;
@class ChatGroupsHandler;
@class ChatImageCache;
@class ChatPresenceHandler;
@class SHPUserDC;
@class ChatContactsSynchronizer;
@class ChatGroup;
@class CellConfigurator;
@class ChatDiskImageCache;
@class ChatConversation;

static const int SECTION_GROUP_MENU_INDEX = 0;
static const int SECTION_CONVERSATIONS_INDEX = 1;

@interface ChatConversationsVC : UITableViewController <UIActionSheetDelegate>
- (IBAction)newGroupAction:(id)sender;
- (IBAction)groupsAction:(id)sender;

@property (strong, nonatomic) NSString *selectedConversationId;
@property (strong, nonatomic) NSIndexPath *selectedConversationIndexPath;
@property (strong, nonatomic) NSString *selectedRecipientId;
@property (strong, nonatomic) NSString *selectedRecipientFullname;
@property (strong, nonatomic) NSString *selectedRecipientTextToSend;
@property (strong, nonatomic) NSDictionary *selectedRecipientAttributesToSend;
@property (assign, nonatomic) BOOL groupsMode;
@property (strong, nonatomic) NSString *selectedGroupId;
@property (strong, nonatomic) NSString *selectedGroupName;
@property (strong, nonatomic) ChatUser *me;
//@property (strong, nonatomic) NSIndexPath *removingConversationAtIndexPath;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) ChatDiskImageCache *imageCache;
@property (assign, nonatomic) int unread_count;
@property (strong, nonatomic) NSDictionary *settings;
@property (assign, nonatomic) BOOL isModal;
@property (strong, nonatomic) CellConfigurator *cellConfigurator;
@property (nonatomic, copy) void (^dismissModalCallback)();

// connection status
@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;
@property (strong, nonatomic) UIButton *usernameButton;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

// subscribers
@property (assign, nonatomic) NSUInteger added_handle;
@property (assign, nonatomic) NSUInteger changed_handle;
@property (assign, nonatomic) NSUInteger read_status_changed_handle;
@property (assign, nonatomic) NSUInteger deleted_handle;
// status
@property (assign, nonatomic) NSUInteger connectedHandle;
@property (assign, nonatomic) NSUInteger disconnectedHandle;

// user thumbs
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;

//// user info
//@property (strong, nonatomic) SHPUserDC *userLoader;

@property (strong, nonatomic) ChatConversationsHandler *conversationsHandler;
@property (strong, nonatomic) ChatPresenceHandler *presenceHandler;

-(void)initializeWithSignedUser; // call this on every signin
-(void)resetCurrentConversation;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
- (IBAction)cancelAction:(id)sender;

- (IBAction)actionNewMessage:(id)sender;

- (IBAction)unwindToConversationsView:(UIStoryboardSegue*)sender;

-(void)openConversationWithUser:(ChatUser *)user;
-(void)openConversationWithUser:(ChatUser *)user orGroup:(ChatGroup *)group sendMessage:(NSString *)text attributes:(NSDictionary *)attributes;

-(void)setUIStatusDisconnected;
-(void)setUIStatusConnected;

+(void)updateReadStatusForConversationCell:(ChatConversation *)conversation atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

//-(void)logout;

@end

