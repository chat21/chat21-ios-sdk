//
//  ChatConversationsVC.m
//  Soleto
//
//  Created by Andrea Sponziello on 07/11/14.
//

#import "ChatConversationsVC.h"
#import "ChatConversation.h"
#import "ChatUtil.h"
#import "ChatConversationsHandler.h"
#import "ChatManager.h"
#import "ChatDB.h"
#import "ChatGroupsDB.h"
//#import "ChatConversationHandler.h"
#import "ChatGroupsHandler.h"
#import "ChatGroup.h"
#import "ChatImageCache.h"
#import "ChatPresenceHandler.h"
#import "ChatImageWrapper.h"
#import "ChatTitleVC.h"
#import "ChatMessagesVC.h"
#import "CellConfigurator.h"
#import "ChatStatusTitle.h"
#import "ChatSelectGroupMembersLocal.h"
#import "ChatSelectGroupLocalTVC.h"
//#import "HelpFacade.h"
#import "ChatConnectionStatusHandler.h"
#import "ChatUIManager.h"
#import "ChatMessage.h"
#import "ChatLocal.h"
#import "ChatService.h"
#import "ChatDiskImageCache.h"

@interface ChatConversationsVC ()
- (IBAction)writeToAction:(id)sender;

@end

@implementation ChatConversationsVC {
    BOOL performSelectedConversationOnAppear;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //autodim
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    NSLog(@"Conversations viewDidLoad start");
    
    self.settings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]];
    
    self.imageCache = [ChatManager getInstance].imageCache;
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.groupsMode =  [ChatManager getInstance].groupsMode;
    
    [self customizeTitleView];
    [self setupTitle:@"Chat"];
    [self setUIStatusDisconnected];
//    self.isModal = true;
    if (!self.isModal && !self.navigationController.presentingViewController) {
        // preserve centered title if no left barbutton is shown
        UIBarButtonItem *emptyButton = [[UIBarButtonItem alloc] initWithTitle:@"                    " style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.leftBarButtonItem = emptyButton;
    } else if (self.isModal) {
        // show and translate cancel button
        self.cancelButton.title = [ChatLocal translate:@"cancel"];
    }
    
    // right toolbar
    UIImage *archived_image = [UIImage imageNamed:@"baseline_history_black_24pt"];
    UIImage *write_to_image = [UIImage imageNamed:@"baseline_create_black_24pt"];
    
    UIBarButtonItem *archived_button = [[UIBarButtonItem alloc] initWithImage:archived_image style:UIBarButtonItemStylePlain target:self action:@selector(archived_action:)];
    UIBarButtonItem *write_to_button = [[UIBarButtonItem alloc] initWithImage:write_to_image style:UIBarButtonItemStylePlain target:self action:@selector(write_to_action:)];
    
    self.navigationItem.rightBarButtonItems = @[write_to_button, archived_button];
    performSelectedConversationOnAppear = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"dm_conversation_cell" bundle:nil] forCellReuseIdentifier:@"conversationDMCell"];
    // conversationGroupCell
    [self.tableView registerNib:[UINib nibWithNibName:@"group_conversation_cell" bundle:nil] forCellReuseIdentifier:@"conversationGroupCell"];
}

-(void)archived_action:(id)sender {
    NSLog(@"archived action");
    [[ChatUIManager getInstance] pushArchivedConversationsView:self];
}

-(void)write_to_action:(id)sender {
    [self writeToAction:sender];
}

-(void)setUIStatusConnected {
    self.usernameButton.hidden = NO;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = [ChatLocal translate:@"ChatConnected"];
}

-(void)setUIStatusDisconnected {
    self.usernameButton.hidden = YES;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    self.statusLabel.text = [ChatLocal translate:@"ChatDisconnected"];
}

-(void)customizeTitleView {
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"status_title_ios11" owner:self options:nil];
    ChatStatusTitle *view = [subviewArray objectAtIndex:0];
    self.usernameButton = view.usernameButton;
    self.statusLabel = view.statusLabel;
    self.activityIndicator = view.activityIndicator;
    self.navigationItem.titleView = view;
}

-(void)setupTitle:(NSString *)title {
    [self.usernameButton setTitle:title forState:UIControlStateNormal];
}

