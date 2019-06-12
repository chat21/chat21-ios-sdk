
//  ChatMessagesTVC.m
//  Chat21
//
//  Created by Dario De Pascalis on 22/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatMessagesTVC.h"
#import "ChatMessagesVC.h"
#import "ChatConversationHandler.h"
#import "ChatMessage.h"
#import "ChatMessageComponents.h"
#import <QuartzCore/QuartzCore.h>
#import "ChatUtil.h"
#import "ChatMiniBrowserVC.h"
#import "ChatUser.h"
#import "ChatLocal.h"
#import "ChatInfoMessageTVC.h"
#import "ChatTextMessageLeftCell.h"
#import "ChatTextMessageRightCell.h"
#import "ChatInfoMessageCell.h"
#import "ChatImageMessageRightCell.h"
#import "ChatImageMessageLeftCell.h"
#import "ChatImageCache.h"
#import "ChatImageDownloadManager.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <NYTPhotoViewer/NYTPhotoViewerArrayDataSource.h>
#import "ChatNYTPhoto.h"
#import "ChatMessageCell.h"
#import "ChatStyles.h"
#import "ChatTextMessageRightCell.h"

@interface ChatMessagesTVC ()

@property(nonatomic, strong) NSString *documentURL;

@end

@implementation ChatMessagesTVC

static NSString *OPEN_LINK_KEY = @"Open link";
static NSString *COPY_LINK_KEY = @"Copy link";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 49.5;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.rowHeights = [[NSMutableDictionary alloc] init];
    self.rowComponents = [[NSMutableDictionary alloc] init];
    self.imageCache = [ChatImageCache getSharedInstance];
    [self popUpMenu];
}

//-(void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}

//////////////// POPUPMENU /////////////

-(QBPopupMenu *)popUpMenuForSelectedMessage {
    //    QBPopupMenuItem *itemCopy = [QBPopupMenuItem itemWithTitle:@"Copicchia" target:self action:@selector(copicchia:)];
    //    //        QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"image"] target:self action:@selector(action:)];
    //    self.popupMenu = [[QBPopupMenu alloc] initWithItems:@[itemCopy]];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    QBPopupMenuItem *item_copy = [QBPopupMenuItem itemWithTitle:NSLocalizedString(@"copy", nil) target:self action:@selector(copy_action:)];
    [items addObject:item_copy];
    QBPopupMenuItem *item_info = [QBPopupMenuItem itemWithTitle:NSLocalizedString(@"info", nil) target:self action:@selector(info_action:)];
    [items addObject:item_info];
//     @[item_copy, item_info];
    
    if (self.selectedMessage.status == MSG_STATUS_FAILED) {
        QBPopupMenuItem *item_resend = [QBPopupMenuItem itemWithTitle:NSLocalizedString(@"resend", nil) target:self action:@selector(resend_action:)];
        [items addObject:item_resend];
    }
    //    QBPopupMenuItem *item_delete = [QBPopupMenuItem itemWithTitle:@"Copia" target:self action:@selector(delete_action:)];
    
    //    QBPopupMenuItem *item5 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"clip"] target:self action:@selector(action)];
    //    QBPopupMenuItem *item6 = [QBPopupMenuItem itemWithTitle:@"Delete" image:[UIImage imageNamed:@"trash"] target:self action:@selector(action)];
    
    
    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
    popupMenu.height = 30;
    popupMenu.navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    popupMenu.statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    //    popupMenu.delegate = self;
    return popupMenu;
}

