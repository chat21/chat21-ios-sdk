//
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
    
    [self popUpMenu];
    
}

//-(void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}

//////////////// POPUPMENU /////////////

-(void)popUpMenu {
    //    QBPopupMenuItem *itemCopy = [QBPopupMenuItem itemWithTitle:@"Copicchia" target:self action:@selector(copicchia:)];
    //    //        QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"image"] target:self action:@selector(action:)];
    //    self.popupMenu = [[QBPopupMenu alloc] initWithItems:@[itemCopy]];
    
    QBPopupMenuItem *item_copy = [QBPopupMenuItem itemWithTitle:@"Copia" target:self action:@selector(copy_action:)];
    QBPopupMenuItem *item_resend = [QBPopupMenuItem itemWithTitle:@"Copia" target:self action:@selector(resend_action:)];
    QBPopupMenuItem *item_delete = [QBPopupMenuItem itemWithTitle:@"Copia" target:self action:@selector(delete_action:)];
    
    //    QBPopupMenuItem *item5 = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"clip"] target:self action:@selector(action)];
    //    QBPopupMenuItem *item6 = [QBPopupMenuItem itemWithTitle:@"Delete" image:[UIImage imageNamed:@"trash"] target:self action:@selector(action)];
    NSArray *items = @[item_copy];
    
    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
    popupMenu.height = 30;
    popupMenu.navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    popupMenu.statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    popupMenu.delegate = self;
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

static NSString *MATCH_TYPE_URL = @"URL";
static NSString *MATCH_TYPE_CHAT_LINK = @"CHATLINK";

- (void)longTapOnCell:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSLog(@"Long tap.");
    UILabel *label = (UILabel *)recognizer.view;
    
    // get the index path of tapped cell:
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    
    
    ChatMessage *message = [self.conversationHandler.messages objectAtIndex:indexPath.row];
    [self printMessage:message];
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
                NSLog(@"Link tapped WITH LONG TAP!");
                selectedMatch = match;
                selectedmatchType = MATCH_TYPE_URL;
                NSString* link = [components.text substringWithRange:match.range];
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
            //        [self.linkMenu showInView:[[[UIApplication sharedApplication] delegate] window]];//]self.view];
        }
//        else if ([selectedmatchType isEqualToString:MATCH_TYPE_CHAT_LINK]) {
//            [self highlightTappedLinkWithTimeout:YES];
//            NSLog(@"chat link: %@", self.selectedHighlightLink);
//            NSArray *parts = [self.selectedHighlightLink componentsSeparatedByString:@"//"];
//            for (NSString *p in parts) {
//                NSLog(@"part: %@", p);
//            }
//            NSString *chatToUser = parts[1];
//            ChatUser *user = [[ChatUser alloc] init];
//            user.userId = chatToUser;
//            [ChatUtil moveToConversationViewWithUser:user];
//            NSLog(@"MATCH_TYPE_CHAT_LINK");
//        }
    } else {
        // ****** LONG TAP ON CELL ****** //
        [self showCustomPopupMenu:recognizer];
    }
}

- (void)tapOnCell:(UIGestureRecognizer *)recognizer
{
    NSLog(@"TAP on: %@", recognizer.view);
    UILabel *label = (UILabel *)recognizer.view;
    
    // get the index path:
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    //    NSLog(@"TAP ON ROW %ld", indexPath.row);
    //    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:pressIndexPath];
    //    UILabel *message_label = (UILabel *)[cell viewWithTag:10];
    //    self.selectedText = message_label.text;
    
    CGPoint locationOfTouchInLabel = [recognizer locationInView:label];
    NSInteger indexOfCharacter = [self indexOfCharacterInLabel:label onTapPoint:locationOfTouchInLabel];
    
    NSLog(@"INDEX: %ld", indexOfCharacter);
    
    ChatMessage *message = [self.conversationHandler.messages objectAtIndex:indexPath.row];
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
    
    NSString *text = components.text;
    
    // char print
    if (indexOfCharacter > text.length - 1) {
        return;
    }
    
    NSTextCheckingResult *selectedMatch = nil;
    NSString *selectedmatchType = nil;
    
    NSArray *urlsMatches = components.urlsMatches;
    NSLog(@"\"%@\"",[text substringWithRange:NSMakeRange(indexOfCharacter, 1)]);
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
                //                [self highlightTappedLinkWithTimeout:YES];
                //                NSLog(@"URL: %@ in pos start:%ld end:%ld", link, match.range.location, match.range.location);
                //                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
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
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.selectedHighlightLink]];
            [self performSegueWithIdentifier:@"webView" sender:self];
        }