-(void)changeTitle {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *title = (NSString *)[defaults objectForKey:@"userChatDomain"];
    if (!title) {
        title = @"Chat";
    }
    [self setupTitle:title];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeWithSignedUser];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.selectedConversationIndexPath != nil) {
        [self.tableView deselectRowAtIndexPath:self.selectedConversationIndexPath animated:YES];
        self.selectedConversationIndexPath = nil;
    }
    
    ChatManager *chat = [ChatManager getInstance];
    [chat.connectionStatusHandler isStatusConnectedWithCompletionBlock:^(BOOL connected, NSError *error) {
        if (connected) {
            [self setUIStatusConnected];
        }
        else {
            [self setUIStatusDisconnected];
        }
    }];
    
    if (performSelectedConversationOnAppear) {
        [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
        performSelectedConversationOnAppear = NO;
    }
    else {
        [self resetCurrentConversation];
    }
    
    [self update_unread];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [self removeSubscribers];
    }
}

-(void)initializeWithSignedUser {
    ChatManager *chat = [ChatManager getInstance];
    ChatUser *loggedUser = chat.loggedUser;
    NSString *loggedUserId = loggedUser.userId;
    if ((loggedUser && !self.me) || // > just signed in / first load after startup
        (loggedUser && ![self.me.userId isEqualToString:loggedUserId])) { // user changed
        [self removeSubscribers];
        self.conversationsHandler = nil;
        self.me = loggedUser;
        [self initChat];
        [self.tableView reloadData];
    }
}

-(void)initChat {
    [self initConversationsHandler];
    self.cellConfigurator = [[CellConfigurator alloc] initWithTableView:self.tableView imageCache:self.imageCache conversations:self.conversationsHandler.conversations];
//    self.cellConfigurator.conversations = self.conversationsHandler.conversations;
    [self setupConnectionStatusHandler];
}

-(void)setupConnectionStatusHandler {
    ChatManager *chat = [ChatManager getInstance];
    ChatConnectionStatusHandler *connectionStatusHandler = chat.connectionStatusHandler;
    if (connectionStatusHandler) {
        self.connectedHandle = [connectionStatusHandler observeEvent:ChatConnectionStatusEventConnected withCallback:^{
            [self setUIStatusConnected];
        }];
        self.disconnectedHandle = [connectionStatusHandler observeEvent:ChatConnectionStatusEventDisconnected withCallback:^{
            [self setUIStatusDisconnected];
        }];
    }
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
    self.added_handle = [handler observeEvent:ChatEventConversationAdded withCallback:^(ChatConversation *conversation) {
        [self conversationReceived:conversation];
    }];
    self.changed_handle = [handler observeEvent:ChatEventConversationChanged withCallback:^(ChatConversation *conversation) {
        [self conversationReceived:conversation];
    }];
    self.read_status_changed_handle = [handler observeEvent:ChatEventConversationReadStatusChanged withCallback:^(ChatConversation *conversation) {
        NSLog(@"Conversation %@ '%@' read status changed to: %d, index: %d", conversation.conversationId, conversation, conversation.is_new, conversation.indexInMemory);
        NSIndexPath* indexPathToReload = [NSIndexPath indexPathForRow:conversation.indexInMemory inSection:SECTION_CONVERSATIONS_INDEX];

        [ChatConversationsVC updateReadStatusForConversationCell:conversation atIndexPath:indexPathToReload inTableView:self.tableView];
    }];
    self.deleted_handle = [handler observeEvent:ChatEventConversationDeleted withCallback:^(ChatConversation *conversation) {
        [self conversationDeleted:conversation];
    }];
}

-(void)removeSubscribers {
    [self.conversationsHandler removeObserverWithHandle:self.added_handle];
    [self.conversationsHandler removeObserverWithHandle:self.changed_handle];
    [self.conversationsHandler removeObserverWithHandle:self.read_status_changed_handle];
    [self.conversationsHandler removeObserverWithHandle:self.deleted_handle];
    self.added_handle = 0;
    self.changed_handle = 0;
    self.read_status_changed_handle = 0;
    self.deleted_handle = 0;
    ChatManager *chatm = [ChatManager getInstance];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.connectedHandle];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.disconnectedHandle];
    self.connectedHandle = 0;
    self.disconnectedHandle = 0;
}

