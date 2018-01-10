//
//  ChatMessagesVC.h
//  Chat21
//
//  Created by Dario De Pascalis on 22/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBPopupMenu.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ChatGroupsSubscriber.h"

@class ChatConversationHandler;
@class QBPopupMenu;
@class ChatImageCache;
@class ChatMessagesTVC;
@class ChatTitleVC;
@class ChatGroup;
@class ChatUser;

@interface ChatMessagesVC : UIViewController<QBPopupMenuDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ChatGroupsSubscriber> {
    BOOL keyboardShow;
    CGFloat heightTable;
    CGFloat originalViewHeight;
    ChatMessagesTVC *containerTVC;
    
}

@property (strong, nonatomic) ChatImageCache *imageCache;
@property (strong, nonatomic) QBPopupMenu *popupMenu;
@property (strong, nonatomic) ChatConversationHandler *conversationHandler;
@property (strong, nonatomic) ChatUser *me;

@property (strong, nonatomic) ChatUser *recipient;
@property (strong, nonatomic) NSString *senderId;
@property (strong, nonatomic) NSString *senderFullname;
@property (strong, nonatomic) NSString *textToSendAsChatOpens;
@property (strong, nonatomic) NSDictionary *attributesToSendAsChatOpens;
@property (assign, nonatomic) BOOL bottomReached;
@property (strong, nonatomic) UILabel *unreadLabel;
@property (assign, nonatomic) int unread_count;
@property (strong, nonatomic) UIStoryboard *profileSB;
@property (strong, nonatomic) UINavigationController *profileNC;
@property (strong, nonatomic) NSString *selectedText;
@property (strong, nonatomic) UITapGestureRecognizer *tapToDismissKB;
@property (assign, nonatomic) BOOL isModal;
@property (nonatomic, copy) void (^dismissModalCallback)();

// subscribers
@property (assign, nonatomic) NSUInteger added_handle;
@property (assign, nonatomic) NSUInteger changed_handle;
@property (assign, nonatomic) NSUInteger deleted_handle;


// user thumbs
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;

// imagepicker
@property (strong, nonatomic) UIActionSheet *photoMenuSheet;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImagePickerController *photoLibraryController;
@property (nonatomic, strong) UIImage *scaledImage;
@property (strong, nonatomic) UIImage *bigImage;

// GROUP_MOD
@property (strong, nonatomic) ChatGroup *group;

// titleView references
@property (strong, nonatomic) ChatTitleVC *titleVC;
@property (weak, nonatomic) UIButton *usernameButton;
@property (weak, nonatomic) UILabel *statusLabel;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
// status
@property (assign, nonatomic) NSUInteger connectedHandle;
@property (assign, nonatomic) NSUInteger disconnectedHandle;
//@property (strong, nonatomic) FIRDatabaseReference *connectedRef;
//@property (assign, nonatomic) FIRDatabaseHandle connectedRefHandle;

@property (strong, nonatomic) NSDate *lastOnline;
//@property (strong, nonatomic) FIRDatabaseReference *onlineRef;
//@property (strong, nonatomic) FIRDatabaseReference *lastOnlineRef;
//@property (assign, nonatomic) FIRDatabaseHandle online_ref_handle;
//@property (assign, nonatomic) FIRDatabaseHandle last_online_ref_handle;
@property (assign, nonatomic) BOOL online;

// sound
@property (strong, nonatomic) NSTimer *soundTimer;
@property (assign, nonatomic) BOOL playingSound;
@property (assign, nonatomic) double lastPlayedSoundTime;

@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintBottomTableTopBarMessage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutContraintBottomBarMessageBottomView;
- (IBAction)sendAction:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
- (IBAction)addContentAction:(id)sender;

-(void)dismissKeyboardFromTableView:(BOOL)activate;
-(void)updateUnreadMessagesCount;

@end