//        else if ([selectedmatchType isEqualToString:MATCH_TYPE_CHAT_LINK]) {
//            [self highlightTappedLinkWithTimeout:YES];
//            NSLog(@"chat link: %@", self.selectedHighlightLink);
//            NSArray *parts = [self.selectedHighlightLink componentsSeparatedByString:@"//"];
//            for (NSString *p in parts) {
//                NSLog(@"part: %@", p);
//            }
//            NSString *chatToUser = parts[1];
//            ChatUser *user = [[ChatUser alloc] init];
//            user.userId = chatToUser;
//            [ChatUtil moveToConversationViewWithUser:user];
//            NSLog(@"MATCH_TYPE_CHAT_LINK");
//        }
    }
}

-(void)highlightTappedLinkWithTimeout:(BOOL)timeout {
    // if a timer was still active first invalidate
    [self.highlightTimer invalidate];
    self.highlightTimer = nil;
    
    if (!self.selectedHighlightLabel) {
        return;
    }
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.selectedHighlightLabel.attributedText];
    UIColor *highlightColor = [UIColor whiteColor];
    [string addAttribute:NSBackgroundColorAttributeName value:highlightColor range:self.selectedHighlightRange];
    self.selectedHighlightLabel.attributedText = string;
    if (timeout) {
        self.highlightTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(endHighlight) userInfo:nil repeats:NO];
    }
}

-(void)unhighlightTappedLink {
    if (!self.selectedHighlightLabel) {
        return;
    }
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:self.selectedHighlightLabel.attributedText];
    UIColor *highlightColor = [UIColor clearColor];
    [string addAttribute:NSBackgroundColorAttributeName value:highlightColor range:self.selectedHighlightRange];
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
    UIView *sfondo_cella = (UIView *)[cell viewWithTag:50];
    NSLog(@"label.text: %@", message_label.text);
    CGFloat abs_x = sfondo_cella.frame.origin.x + cell.frame.origin.x + self.view.frame.origin.x; // l'ultimo è zero
    CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:pressIndexPath];
    CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
    CGFloat abs_y = rectInSuperview.origin.y + sfondo_cella.frame.origin.y;
    NSLog(@"abs_y %f", abs_y);
    // absolute to view, not tableView
    CGRect absolute_to_view_rect = CGRectMake(abs_x, abs_y, message_label.frame.size.width, message_label.frame.size.height);
    // disable keyboard's gesture recognizer
    [self.vc dismissKeyboardFromTableView:NO];
    [self.popupMenu showInView:self.tableView targetRect:absolute_to_view_rect animated:YES];
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

//-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (actionSheet == self.linkMenu) {
//        NSLog(@"Link menu!");
//        NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
//        if ([option isEqualToString:NSLocalizedString(COPY_LINK_KEY, nil)]) {
//            NSLog(@"Copy link");
//            UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
//            generalPasteboard.string = self.selectedHighlightLink;
//            NSLog(@"Link copied!");
//        }
//        else if ([option isEqualToString:NSLocalizedString(OPEN_LINK_KEY, nil)]) {
//            NSLog(@"Open link in browser");
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.selectedHighlightLink]];
//        }
//        else {
//            NSLog(@"MENU DISMISSED!");
//        }
//        [self unhighlightTappedLink];
//    }
//}

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
                             actionWithTitle:[ChatLocal translate:@"CancelLKey"]
                             style:UIAlertActionStyleDefault
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
    // Dispose of any resources that can be recreated.
}