-(void)popUpMenu {
    //    QBPopupMenuItem *itemCopy = [QBPopupMenuItem itemWithTitle:@"Copicchia" target:self action:@selector(copicchia:)];
    //    //        QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"image"] target:self action:@selector(action:)];
    //    self.popupMenu = [[QBPopupMenu alloc] initWithItems:@[itemCopy]];
    
    QBPopupMenuItem *item_copy = [QBPopupMenuItem itemWithTitle:NSLocalizedString(@"copy", nil) target:self action:@selector(copy_action:)];
    QBPopupMenuItem *item_info = [QBPopupMenuItem itemWithTitle:NSLocalizedString(@"info", nil) target:self action:@selector(info_action:)];
//    QBPopupMenuItem *item_delete = [QBPopupMenuItem itemWithTitle:@"Copia" target:self action:@selector(delete_action:)];
    
    //    QBPopupMenuItem *item5 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"clip"] target:self action:@selector(action)];
    //    QBPopupMenuItem *item6 = [QBPopupMenuItem itemWithTitle:@"Delete" image:[UIImage imageNamed:@"trash"] target:self action:@selector(action)];
    NSArray *items = @[item_copy, item_info];
    
    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
    popupMenu.height = 30;
    popupMenu.navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    popupMenu.statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
//    popupMenu.delegate = self;
    self.popupMenu = popupMenu;
}

-(void)popupMenuDidDisappear:(QBPopupMenu *)menu {
    [self.vc dismissKeyboardFromTableView:YES];
}

-(void)copy_action:(id)sender {
    UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
    generalPasteboard.string = self.selectedText;
    NSLog(@"Text copied!");
}

-(void)info_action:(id)sender {
    NSLog(@"Message info action!");
    [self performSegueWithIdentifier:@"info" sender:self];
}

-(void)resend_action:(id)sender {
    NSString *selectedMessageId = self.selectedMessage.messageId;
    NSLog(@"Resending message with id %@", selectedMessageId);
    [self.conversationHandler resendMessageWithId:selectedMessageId completion:^(ChatMessage *message, NSError *error) {
        NSLog(@"Message %@ successfully resent.", selectedMessageId);
    }];
}

static NSString *MATCH_TYPE_URL = @"URL";
static NSString *MATCH_TYPE_CHAT_LINK = @"CHATLINK";

//-(BOOL)photosViewController:(NYTPhotosViewController *)controller handleActionButtonTappedForPhoto:(id <NYTPhoto>)photo {
//    NSLog(@"Activity...");
//    UIImage *image = photo.image;
//    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
//    activityViewController.completionWithItemsHandler = ^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
//    };
//        [self presentViewController:activityViewController animated:YES completion:nil];
//    return NO;
//}

- (void)longTapOnCell:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSLog(@"Long tap on: %@", recognizer.view);
    UITableViewCell *containerCell = (UITableViewCell *)recognizer.view.superview.superview.superview;
    NSLog(@"suoerview; %@", containerCell);
    if ([containerCell isKindOfClass:[ChatTextMessageRightCell class]]) {
        NSLog(@"Right Cell");
        self.right_cell_hl = YES;
    }
    else if ([containerCell isKindOfClass:[ChatTextMessageLeftCell class]]) {
        NSLog(@"Left Cell");
        self.right_cell_hl = NO;
    }
    
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    ChatMessage *message = [self.conversationHandler.messages objectAtIndex:indexPath.row];
    self.selectedMessage = message;
    NSLog(@"Message.text: %@", message.text);
    if ([message typeImage]) {
        NSLog(@"Long tap On Cell: Image message");
        [self processLongTapOnImageMessage:recognizer message:message];
    }
    else {
        NSLog(@"Long tap On Cell: Text message");
        [self processLongTapOnTextMessage:recognizer message:message];
    }
    
    // get the index path of tapped cell:
//    CGPoint tapLocation = [recognizer locationInView:self.tableView];
//    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    
    
//    ChatMessage *message = [self.conversationHandler.messages objectAtIndex:indexPath.row];
    
}

-(void)processLongTapOnImageMessage:(UIGestureRecognizer *)recognizer message:(ChatMessage *)message {
    NSLog(@"Long tap on Image message.");
    [self showCustomPopupMenu:recognizer];
}