//#protocol SHPConversationsViewDelegate

-(void)didFinishConnect:(ChatConversationsHandler *)handler error:(NSError *)error {
    if (!error) {
        NSLog(@"ChatConversationsHandler Initialization finished with success.");
    } else {
        NSLog(@"ChatConversationsHandler Initialization finished with error: %@", error);
    }
}

//protocol SHPConversationsViewDelegate

-(void)conversationReceived:(ChatConversation *)conversation {
    // STUDIARE: since iOS 5, you can do the move like so:
    // [tableView moveRowAtIndexPath:indexPathOfRowToMove toIndexPath:indexPathOfTopRow];
    
//    NSLog(@"New conversation received %@ by %@ (sender: %@)", conversation.last_message_text, conversation.conversWith_fullname, conversation.sender);
    [self showNotificationWindow:conversation];
    [self.tableView reloadData];
//    [self printAllConversations];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update_unread];
    });
}

-(void)conversationDeleted:(ChatConversation *)conversation {
    NSLog(@"Conversation removed %@ by %@ (sender: %@)", conversation.last_message_text, conversation.conversWith_fullname, conversation.sender);
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update_unread];
    });
}

-(void)showNotificationWindow:(ChatConversation *)conversation {
    NSString *currentConversationId = self.conversationsHandler.currentOpenConversationId;
//    NSLog(@"conversation.is_new: %d", conversation.is_new);
//    NSLog(@"!self.view.window: %d", !self.view.window);
//    NSLog(@"conversation.conversationId: %@", conversation.conversationId);
//    NSLog(@"currentConversationId: %@", currentConversationId);
//    NSLog(@"conversation.is_new && !self.view.window && conversation.conversationId != currentConversationId");
    if ( conversation.is_new
         && !self.view.window // conversationsview hidden
         && conversation.conversationId != currentConversationId ) {
        
        [ChatUIManager showNotificationWithMessage:conversation.last_message_text image:nil sender:conversation.conversWith senderFullname:conversation.conversWith_fullname];
    }
}

-(void)update_unread {
    int count = 0;
    for (ChatConversation *c in self.conversationsHandler.conversations) {
        if (c.is_new) {
            count++;
        }
    }
    self.unread_count = count;
    
    // notify next VC
    if (self.navigationController.viewControllers.count > 1) {
        ChatMessagesVC *nextVC = [self.navigationController.viewControllers objectAtIndex:1];
        if ([nextVC respondsToSelector:@selector(updateUnreadMessagesCount)]) {
            nextVC.unread_count = count;
            [nextVC performSelector:@selector(updateUnreadMessagesCount) withObject:nil];
        }
    }
    if (self.unread_count > 0) {
        [[self navigationController] tabBarItem].badgeValue = [[NSString alloc] initWithFormat:@"%d", self.unread_count];
    } else {
        [[self navigationController] tabBarItem].badgeValue = nil;
    }
}