-(void)scrollToLastMessage:(BOOL)animated {
    NSArray *messages = self.conversationHandler.messages;
    if (messages && messages.count > 0) {
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: messages.count-1 inSection: 0];
        [self.tableView
         scrollToRowAtIndexPath:ipath
         atScrollPosition: UITableViewScrollPositionTop
         animated:animated];
        NSLog(@"SCROLL OK!");
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
    NSLog(@">>> ROWS IN SECTION %ld = %ld", (long)section, (long)rows_count);
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
            //            NSLog(@"OOPS NO estimated height for row: %ld", indexPath.row);
            
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
    
    NSDate *dateToday = [NSDate date];//ISTANZIO DATA PREVIEW
    //    UIColor *colorCloud;
    //    UIColor *messageColor;
    UITableViewCell *cell;
    int numberDaysPrevChat = 0;
    int numberDaysNextChat = 0;
    NSString *dateChat;
    ChatMessage *message;
    ChatMessage *previousMessage;
    ChatMessage *nextMessage;
    
    NSArray *messages = self.conversationHandler.messages;
//    NSLog(@"ALL MESSAGES:");
//    int i = 0;
//    for (ChatMessage *m in messages) {
//        NSLog(@"MESSAGE[%d]: %@",i, m.text);
//        i += 1;
//    }
    if (messages && messages.count > 0) {
        message = (ChatMessage *)[messages objectAtIndex:indexPath.row];
        [self analyzeMessageText:message forIndexPath:indexPath];
        
//        NSLog(@"type: %@ text: %@", message.mtype, message.text);
        if ([message.mtype isEqualToString:MSG_TYPE_INFO]) {
            NSLog(@"MSG_TYPE_INFO");
            cell = [tableView dequeueReusableCellWithIdentifier:cellMessageInfo forIndexPath:indexPath];
            UIView *sfondo = (UIView *)[cell viewWithTag:50];
            sfondo.layer.masksToBounds = YES;
            sfondo.layer.shadowOffset = CGSizeMake(-15, 20);
            sfondo.layer.shadowRadius = 5;
            sfondo.layer.shadowOpacity = 0.5;
        }
        else if ([message.sender isEqualToString:self.vc.senderId]) {
//            NSLog(@"cellMessageRight");
            cell = [tableView dequeueReusableCellWithIdentifier:cellMessageRight forIndexPath:indexPath];
        }
        else {
//            NSLog(@"cellMessageLeft");
            cell = [tableView dequeueReusableCellWithIdentifier:cellMessageLeft forIndexPath:indexPath];
        }
        
        UIView *sfondoBox = (UIView *)[cell viewWithTag:50];
        sfondoBox.layer.masksToBounds = YES;
        sfondoBox.layer.cornerRadius = 8.0;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *labelMessage = (UILabel *)[cell viewWithTag:10];
        
        UIGestureRecognizer *longTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapOnCell:)];
        UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnCell:)];
        [labelMessage addGestureRecognizer:longTapGestureRecognizer];
        [labelMessage addGestureRecognizer:tapGestureRecognizer];
        labelMessage.userInteractionEnabled = YES;
        
        //[str addAttribute: NSLinkAttributeName value: @"http://www.google.com" range: NSMakeRange(0, 3)];
        
        [self attributedString:labelMessage text:message indexPath:indexPath];
        
        UILabel *labelTime = (UILabel *)[cell viewWithTag:40];
        labelTime.text = [message dateFormattedForListView];
        
        UILabel *labelNameUser = (UILabel *)[cell viewWithTag:20];
        NSString *text_name_user = [self displayUserOfMessage:message];
        labelNameUser.text = text_name_user;
        
        UILabel *labelDay = (UILabel *)[cell viewWithTag:30];
        if(indexPath.row>0){
            previousMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row-1)];
            if(messages.count > (indexPath.row+1)){
                nextMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row+1)];
                numberDaysNextChat = (int)[ChatUtil daysBetweenDate:message.date andDate:nextMessage.date];
            }
            numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:previousMessage.date andDate:message.date];
            dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
        }else{
            numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:message.date andDate:dateToday];
            dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
        }
        if(numberDaysPrevChat>0){
            //            [self changeConstraint:viewBox toItem:cell.contentView  topValue:21];
            //            [self showDateLabel:labelDay];
            labelDay.text = dateChat;
        }else{
            //            [self hideDateLabel:labelDay];
            labelDay.text = @"";
        }
        
        //-----------------------------------------------------------//
        //START STATE MESSAGE
        //-----------------------------------------------------------//
        
        UIImageView *status_image_view = (UIImageView *)[cell viewWithTag:22];
        switch (message.status) {
            case MSG_STATUS_SENDING:
                //                NSLog(@"SENDING!!!!!!!!!!");
                status_image_view.image = [UIImage imageNamed:@"chat_watch"];
                //message_view.textColor = [UIColor lightGrayColor];
                break;
            case MSG_STATUS_SENT:
                //                NSLog(@"SENT!!!!!!!!!!");
                status_image_view.image = [UIImage imageNamed:@"chat_check"];
                //message_view.textColor = messageColor;
                break;
            case MSG_STATUS_RETURN_RECEIPT:
                //                NSLog(@"RECEIVED!!!!!!!!!!");
                status_image_view.image = [UIImage imageNamed:@"chat_double_check"];
                //message_view.textColor = messageColor;
                break;
            case MSG_STATUS_FAILED:
                //                NSLog(@"FAILED!!!!!!!!!!");
                status_image_view.image = [UIImage imageNamed:@"chat_failed"];
                //message_view.textColor = [UIColor redColor];
                break;
            default:
                break;
        }
        //-----------------------------------------------------------//
        //END STATE MESSAGE
        //-----------------------------------------------------------//