-(void)processLongTapOnTextMessage:(UIGestureRecognizer *)recognizer message:(ChatMessage *)message {
    UILabel *label = (UILabel *)recognizer.view;
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
    
    CGPoint locationOfTouchInLabel = [recognizer locationInView:label];
    NSInteger indexOfCharacter = [self indexOfCharacterInLabel:label onTapPoint:locationOfTouchInLabel];
    
    NSTextCheckingResult *selectedMatch = nil;
    NSString *selectedmatchType = nil;
    //    NSLog(@"\"%@\"",[text substringWithRange:NSMakeRange(indexOfCharacter, 1)]);
    NSArray *urlsMatches = components.urlsMatches;
    if (urlsMatches) {
        for (NSTextCheckingResult *match in urlsMatches) {
            if (NSLocationInRange(indexOfCharacter, match.range)) {
                NSLog(@"Link tapped WITH LONG TAP! %@", components.text);
                selectedMatch = match;
                selectedmatchType = MATCH_TYPE_URL;
                NSString* link = [components.text substringWithRange:match.range];
//                [self unhighlightTappedLink];
                self.selectedHighlightLabel = label;
                self.selectedHighlightRange = match.range;
                self.selectedHighlightLink = link;
                break;
            }
        }
    }
    
    // check chat type links
    NSArray *chatLinkMatches = components.chatLinkMatches;
    if (chatLinkMatches) {
        NSLog(@"analyz chatLinkMatches %lu", (unsigned long)chatLinkMatches.count);
        for (NSTextCheckingResult *match in chatLinkMatches) {
            NSLog(@"analyz match pos: %lu len: %lu", match.range.location, match.range.length);
            if (NSLocationInRange(indexOfCharacter, match.range)) {
                NSLog(@"Chat Link tapped WITH LONG TAP!");
                selectedMatch = match;
                selectedmatchType = MATCH_TYPE_CHAT_LINK;
                NSString* link = [components.text substringWithRange:match.range];
                [self unhighlightTappedLink];
                self.selectedHighlightLabel = label;
                self.selectedHighlightRange = match.range;
                self.selectedHighlightLink = link;
                break;
            }
        }
    }
    
    if (selectedMatch) {
        if ([selectedmatchType isEqualToString:MATCH_TYPE_URL]) {
            NSLog(@"Opening link menuc for: %@", self.selectedHighlightLink);
            [self highlightTappedLinkWithTimeout:NO];
            [self setupMenuForSelectedLink];
        }
    } else {
        // ****** LONG TAP ON CELL ****** //
        [self showCustomPopupMenu:recognizer];
    }
}

- (void)tapOnCell:(UIGestureRecognizer *)recognizer
{
    NSLog(@"TAP on: %@", recognizer.view);
    // get the index path:
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    ChatMessage *message = [self.conversationHandler.messages objectAtIndex:indexPath.row];
    NSLog(@"Message.text: %@", message.text);
    if ([message typeImage]) {
        NSLog(@"tapOnCell: Image message");
        [self processTapOnImageMessage:recognizer message:message];
    }
    else {
        NSLog(@"tapOnCell: Text message");
        [self processTapOnTextMessage:recognizer message:message];
    }
//    UIView *view = (UIView *)recognizer.view;
//    if ([view isKindOfClass:[UIImageView class]]) {
//        NSLog(@"UIImageView");
//    }
//    else if ([view isKindOfClass:[UILabel class]]) {
//        NSLog(@"UILabel");
//    }
}

-(void)processTapOnImageMessage:(UIGestureRecognizer *)recognizer message:(ChatMessage *)message {
//    if (![recognizer.view isKindOfClass:[UIImageView class]]) {
//        NSLog(@"Error. recognizer.view is not UILabel for a message of type text.");
//        return;
//    }
    NSLog(@"Processing tap on Image message.");
    self.selectedImageURL = [[NSString alloc] initWithFormat:@"file://%@", [message imagePathFromMediaFolder] ];
    NSLog(@"Opening image: %@", self.selectedImageURL);
//    [self performSegueWithIdentifier:@"imageView" sender:self];
//    ChatNYTPhoto .image .placeholderImage
    
    UIImage *image = [message imageFromMediaFolder];
    ChatNYTPhoto *photo = [[ChatNYTPhoto alloc] init];
    photo.image = image;
    NSArray *photos = [NSArray arrayWithObjects:photo, nil];
    NYTPhotoViewerArrayDataSource *dataSource = [[NYTPhotoViewerArrayDataSource alloc] initWithPhotos:photos];
    NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithDataSource:dataSource];
    [self presentViewController:photosViewController animated:YES completion:nil];
}