#pragma mark - Table view data source

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    if (indexPath.section == SECTION_GROUP_MENU_INDEX) {
        return NO;
    }
    return YES;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section != SECTION_CONVERSATIONS_INDEX) {
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
    
    // Archive option
    UITableViewRowAction *archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:[ChatLocal translate:@"ArchiveConversationAction"] handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        NSLog(@"Archiving...");
        NSString *conversationId = conversation.conversationId;
        
        // instantly removes the conversation from memory & local db
        [self.conversationsHandler removeLocalConversation:conversation completion:^{
            [self removeConversationAtIndex:indexPath];
        }];
        // now remotely archives the conversation
        if ([conversationId hasPrefix:@"support-group-"]) {
            NSLog(@"Archiving and closing support conversation...");
            [ChatService archiveAndCloseSupportConversation:conversation completion:^(NSError *error) {
                if (error) {
                    NSLog(@"Archive and Close operation failed with error: %@", error);
                }
                else {
                    NSLog(@"Support conversation %@ successfully archived and closed.", conversation.conversationId);
                }
            }];
        }
        else {
            NSLog(@"Archiving and closing conversation...");
            [ChatService archiveConversation:conversation completion:^(NSError *error) {
                if (error) {
                    NSLog(@"Archive operation failed with error: %@", error);
                }
                else {
                    NSLog(@"Conversation %@ successfully archived.", conversation.conversationId);
                }
            }];
        }
    }];
    archiveAction.backgroundColor = [UIColor colorWithRed:0.286 green:0.439 blue:0.639 alpha:1.0];
    
    // Read option
    NSString *title = [ChatLocal translate:@"ReadConversationAction"];
    title = conversation.is_new ? [ChatLocal translate:@"ReadConversationAction"] : [ChatLocal translate:@"UnreadConversationAction"];
    UITableViewRowAction *readAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSLog(@"Read...");
        BOOL read_stastus = !conversation.is_new;
        conversation.is_new = read_stastus;
        // instantly updates the conversation in memory & local db
        [self.conversationsHandler updateLocalConversation:conversation completion:nil];
        [ChatConversationsVC updateReadStatusForConversationCell:conversation atIndexPath:indexPath inTableView:self.tableView];
        FIRDatabaseReference *conversation_ref = [self.conversationsHandler.conversationsRef child:conversation.conversationId];
        ChatManager *chat = [ChatManager getInstance];
        [chat updateConversationIsNew:conversation_ref is_new:read_stastus];
        [self update_unread];
    }];
    readAction.backgroundColor = [UIColor blueColor];
    return @[readAction, archiveAction];
}

+(void)updateReadStatusForConversationCell:(ChatConversation *)conversation atIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [CellConfigurator changeReadStatus:conversation forCell:cell];
}

//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"commitEditingStyle");
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        //add code here for when you hit delete
//        NSString *title = [ChatLocal translate:@"DeleteConversationTitle"];
//        NSString *msg = [ChatLocal translate:@"DeleteConversationMessage"];
//        NSString *cancel = [ChatLocal translate:@"Cancel"];
//
//        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:@"OK", nil];
//        self.removingConversationAtIndexPath = indexPath;
//        [alertView show];
//    }
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SECTION_GROUP_MENU_INDEX) {
        return 1;
    } else {
        NSArray *conversations = self.conversationsHandler.conversations;
        if (conversations && conversations.count > 0) {
            return conversations.count;
        } else {
            return 1; // message cell
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_GROUP_MENU_INDEX) {
        if (self.groupsMode) {
            return 44;
        } else {
            return 0;
        }
    }
    return 70;//UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *menuCellName = @"menuCell";
    static NSString *messageCellName = @"MessageCell";
    
    UITableViewCell *cell;
    NSArray *conversations = self.conversationsHandler.conversations;
    if (indexPath.section == SECTION_GROUP_MENU_INDEX) {
        cell = [tableView dequeueReusableCellWithIdentifier:menuCellName forIndexPath:indexPath];
        // Chat
        UIButton *new_group_button = [cell viewWithTag:10];
        [new_group_button setTitle:[ChatLocal translate:@"NewGroup"] forState:UIControlStateNormal];
        UIButton *groups_button = [cell viewWithTag:20];
        [groups_button setTitle:[ChatLocal translate:@"Groups"] forState:UIControlStateNormal];
    }
    else if (indexPath.section == SECTION_CONVERSATIONS_INDEX) {
        if (conversations && conversations.count > 0) {
            ChatConversation *conversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
            cell = [self.cellConfigurator configureConversationCell:conversation indexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:messageCellName forIndexPath:indexPath];
            UILabel *message1 = (UILabel *)[cell viewWithTag:50];
            message1.text = [ChatLocal translate:@"NoConversationsYet"];
            cell.userInteractionEnabled = NO;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_GROUP_MENU_INDEX) { // toolbar
        return;
    }
    NSArray *conversations = self.conversationsHandler.conversations;
    ChatConversation *selectedConversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
    self.selectedConversationIndexPath = indexPath;
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
    // instantly updates the conversation in memory & on local db
    [self.conversationsHandler updateLocalConversation:selectedConversation completion:nil];
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
                NSString *me = [ChatManager getInstance].loggedUser.userId;
                NSMutableArray *membersIDs = [[NSMutableArray alloc] init];
                [membersIDs addObject:me]; // always add me
                temporaryGroup.members = [ChatGroup membersArray2Dictionary:membersIDs];
                
                vc.group = temporaryGroup;
            }
        }
        [self update_unread];
        vc.unread_count = self.unread_count;
        vc.textToSendAsChatOpens = self.selectedRecipientTextToSend;
        vc.attributesToSendAsChatOpens = self.selectedRecipientAttributesToSend;
        [self resetSelectedConversationStatus];
    }
}

