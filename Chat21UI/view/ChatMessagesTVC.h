//
//  ChatMessagesTVC.h
//  Chat21
//
//  Created by Dario De Pascalis on 22/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBPopupMenu.h"
#import "NYTPhotosViewController.h"


@class ChatMessagesVC;
@class ChatMessage;
@class ChatConversationHandler;
@class QBPopupMenu;
@class ChatImageCache;

@interface ChatMessagesTVC : UITableViewController<UIActionSheetDelegate,QBPopupMenuDelegate>{
    // <NYTPhotosViewControllerDelegate> for activity
}
@property (weak, nonatomic) ChatMessagesVC *vc;
@property (weak, nonatomic) ChatConversationHandler *conversationHandler;
@property (strong, nonatomic) NSMutableDictionary *rowHeights;
@property (strong, nonatomic) NSMutableDictionary *rowComponents;
@property (strong, nonatomic) NSTimer *highlightTimer;
@property (strong, nonatomic) UILabel *selectedHighlightLabel;
@property (assign, nonatomic) NSRange selectedHighlightRange;
@property (strong, nonatomic) NSString *selectedHighlightLink;
@property (strong, nonatomic) NSString *selectedImageURL;
@property (strong, nonatomic) ChatImageCache *imageCache;
//@property (strong, nonatomic) UIActionSheet *linkMenu;

@property (strong, nonatomic) QBPopupMenu *popupMenu;
@property (strong, nonatomic) NSString *selectedText;
@property (strong, nonatomic) ChatMessage *selectedMessage;

- (void)reloadDataTableView;
- (void)reloadDataTableViewOnIndex:(NSInteger)index;
- (void)scrollToLastMessage:(BOOL)animated;

// events
-(void)messageUpdated:(ChatMessage *)message;
-(void)messageDeleted:(ChatMessage *)message;
// TODO messageReceived (move from VC to TVC)
//-(void)messageReceived:(ChatMessage *)message;

@end