-(void)processTapOnTextMessage:(UIGestureRecognizer *)recognizer message:(ChatMessage *)message {
    if (![recognizer.view isKindOfClass:[UILabel class]]) {
        NSLog(@"Error. recognizer.view is not UILabel for a message of type text.");
        return;
    }
    NSLog(@"Processing tap on Text message.");
    UILabel *label = (UILabel *)recognizer.view;
    CGPoint locationOfTouchInLabel = [recognizer locationInView:label];
    NSInteger indexOfCharacter = [self indexOfCharacterInLabel:label onTapPoint:locationOfTouchInLabel];
    
//    NSLog(@"INDEX: %ld", indexOfCharacter);
    
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
    
    NSString *text = components.text;
    
    // char print
    if (indexOfCharacter > text.length - 1) {
        return;
    }
    
    NSTextCheckingResult *selectedMatch = nil;
    NSString *selectedmatchType = nil;
    NSArray *urlsMatches = components.urlsMatches;
//    NSLog(@"\"%@\"",[text substringWithRange:NSMakeRange(indexOfCharacter, 1)]);
    if (urlsMatches) {
        for (NSTextCheckingResult *match in urlsMatches) {
            if (NSLocationInRange(indexOfCharacter, match.range)) {
                NSLog(@"Link tapped! location: %lu", (unsigned long)match.range.location);
                selectedMatch = match;
                selectedmatchType = MATCH_TYPE_URL;
                NSString* link = [text substringWithRange:match.range];
                [self unhighlightTappedLink];
                self.selectedHighlightLabel = label;
                self.selectedHighlightRange = match.range;
                self.selectedHighlightLink = link;
                break;
            }
        }
    }
    
    // check chat type links
    NSArray *chatLinkMatches = components.chatLinkMatches;
    if (chatLinkMatches) {
        for (NSTextCheckingResult *match in chatLinkMatches) {
            if (NSLocationInRange(indexOfCharacter, match.range)) {
                NSLog(@"Chat Link tapped!");
                selectedMatch = match;
                selectedmatchType = MATCH_TYPE_CHAT_LINK;
                NSString* link = [components.text substringWithRange:match.range];
                [self unhighlightTappedLink];
                self.selectedHighlightLabel = label;
                self.selectedHighlightRange = match.range;
                self.selectedHighlightLink = link;
                break;
            }
        }
    }
    
    if (selectedMatch) {
        if ([selectedmatchType isEqualToString:MATCH_TYPE_URL]) {
            NSLog(@"Opening link menu for: %@", self.selectedHighlightLink);
            [self highlightTappedLinkWithTimeout:YES];
            [self performSegueWithIdentifier:@"webView" sender:self];
        }
    }
}

-(void)highlightTappedLinkWithTimeout:(BOOL)timeout { // left or right?
    // if a timer was still active first invalidate
    [self.highlightTimer invalidate];
    self.highlightTimer = nil;
    
    if (!self.selectedHighlightLabel) {
        return;
    }
    ChatStyles *styles = [ChatStyles sharedInstance];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.selectedHighlightLabel.attributedText];
    
    UIColor *backgroundColor;
    UIColor *textColor;
    if (self.right_cell_hl) {
        backgroundColor = styles.linkRightHLBackgroundColor;
        textColor = styles.linkRightHLTextColor;
    }
    else {
        backgroundColor = styles.linkLeftHLBackgroundColor;
        textColor = styles.linkLeftHLTextColor;
    }
    [string addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:self.selectedHighlightRange];
    [string addAttribute:NSForegroundColorAttributeName value:textColor range:self.selectedHighlightRange];
    self.selectedHighlightLabel.attributedText = string;
    if (timeout) {
        self.highlightTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(endHighlight) userInfo:nil repeats:NO];
    }
}