-(void)openConversationWithUser:(ChatUser *)user {
    [self openConversationWithUser:user orGroup:nil sendMessage:nil attributes:nil];
}

-(void)openConversationWithUser:(ChatUser *)user orGroup:(ChatGroup *)group sendMessage:(NSString *)text attributes:(NSDictionary *)attributes {
    
    NSLog(@"Opening conversation with recipient: %@ or group: %@", user.userId, group.groupId);
    NSLog(@"self.selectedConversationId: %@", self.selectedConversationId);
    NSLog(@"self.conversationsHandler.currentOpenConversationId: %@", self.conversationsHandler.currentOpenConversationId);
    NSString *newConvId;
    if (user != nil) {
        newConvId = user.userId;
    }
    else if (group != nil) {
        newConvId = group.groupId;
    }
    else {
        NSLog(@"ERROR. User and Group can't be both null.");
        return;
    }
    if ([self.selectedConversationId isEqualToString:newConvId]) {
        NSLog(@"Conversation %@ already open. User: %@ group: %@",self.selectedConversationId, user.userId, group.groupId);
        return;
    }
    self.selectedRecipientTextToSend = text;
    self.selectedConversationId = newConvId;
    if (user) {
        self.selectedRecipientId = user.userId;
        self.selectedRecipientFullname = user.fullname;
//        self.selectedConversationId = user.userId;
        self.selectedRecipientAttributesToSend = attributes;
    }
    else {
        self.selectedGroupId = group.groupId;
        self.selectedGroupName = group.name;
//        self.selectedConversationId = group.groupId;
    }
    [self loadViewIfNeeded];
    
    // popViewControllerAnimated completionCallback
//    [CATransaction begin];
//    [CATransaction setCompletionBlock:^{
//        [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
//    }];
//    performSelectedConversationOnAppear = YES;
//    [self.navigationController popViewControllerAnimated:NO];
//    [CATransaction commit];
    
    [self.navigationController popToRootViewControllerAnimated:NO];
//    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
    BOOL isConversationsVCOnscreen = self.view.window != nil;
    if (isConversationsVCOnscreen) {
        [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
    }
    else {
        performSelectedConversationOnAppear = YES;
    }
}

-(void)resetCurrentConversation {
    self.conversationsHandler.currentOpenConversationId = nil;
    self.selectedConversationId = nil;
}

-(void)resetSelectedConversationStatus {
    self.selectedRecipientTextToSend = nil;
    self.selectedRecipientAttributesToSend = nil;
    self.selectedRecipientId = nil;
    self.selectedRecipientFullname = nil;
    self.selectedGroupId = nil;
}

//- (IBAction)testConnectionAction:(id)sender {
//    NSLog(@"test connection status.");
//    [self isStatusConnected];
//}

- (IBAction)newGroupAction:(id)sender {
    NSLog(@"New Group Action");
    [[ChatUIManager getInstance] openCreateGroupViewAsModal:self withCompletionBlock:^(ChatGroup *group, BOOL canceled) {
        if (canceled) {
            NSLog(@"Create group canceled");
        }
        else {
            NSLog(@"Group created. Opening conversation...");
            [self openConversationWithUser:nil orGroup:group sendMessage:nil attributes:nil];
        }
    }];
}

- (IBAction)groupsAction:(id)sender {
//    [self printDBGroups];
//    [self performSegueWithIdentifier:@"ChooseGroup" sender:self];
    [[ChatUIManager getInstance] openSelectGroupViewAsModal:self withCompletionBlock:^(ChatGroup *group, BOOL canceled) {
        if (canceled) {
            NSLog(@"Select group canceled.");
        }
        else {
            if (group) {
                self.selectedGroupId = group.groupId;
                [self openConversationWithUser:nil orGroup:group sendMessage:nil attributes:nil];
            }
        }
    }];
}

// images



//-(void)terminatePendingImageConnections {
//    NSLog(@"''''''''''''''''''''''   Terminate all pending IMAGE connections...");
//    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
////    NSLog(@"total downloads: %d", allDownloads.count);
//    for(SHPImageDownloader *obj in allDownloads) {
//        obj.delegate = nil;
//    }
//    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
//}

// end user images

//- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//    switch (buttonIndex) {
//        case 0:
//        {
//            // cancel
//            NSLog(@"Delete canceled");
//            break;
//        }
//        case 1:
//        {
//            // ok
//            NSLog(@"Deleting conversation...");
//            NSInteger conversationIndex = self.removingConversationAtIndexPath.row;
//            [self removeConversationAtIndex:conversationIndex];
//        }
//    }
//}

-(void)removeConversationAtIndex:(NSIndexPath *)conversationIndexPath {
//    ChatConversation *removingConversation = (ChatConversation *)[self.conversationsHandler.conversations objectAtIndex:conversationIndex];
//    NSLog(@"Removing conversation id %@ / ref %@",removingConversation.conversationId, removingConversation.ref);
    
    [self.tableView beginUpdates];
//    ChatManager *chat = [ChatManager getInstance];
//    [chat removeConversation:removingConversation];
//    [self.conversationsHandler.conversations removeObjectAtIndex:conversationIndex];
    [self.tableView deleteRowsAtIndexPaths:@[conversationIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    /* http://stackoverflow.com/questions/5454708/nsinternalinconsistencyexception-invalid-number-of-rows
     If you delete the last row in your table, the UITableView code expects there to be 0 rows remaining. It
     calls your UITableViewDataSource methods to determine how many are left. Since you have a "No data"
     cell, it returns 1, not 0. So when you delete the last row in your table, try calling
     insertRowsAtIndexPaths:withRowAnimation: to insert your "No data" row.
     */
    if (self.conversationsHandler.conversations.count <= 0) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:conversationIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    
    [self update_unread];
}

-(void)disposeResources {
//    [self terminatePendingImageConnections];
}

- (IBAction)cancelAction:(id)sender {
    NSLog(@"Dismissing Conversations View.");
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.dismissModalCallback) {
            self.dismissModalCallback();
        }
    }];
}

