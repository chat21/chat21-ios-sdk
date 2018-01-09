//
//  ChatMessagesTVC.h
//  Chat21
//
//  Created by Dario De Pascalis on 22/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBPopupMenu.h"

@class ChatMessagesVC;
@class ChatConversationHandler;
@class QBPopupMenu;

@interface ChatMessagesTVC : UITableViewController<UIActionSheetDelegate,QBPopupMenuDelegate>{
    
}
@property (weak, nonatomic) ChatMessagesVC *vc;
@property (weak, nonatomic) ChatConversationHandler *conversationHandler;
@property (strong, nonatomic) NSMutableDictionary *rowHeights;
@property (strong, nonatomic) NSMutableDictionary *rowComponents;
@property (strong, nonatomic) NSTimer *highlightTimer;
@property (strong, nonatomic) UILabel *selectedHighlightLabel;
@property (assign, nonatomic) NSRange selectedHighlightRange;
@property (strong, nonatomic) NSString *selectedHighlightLink;
//@property (strong, nonatomic) UIActionSheet *linkMenu;

@property (strong, nonatomic) QBPopupMenu *popupMenu;
@property (strong, nonatomic) NSString *selectedText;

- (void)reloadDataTableView;
- (void)scrollToLastMessage:(BOOL)animated;

@end