-(void)unhighlightTappedLink {
    if (!self.selectedHighlightLabel) {
        return;
    }
    NSLog(@"TAP5!");
    ChatStyles *styles = [ChatStyles sharedInstance];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.selectedHighlightLabel.attributedText];
    NSLog(@"TAP6!");
    UIColor *backgroundColor = [UIColor clearColor];
    UIColor *textColor;
    if (self.right_cell_hl) {
        textColor = styles.ballonRightTextColor;
    }
    else {
        textColor = styles.ballonLeftTextColor;
    }
    NSLog(@"TAP7! %@", string);
    [string addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:self.selectedHighlightRange];
    [string addAttribute:NSForegroundColorAttributeName value:textColor range:self.selectedHighlightRange];
    NSLog(@"TAP9!");
    self.selectedHighlightLabel.attributedText = string;
}

-(void)endHighlight {
    [self.highlightTimer invalidate];
    self.highlightTimer = nil;
    [self unhighlightTappedLink];
    self.selectedHighlightLabel = nil;
}

-(NSInteger)indexOfCharacterInLabel:(UILabel *)label onTapPoint:(CGPoint)point {
    UILabel *textLabel = label;
    CGPoint tapLocation = point;
    
    // init text storage
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:textLabel.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // init text container
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(textLabel.frame.size.width, textLabel.frame.size.height + 100) ];
    //    NSLog(@"label width: %f h: %f", textLabel.frame.size.width, textLabel.frame.size.height);
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = textLabel.numberOfLines;
    textContainer.lineBreakMode = textLabel.lineBreakMode;
    
    [layoutManager addTextContainer:textContainer];
    
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:tapLocation
                                                      inTextContainer:textContainer
                             fractionOfDistanceBetweenInsertionPoints:NULL];
    
    
    return characterIndex;
}

-(void)showCustomPopupMenu:(UIGestureRecognizer *)recognizer {
    CGPoint pressLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *pressIndexPath = [self.tableView indexPathForRowAtPoint:pressLocation];
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:pressIndexPath];
    UILabel *message_label = (UILabel *)[cell viewWithTag:10];
    self.selectedText = message_label.text;
    UIView *cell_background = (UIView *)[cell viewWithTag:50];
    NSLog(@"label.text: %@", message_label.text);
    CGFloat abs_x = cell_background.frame.origin.x + cell.frame.origin.x + self.view.frame.origin.x; // l'ultimo è zero
    CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:pressIndexPath];
    CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
    CGFloat abs_y = rectInSuperview.origin.y + cell_background.frame.origin.y;
    NSLog(@"abs_y %f", abs_y);
    // absolute to view, not tableView
    CGRect absolute_to_view_rect = CGRectMake(abs_x, abs_y, message_label.frame.size.width, message_label.frame.size.height);
    // disable keyboard's gesture recognizer
    [self.vc dismissKeyboardFromTableView:NO];
    [[self popUpMenuForSelectedMessage] showInView:self.tableView targetRect:absolute_to_view_rect animated:YES];
//    [self.popupMenu showInView:self.tableView targetRect:absolute_to_view_rect animated:YES];
    // test
    //    CGRect targetRect = absolute_to_view_rect;
    //    UIView *targetV = [[UIView alloc] initWithFrame:targetRect];
    //    [targetV setBackgroundColor:[UIColor blueColor]];
    //    NSLog(@"VIEW %@", self.view);
    //    NSLog(@"TABLEVIEW %@", self.tableView);
    //    [self.view addSubview:targetV];
    //    [self.view addSubview:targetV];
    //    NSLog(@"frame %f %f %f %f", targetRect.origin.x, targetRect.origin.y, targetRect.size.width, targetRect.size.height);
    //    CGRect targetRect2 = CGRectMake(44, 268, 100, 40);
    //    UIView *targetV2 = [[UIView alloc] initWithFrame:targetRect2];
    //    [targetV2 setBackgroundColor:[UIColor redColor]];
    //    [self.tableView addSubview:targetV2];
    // test end
}

