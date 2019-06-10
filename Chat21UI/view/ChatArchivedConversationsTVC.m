//
//  ChatArchivedConversationsTVC.m
//  tiledesk
//
//  Created by Andrea Sponziello on 16/07/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatArchivedConversationsTVC.h"
#import "ChatConversation.h"
#import "ChatManager.h"
#import "ChatConversationsHandler.h"
#import "ChatLocal.h"
#import "CellConfigurator.h"
#import "ChatMessagesVC.h"
#import "ChatConversationsVC.h"
#import "ChatGroup.h"
#import "ChatDiskImageCache.h"

@interface ChatArchivedConversationsTVC ()

@end

@implementation ChatArchivedConversationsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = [ChatLocal translate:@"ArchivedConversationsTitle"];
    
    //autodim
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    NSLog(@"Conversations viewDidLoad start");
    
    self.imageCache = [ChatManager getInstance].imageCache;
    
//    self.cellConfigurator = [[CellConfigurator alloc] initWithTableView:self.tableView imageCache:self.imageCache];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    if (!self.isModal) {
        // hide cancel button
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        // show and translate cancel button
//        self.cancelButton.title = [ChatLocal translate:@"cancel"];
    }
    
    [self initConversationsHandler];
//    self.cellConfigurator.conversations = self.conversationsHandler.archivedConversations;
    
    self.cellConfigurator = [[CellConfigurator alloc] initWithTableView:self.tableView imageCache:self.imageCache conversations:self.conversationsHandler.archivedConversations];
    [self.tableView registerNib:[UINib nibWithNibName:@"dm_conversation_cell" bundle:nil] forCellReuseIdentifier:@"conversationDMCell"];
    // conversationGroupCell
    [self.tableView registerNib:[UINib nibWithNibName:@"group_conversation_cell" bundle:nil] forCellReuseIdentifier:@"conversationGroupCell"];
    
    [self.tableView reloadData];
}

-(void)initImageCache {
    //    // cache setup
    //    self.imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
    //    if (!self.imageCache) {
    //        self.imageCache = [[ChatImageCache alloc] init];
    //        self.imageCache.cacheName = @"chatUserIcons";
    //        // test
    //        // [self.imageCache listAllImagesFromDisk];
    //        // [self.imageCache empty];
    //        [self.applicationContext setVariable:@"chatUserIcons" withValue:self.imageCache];
    //    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [self removeSubscribers];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)initConversationsHandler {
    ChatManager *chatm = [ChatManager getInstance];
    ChatConversationsHandler *handler = [chatm getAndStartConversationsHandler];
    [self subscribe:handler];
    self.conversationsHandler = handler;
}

-(void)subscribe:(ChatConversationsHandler *)handler {
    if (self.added_handle > 0) {
        NSLog(@"Subscribe(): just subscribed to conversations handler. Do nothing.");
        return;
    }
    self.added_handle = [handler observeEvent:ChatEventArchivedConversationAdded withCallback:^(ChatConversation *conversation) {
        [self.tableView reloadData];
    }];
    self.added_handle = [handler observeEvent:ChatEventArchivedConversationRemoved withCallback:^(ChatConversation *conversation) {
        [self.tableView reloadData];
    }];
//    self.changed_handle = [handler observeEvent:ChatEventConversationChanged withCallback:^(ChatConversation *conversation) {
//        [self conversationReceived:conversation];
//    }];
//    self.deleted_handle = [handler observeEvent:ChatEventConversationDeleted withCallback:^(ChatConversation *conversation) {
//        [self conversationDeleted:conversation];
//    }];
}

-(void)removeSubscribers {
    [self.conversationsHandler removeObserverWithHandle:self.added_handle];
//    [self.conversationsHandler removeObserverWithHandle:self.changed_handle];
//    [self.conversationsHandler removeObserverWithHandle:self.read_status_changed_handle];
//    [self.conversationsHandler removeObserverWithHandle:self.deleted_handle];
    self.added_handle = 0;
    self.changed_handle = 0;
    self.read_status_changed_handle = 0;
    self.deleted_handle = 0;
}

//#protocol SHPConversationsViewDelegate

//protocol SHPConversationsViewDelegate