- (IBAction)actionNewMessage:(id)sender {
//    [self performSegueWithIdentifier:@"SelectUser" sender:self];
    
}

-(IBAction)unwindToConversationsView:(UIStoryboardSegue *)sender {
    
//    UIViewController *sourceViewController = sender.sourceViewController;
//    if ([sourceViewController isKindOfClass:[MRCategoryStepTVC class]]) {
//        NSLog(@"Job wizard canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    } else if ([sourceViewController isKindOfClass:[MRPreviewStepTVC class]]) {
//        NSLog(@"job context: %@", self.jobWizardContext);
//    }
//    
    NSLog(@"unwindToConversationsView. no impl.");
    
}

- (IBAction)writeToAction:(id)sender {
//    [self performSegueWithIdentifier:@"SelectUser" sender:self];
    [[ChatUIManager getInstance] openSelectContactViewAsModal:self withCompletionBlock:^(ChatUser *contact, BOOL canceled) {
        if (canceled) {
            NSLog(@"Select Contact canceled");
        }
        else {
            NSLog(@"Selected contact: %@/%@", contact.fullname, contact.userId);
            [self openConversationWithUser:contact];
        }
    }];
}

//- (IBAction)helpAction:(id)sender {
//    NSLog(@"Help in Documents' navigator view");
//    [[HelpFacade sharedInstance] openSupportView:self];
//}

//-(void)helpWizardEnd:(NSDictionary *)context {
//    NSLog(@"helpWizardEnd");
//    [context setValue:NSStringFromClass([self class]) forKey:@"section"];
//    [[HelpFacade sharedInstance] handleWizardSupportFromViewController:self helpContext:context];
//}

@end