-(void)setupMenuForSelectedLink {
    //    NSLog(@"self.linkMenu %@", self.linkMenu);
    //    NSLog(@"title: %@", self.selectedHighlightLink);
    //    self.linkMenu.title = self.selectedHighlightLink;
    
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:self.selectedHighlightLink
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* copy = [UIAlertAction
                           actionWithTitle:[ChatLocal translate:COPY_LINK_KEY]
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
                               NSLog(@"Copy link");
                               UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
                               generalPasteboard.string = self.selectedHighlightLink;
                               NSLog(@"Link copied!");
                               [self unhighlightTappedLink];
                           }];
    UIAlertAction* open = [UIAlertAction
                           actionWithTitle:[ChatLocal translate:OPEN_LINK_KEY]
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
                               NSLog(@"Open link in browser");
                               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.selectedHighlightLink]];
                               [self unhighlightTappedLink];
                           }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:[ChatLocal translate:@"cancel"]
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 NSLog(@"cancel");
                                 [self unhighlightTappedLink];
                             }];
    [view addAction:open];
    [view addAction:copy];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

///////////// FINE POPUPMENU ////////////

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


-(void)scrollToLastMessage:(BOOL)animated {
    [self.view layoutIfNeeded];
    NSInteger section = 0;
    NSArray *messages = self.conversationHandler.messages;
    if (messages && messages.count > 0 && messages.count <= [self.tableView numberOfRowsInSection:section]) {
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: messages.count-1 inSection:section];
        [self.tableView
         scrollToRowAtIndexPath:ipath
         atScrollPosition: UITableViewScrollPositionTop
         animated:animated];
    }
}

- (void)reloadDataTableView {
    [self.tableView reloadData];
}