#pragma mark - Table view data source

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section != SECTION_ARCHIVED_CONVERSATIONS_INDEX) {
        return @[];
    }
    
    ChatConversation *conversation = nil;
    NSArray<ChatConversation*> *conversations = self.conversationsHandler.conversations;
    if (conversations && conversations.count > 0) {
        conversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
    }
    
    if (conversation == nil) {
        return @[];
    }
    
    // Unarchive option
    UITableViewRowAction *archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:[ChatLocal translate:@"UnarchiveConversationAction"] handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        NSLog(@"Unarchiving...");
    }];
    archiveAction.backgroundColor = [UIColor colorWithRed:0.286 green:0.439 blue:0.639 alpha:1.0];
    return @[archiveAction];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *conversations = self.conversationsHandler.archivedConversations;
    if (conversations && conversations.count > 0) {
        return conversations.count;
    } else {
        return 1; // message cell
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;// else 70;//
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *messageCellName = @"MessageCell";
    
    UITableViewCell *cell;
    NSArray *conversations = self.conversationsHandler.archivedConversations;
    if (conversations && conversations.count > 0) {
        ChatConversation *conversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
        //            NSLog(@"Conversation.sender %@", conversation.sender);
        cell = [self.cellConfigurator configureConversationCell:conversation indexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:messageCellName forIndexPath:indexPath];
        UILabel *message1 = (UILabel *)[cell viewWithTag:50];
        message1.text = [ChatLocal translate:@"NoConversationsYet"];
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *conversations = self.conversationsHandler.archivedConversations;
    ChatConversation *selectedConversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
    self.selectedConversationId = selectedConversation.conversationId;
    if (selectedConversation.isDirect) {
        self.selectedRecipientId = selectedConversation.conversWith;
        self.selectedRecipientFullname = selectedConversation.conversWith_fullname;
    }
    else {
        self.selectedGroupId = selectedConversation.recipient;
        self.selectedGroupName = selectedConversation.recipientFullname;
    }
    if (selectedConversation.status == CONV_STATUS_FAILED) {
        // TODO
        NSLog(@"CONV_STATUS_FAILED. Not implemented. Re-start group creation workflow");
        return;
    }
    
    selectedConversation.is_new = NO;
    // instantly updates the conversation in memory & local db
    [self.conversationsHandler updateLocalConversation:selectedConversation completion:nil];
    // instantly updates the conversation status on tableView's cell
    [ChatConversationsVC updateReadStatusForConversationCell:selectedConversation atIndexPath:indexPath inTableView:self.tableView];
    ChatManager *chatm = [ChatManager getInstance];
    [chatm updateConversationIsNew:selectedConversation.ref is_new:selectedConversation.is_new];
    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CHAT_SEGUE"]) {
        ChatMessagesVC *vc = (ChatMessagesVC *)[segue destinationViewController];
        // conversationsHandler will update status of new conversations (they come with is_new = true) with is_new = false (because the conversation is open and so new messages are all read)
        self.conversationsHandler.currentOpenConversationId = self.selectedConversationId;
        if (self.selectedRecipientId) {
            ChatUser *recipient = [[ChatUser alloc] init:self.selectedRecipientId fullname:self.selectedRecipientFullname];
            vc.recipient = recipient;
        }
        else {
            vc.recipient = nil;
        }
        if (self.selectedGroupId) {
            NSLog(@"SELECTED GROUP ID: %@", self.selectedGroupId);
            vc.group = [[ChatManager getInstance] groupById:self.selectedGroupId];
            NSLog(@"vc.group: %@", vc.group);
            if (!vc.group) {
                // GROUP INFO NOT FOUND. GROUPS STILL NOT SYNCHONIZED OR I'M HERE
                // BECAUSE A PUSH NOTIFICATION THAT STARTED THE APPLICATION (AND THE GROUP WASN'T STILL SYNCHRONIZED)
                ChatGroup *temporaryGroup = [[ChatGroup alloc] init];
                temporaryGroup.name = self.selectedGroupName;
                temporaryGroup.groupId = self.selectedGroupId;
                //                emptyGroup.members = nil; // signals no group metadata
                NSString *me = [ChatManager getInstance].loggedUser.userId;
                NSMutableArray *membersIDs = [[NSMutableArray alloc] init];
                [membersIDs addObject:me]; // always add me
                temporaryGroup.members = [ChatGroup membersArray2Dictionary:membersIDs];
                
                vc.group = temporaryGroup;
            }
        }
        [self resetSelectedConversationStatus];
    }
}

-(void)resetSelectedConversationStatus {
    self.selectedRecipientId = nil;
    self.selectedRecipientFullname = nil;
    self.selectedGroupId = nil;
}

@end