//        NSLog(@"FINE ELABORAZIONE CELLA.");
        //        UITextView *textMessage = (UITextView *)[cell viewWithTag:10];
        //        textMessage.text = [NSString stringWithFormat:@"%@", message.text];
        //        //textMessage.selectable = NO;
        //        //textMessage.userInteractionEnabled = NO;
        //        //@property(nonatomic,getter=isSelectable) BOOL selectable NS_AVAILABLE_IOS(7_0);
        //        textMessage.dataDetectorTypes = UIDataDetectorTypeAll;
        //        textMessage.delegate = self;
        //        [textMessage sizeToFit];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:noMessagesCell forIndexPath:indexPath];
    }
    return cell;
}

-(void)attributedString:(UILabel *)label text:(ChatMessage *)message indexPath:(NSIndexPath *)indexPath {
    // consider use of: https://github.com/TTTAttributedLabel/TTTAttributedLabel
//    NSLog(@"string text: %@", message.text);
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message.text];
//    NSLog(@"attributedString.string.length: %lu", (unsigned long)attributedString.string.length);
    [attributedString addAttributes:@{NSFontAttributeName: label.font} range:NSMakeRange(0, attributedString.string.length)];
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
//    NSLog(@"componenents[%lu] text: %@ urlsMatches: %@ linkMatches: %@",indexPath.row, components.text, components.urlsMatches, components.chatLinkMatches);
    NSArray *urlMatches = components.urlsMatches;
//    NSLog(@"urlMatches %@ .count: %lu", urlMatches, (unsigned long)urlMatches.count);
    if (urlMatches) {
        for (NSTextCheckingResult *match in urlMatches) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:match.range];
        }
    }
    NSArray *chatLinkMatches = components.chatLinkMatches;
//    NSLog(@"chatLinkMatches %@ .count: %lu", chatLinkMatches, (unsigned long)chatLinkMatches.count);
    if (chatLinkMatches) {
        for (NSTextCheckingResult *match in chatLinkMatches) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor brownColor] range:match.range];
        }
    }
    label.attributedText = attributedString;
}