- (void)reloadDataTableViewOnIndex:(NSInteger) index {
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *messages = self.conversationHandler.messages;
    NSInteger rows_count = 1;
    if (messages) {
        rows_count = messages.count;
    }
//    NSLog(@">>> ROWS IN SECTION %ld = %ld", (long)section, (long)rows_count);
    return rows_count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.rowHeights) {
        NSNumber *_height = (NSNumber *)[self.rowHeights objectForKey:@(indexPath.row)];
        float cell_height = _height.floatValue;
        if (cell_height > 0) {
            //            NSLog(@"returning estimated height for row %ld of %f", indexPath.row, cell_height);
            return cell_height;
        }else {
            // NSLog(@"OOPS NO estimated height for row: %ld", indexPath.row);
            return UITableViewAutomaticDimension;
        }
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    float cell_height = cell.contentView.frame.size.height;
    //    NSLog(@"Caching row at index: %ld height: %f", indexPath.row, cell_height);
    [self.rowHeights setObject:@(cell_height) forKey:@(indexPath.row)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *noMessagesCell = @"noMessagesCell";
    static NSString *cellMessageInfo = @"CellMessageInfo";
    static NSString *cellMessageRight = @"CellMessageRight";
    static NSString *cellMessageLeft = @"CellMessageLeft";
    static NSString *cellImageRight = @"CellImageRight";
    static NSString *cellImageLeft = @"CellImageLeft";
    ChatMessage *message;
    
    NSArray *messages = self.conversationHandler.messages;
    if (messages && messages.count > 0) {
        message = (ChatMessage *)[messages objectAtIndex:indexPath.row];
        [self analyzeMessageText:message];
        if ([message.mtype isEqualToString:MSG_TYPE_INFO]) {
            ChatInfoMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellMessageInfo forIndexPath:indexPath];
            [cell configure:message indexPath:indexPath rowComponents:self.rowComponents];
            return cell;
        }
        else if ([self isOutgoing:message]) {
            if ([message typeImage]) {
                ChatImageMessageRightCell *cell = [tableView dequeueReusableCellWithIdentifier:cellImageRight forIndexPath:indexPath];
                [cell configure:message
                    messages:messages
                    indexPath:indexPath
                    viewController:self rowComponents:self.rowComponents
                    imageCache:self.imageCache
                    completion:^(UIImage *image) {
                        [self.imageCache addImage:image withKey:message.messageId];
                        if ([self isIndexPathVisible:indexPath]) {
                            ChatImageMessageRightCell *updateCell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
                            if (updateCell) {
                                if (image) {
                                    updateCell.messageImageView.image = image;
                                }
                                else {
                                    [self downloadImage:message onIndexPath:indexPath];
                                }
                            }
                        }
                     }
                 ];
                return cell;
            }
            else {
                ChatTextMessageRightCell *cell = [tableView dequeueReusableCellWithIdentifier:cellMessageRight forIndexPath:indexPath];
                [cell configure:message messages:messages indexPath:indexPath viewController:self rowComponents:self.rowComponents];
                return cell;
            }
        }
        else {
            if ([message typeImage]) {
                ChatImageMessageLeftCell *cell = [tableView dequeueReusableCellWithIdentifier:cellImageLeft forIndexPath:indexPath];
                [cell configure:message
                       messages:messages
                      indexPath:indexPath
                 viewController:self rowComponents:self.rowComponents
                     imageCache:self.imageCache
                     completion:^(UIImage *image) {
                         [self.imageCache addImage:image withKey:message.messageId];
                         if ([self isIndexPathVisible:indexPath]) {
                             ChatImageMessageRightCell *updateCell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
                             if (updateCell) {
                                 if (image) {
                                     [self.tableView beginUpdates];
                                     updateCell.messageImageView.image = image;
                                     [self.tableView endUpdates];
                                 }
                                 else {
                                     [self downloadImage:message onIndexPath:indexPath];
                                 }
                             }
                         }
                     }
                 ];
                return cell;
//                ChatTextMessageLeftCell *cell = [tableView dequeueReusableCellWithIdentifier:cellMessageLeft forIndexPath:indexPath];
//                [cell configure:message messages:messages indexPath:indexPath viewController:self rowComponents:self.rowComponents];
//                return cell;
            }
            else {
                NSLog(@"rendering text message %@", message.text);
                ChatTextMessageLeftCell *cell = [tableView dequeueReusableCellWithIdentifier:cellMessageLeft forIndexPath:indexPath];
//                NSLog(@"cell class: %@", NSStringFromClass([cell class]));
                [cell configure:message messages:messages indexPath:indexPath viewController:self rowComponents:self.rowComponents];
                return cell;
            }
        }
    }
    return [tableView dequeueReusableCellWithIdentifier:noMessagesCell forIndexPath:indexPath];
}

- (void)downloadImage:(ChatMessage *)message onIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Downloading image: %@", message.imageURL);
    ChatMessagesTVC * __weak weakSelf = self;
    [self.conversationHandler.imageDownloader downloadImage:message onIndexPath:indexPath completionHandler:^(NSIndexPath * indexPath, UIImage *image, NSError *error) {
        if (error) {
            NSLog(@"Image downloaded with error. %@", [error localizedDescription]);
        }
        ChatMessagesTVC *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf.imageCache addImage:image withKey:message.messageId];
        if ([strongSelf isIndexPathVisible:indexPath]) {
            ChatImageMessageRightCell *updateCell = (id)[strongSelf.tableView cellForRowAtIndexPath:indexPath];
            if (updateCell) {
                updateCell.messageImageView.image = image;
            }
        }
    }];
}

-(BOOL)isIndexPathVisible:(NSIndexPath *)indexPath {
    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *index in indexes) {
        if (indexPath.row == index.row && indexPath.section == index.section) {
            return YES;
        }
    }
    return NO;
}