-(void)analyzeMessageText:(ChatMessage *)message forIndexPath:(NSIndexPath *)indexPath {
    // TEST URLs
//    NSLog(@"CREATING COMPONENTS[%ld], TEXT: %@", (long)indexPath.row, message.text);
    ChatMessageComponents *components = [self.rowComponents objectForKey:message.messageId];
    if (components) {
//        NSLog(@"COMPONENTS[%ld] ALREADY CREATED. %@",indexPath.row, components.text);
        return;
    }
    components = [[ChatMessageComponents alloc] init];
    components.text = message.text;
//    NSLog(@"CREATED componenst[%lu].text=%@", indexPath.row, components.text);
    // HTTP URLs
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *text = message.text; //@"andrea qui: http://www.google.com e qui: http://libero.it/dico?io?4&pippo=pluto%2S fine";
    NSArray *arrayOfAllMatches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    if (arrayOfAllMatches) {
        components.urlsMatches = arrayOfAllMatches;
    }
    
    // CHAT LINKs
//    NSLog(@"ESTRAGGO LINK CHAT");
    NSError *error_chat;
    NSRegularExpression *regex_chat = [NSRegularExpression regularExpressionWithPattern:@"(chat://)([a-zA-Z0-9_])+" options:NSRegularExpressionCaseInsensitive error:&error_chat];
    
    NSString *_text = message.text; //@"andrea qui: chat:antonio e qui: chat:mario_fino0 fine";
//    NSLog(@"analizzo il testo: %@", _text);
    NSArray *_arrayOfAllMatches = [regex_chat matchesInString:_text options:0 range:NSMakeRange(0, [_text length])];
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

-(NSString *)displayUserOfMessage:(ChatMessage *)m {
    NSString *displayName;
    
    // use fullname if available
    if (m.senderFullname) {
        NSString *trimmedFullname = [m.senderFullname stringByTrimmingCharactersInSet:
                                     [NSCharacterSet whitespaceCharacterSet]];
        if (trimmedFullname.length > 0 && ![trimmedFullname isEqualToString:@"(null)"]) {
            displayName = trimmedFullname;
        }
    }
    
    // if fullname not available use username instead
    if (!displayName) {
        displayName = m.sender;
    }
    
    return displayName;
}

-(NSString*)formatDateMessage:(int)numberDaysBetweenChats message:(ChatMessage*)message row:(CGFloat)row {
    NSString *dateChat;
    if(numberDaysBetweenChats>0 || row==0){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSDate *today;
        today = [NSDate date];
        int days = (int)[ChatUtil daysBetweenDate:message.date andDate:today];
        if(days==0){
            dateChat = [ChatLocal translate:@"today"];
        }
        else if(days==1){
            dateChat = [ChatLocal translate:@"yesterday"];
        }
        else if(days<8){
            [dateFormatter setDateFormat:@"EEEE"];
            dateChat = [dateFormatter stringFromDate:message.date];
        }
        else{
            [dateFormatter setDateFormat:@"dd MMM"];
            dateChat = [dateFormatter stringFromDate:message.date];
        }
    }
    return dateChat;
}

-(void)printMessage:(ChatMessage *)message {
//    NSLog(@"message.text: %@", message.text);
//    NSLog(@"message.type: %@", message.mtype);
//    NSLog(@"message.archived: %d", message.archived);
//    NSLog(@"message.attributes:");
//    NSDictionary *attributes = message.attributes;
//    NSArray *keys = [attributes allKeys];
//    for (NSString *k in keys) {
//        NSLog(@"\"%@\":\"%@\"", k, attributes[k]);
//    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"prepareForSegue: %@",segue.identifier);
    if ([segue.identifier isEqualToString:@"webView"]) {
        ChatMiniBrowserVC *vc = (ChatMiniBrowserVC *)[segue destinationViewController];
        vc.hiddenToolBar = YES;
        vc.titlePage = @"";
        vc.urlPage = self.selectedHighlightLink;
    }
}

-(void)dealloc {
    NSLog(@"DEALLOCATING CHAT MESSAGES TVC.");
}

@end