-(void)messageUpdated:(ChatMessage *)message {
    // TODO
    // all this stuff on ContainerTVC
    // indexPathMessage = [self findIndexPathForMessage:message];
    // indexes = [self.tableView indexPathsForVisibleRows];
    // if (indexPathMessage <= indexes.row.max && indexPathMessage >= indexes.row.min)
    //      if ([self isIndexPathVisible:indexPath]) {
    //      ChatImageMessageRightCell *updateCell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
    //      if (updateCell) {
    //            [self.tableView beginUpdates];
    //            updateCell.messageImageView.image = image;
    //            [self.tableView endUpdates];
    //      }
    [self reloadDataTableView];
}

-(void)messageDeleted:(ChatMessage *)message {
    [self reloadDataTableView];
}


-(BOOL)isOutgoing:(ChatMessage *)message {
    return [message.sender isEqualToString:self.vc.senderId];
}

-(void)analyzeMessageText:(ChatMessage *)message {
    // TEST URLs
//    NSLog(@"Text: %@", message.text);
    NSString *text = message.text;
    if (!text) {
        text = @""; // TEST CAN'T BE NIL!!!!
    }
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
    if (components) {
        // COMPONENTS ALREADY CREATED
        return;
    }
    components = [[ChatMessageComponents alloc] init];
    components.text = text;
//    NSLog(@"CREATED componenst[%lu].text=%@", indexPath.row, components.text);
    // HTTP URLs
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *arrayOfAllMatches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    if (arrayOfAllMatches) {
        components.urlsMatches = arrayOfAllMatches;
    }
    
    // CHAT LINKs
//    NSLog(@"ESTRAGGO LINK CHAT");
    NSError *error_chat;
    NSRegularExpression *regex_chat = [NSRegularExpression regularExpressionWithPattern:@"(chat://)([a-zA-Z0-9_])+" options:NSRegularExpressionCaseInsensitive error:&error_chat];
    
//    NSString *_text = message.text; //@"andrea qui: chat:antonio e qui: chat:mario_fino0 fine";
//    NSLog(@"analizzo il testo: %@", _text);
    NSArray *_arrayOfAllMatches = [regex_chat matchesInString:text options:0 range:NSMakeRange(0, [text length])];
//    NSLog(@"match trovati: %@", _arrayOfAllMatches);
    if (_arrayOfAllMatches) {
        components.chatLinkMatches = _arrayOfAllMatches;
    }
    
    //    // TEST
    //    NSLog(@"Text analysis for message: %@ on row: %ld", message.text, indexPath.row);
    //    for (NSTextCheckingResult *match in arrayOfAllMatches) {
    //        NSString* substringForMatch = [text substringWithRange:match.range];
    //        NSLog(@"Extracted URL: %@ in pos start:%ld end:%ld",substringForMatch, match.range.location, match.range.location + match.range.length);
    //    }
    
    [self.rowComponents setObject:components forKey:message.messageId];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"prepareForSegue: %@",segue.identifier);
    if ([segue.identifier isEqualToString:@"webView"]) {
        ChatMiniBrowserVC *vc = (ChatMiniBrowserVC *)[segue destinationViewController];
        vc.hiddenToolBar = YES;
        vc.titlePage = @"";
        vc.urlPage = self.selectedHighlightLink;
    }
//    if ([segue.identifier isEqualToString:@"imageView"]) {
//        ChatImageBrowserVC *vc = (ChatImageBrowserVC *)[segue destinationViewController];
//        vc.imageURL = self.selectedImageURL;
//    }
    else if ([segue.identifier isEqualToString:@"info"]) {
        ChatInfoMessageTVC *vc = (ChatInfoMessageTVC *)[segue destinationViewController];
        vc.message = self.selectedMessage;
    }
}

-(void)dealloc {
    NSLog(@"DEALLOCATING: ChatMessagesTVC.");
}

@end

