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
#import "ChatConversationHandler.h"
#import "ChatGroupsHandler.h"
#import "ChatGroup.h"
#import "ChatImageCache.h"
#import "ChatPresenceHandler.h"
#import "ChatImageWrapper.h"
#import "ChatTitleVC.h"
#import "ChatMessagesVC.h"
#import "CellConfigurator.h"
#import "ChatStatusTitle.h"
#import "ChatSelectUserLocalVC.h"
#import "ChatSelectGroupMembersLocal.h"
#import "ChatSelectGroupLocalTVC.h"
//#import "HelpFacade.h"
#import "ChatConnectionStatusHandler.h"
#import "ChatUIManager.h"
#import "ChatMessage.h"
#import "ChatLocal.h"

@interface ChatConversationsVC ()
- (IBAction)writeToAction:(id)sender;

@end

@implementation ChatConversationsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //autodim
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    NSLog(@"Conversations viewDidLoad start");
    
    self.settings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]];
    
    [self initImageCache];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.groupsMode =  [ChatManager getInstance].groupsMode;

//    [self backButtonSetup];
    [self customizeTitleView];
    [self setupTitle:@"Chat"];
    [self setUIStatusDisconnected];
    if (!self.isModal) {
        // hide cancel button
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        // show and translate cancel button
        self.cancelButton.title = [ChatLocal translate:@"cancel"];
    }
//    [[HelpFacade sharedInstance] activateSupportBarButton:self];
}

//-(void)customizeRightBarButton {
//    UIImage* image = [UIImage imageNamed:@"chat_mrlupo.png"];
//    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
//    UIButton *imageButton = [[UIButton alloc] initWithFrame:frameimg];
//    [imageButton setBackgroundImage:image forState:UIControlStateNormal];
//    [imageButton addTarget:self action:@selector(writeToSupport)
//         forControlEvents:UIControlEventTouchUpInside];
//    //[imageButton setShowsTouchWhenHighlighted:YES];
//
//    UIBarButtonItem *rightbutton =[[UIBarButtonItem alloc] initWithCustomView:imageButton];
//    self.navigationItem.rightBarButtonItem=rightbutton;
//}

//-(void)writeToSupport {
//    NSLog(@"New message to Support.");
//    NSString *botuser = [self.settings objectForKey:@"botuser"];
//    NSString *fakeuser = [self.settings objectForKey:@"fakeuser"];
//
//    if ([self.applicationContext.loggedUser.username isEqualToString:botuser] ||
//        [self.applicationContext.loggedUser.username isEqualToString:fakeuser]) {
//        [self performSegueWithIdentifier:@"SelectUser" sender:self];
//    } else {
//        [self openConversationWithRecipient:botuser];
//    }
//}

// ------------------------------
// --------- USER INFO ----------
// ------------------------------
//-(void)getAllUserInfo {
//    [self.userLoader findByUsername:self.me.username];
//}

////DELEGATE
////--------------------------------------------------------------------//
//-(void)usersDidLoad:(NSArray *)__users error:(NSError *)error
//{
//    NSLog(@"usersDidLoad: %@ - %@",__users, error);
//    SHPUser *tmp_user;
//    if(__users.count > 0) {
//        tmp_user = [__users objectAtIndex:0];
//        self.applicationContext.loggedUser.fullName = tmp_user.fullName;
//        self.applicationContext.loggedUser.email = tmp_user.fullName;
//        // get company
//        NSArray *parts = [tmp_user.email componentsSeparatedByString: @"@"];
//        NSString *domain;
//        if (parts.count > 0) {
//            domain = [parts lastObject];
//            // SOLO IN QUESTA VISTA VENGONO RINFRESCATI E SALVATI
//            // I DATI DELL'UTENTE CONNESSO
//            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
//            NSMutableDictionary *userData = [[NSMutableDictionary  alloc] init];
//            [userData setObject:tmp_user.email forKey:@"email"];
//            [userData setObject:tmp_user.fullName forKey:@"fullName"];
//            // save chat domain.
//            [defaults setObject:domain forKey:@"userChatDomain"];
//            NSString *userKey = [[NSString alloc] initWithFormat:@"usrKey-%@", self.applicationContext.loggedUser.username];
//            [defaults setObject:userData forKey:userKey];
////            // get
////            NSString *fullName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userFullName"];
//            [defaults synchronize];
//        }
//        // save user in NSUserDefaults
//        NSLog(@"User full name: %@", tmp_user.fullName);
//        // updateTitle
//        [self changeTitle];
//    } else {
//    }
//}
// ------------------------------------
// --------- USER INFO END ------------
// ------------------------------------

//-(void)isStatusConnected {
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    FIRDatabaseReference *connectedRef = [rootRef child:url];
//
//    // once
//    [connectedRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        // Get user value
//        NSLog(@"SNAPSHOT ONCE %@ - %d", snapshot, [snapshot.value boolValue]);
//        if([snapshot.value boolValue]) {
//            NSLog(@"..connected once..");
//            // come giu, rifattorizzare
//            [self setUIStatusConnected];
//        }
//        else {
//            NSLog(@"..not connected once..");
//            [self setUIStatusDisconnected];
//        }
//    } withCancelBlock:^(NSError * _Nonnull error) {
//        NSLog(@"%@", error.localizedDescription);
//    }];
//}

//-(void)setupConnectionStatus {
//    NSLog(@"Connection status.");
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    FIRDatabaseReference *connectedRef = [rootRef child:url];
//
//    // event
//    if (!self.connectedRefHandle) {
//        self.connectedRefHandle = [connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
//            NSLog(@"snapshot %@ - %d", snapshot, [snapshot.value boolValue]);
//            if([snapshot.value boolValue]) {
//                NSLog(@".connected.");
//                [self setUIStatusConnected];
//            } else {
//                NSLog(@".not connected.");
//                [self setUIStatusDisconnected];
//            }
//        }];
//    }
//}

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
    NSLog(@"CUSTOMIZING TITLE VIEW");
    
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"status_title_ios11" owner:self options:nil];
    ChatStatusTitle *view = [subviewArray objectAtIndex:0];
//    view.frame = CGRectMake(0, 0, 200, 40);
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

//-(void)backButtonSetup {
//    if (!self.backButton) {
//        self.backButton = [[UIBarButtonItem alloc]
//                           initWithTitle:@"Chat"
//                           style:UIBarButtonItemStylePlain
//                           target:self
//                           action:@selector(backButtonClicked:)];
//    }
//    self.navigationItem.backBarButtonItem = self.backButton;
//}

-(void)backButtonClicked:(UIBarButtonItem*)sender
{
    NSLog(@"Back");
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [self removeSubscribers];
    }
}
     
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Conversations viewDidAppear");
    
    ChatManager *chat = [ChatManager getInstance];
    [chat.connectionStatusHandler isStatusConnectedWithCompletionBlock:^(BOOL connected, NSError *error) {
        if (connected) {
            [self setUIStatusConnected];
        }
        else {
            [self setUIStatusDisconnected];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"Conversations viewWillAppear");
    
    [self initializeWithSignedUser];
    
    [self resetCurrentConversation];
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
//    if (loggedUser && !self.me) { // > just signed in / first load after startup
//        self.me = loggedUser;
//        [self initChat];
//        [self.tableView reloadData];
//    }
//    else if (loggedUser && ![self.me.userId isEqualToString:loggedUserId]) {
//        // user changed
//        NSLog(@"User changed. Logged user is %@/%@ while self.me is %@/%@", loggedUser.userId, loggedUser.fullname, self.me.userId, self.me.fullname);
//        [self logout];
//        self.me = loggedUser;
//        [self initChat];
//        [self.tableView reloadData];
//    }
//    else if (!loggedUser && self.me) {
//        NSAssert(false, @"You just signed out so you can't be here! This code must be unreacheable!");
//        NSLog(@"**** You just logged out! Disposing current chat handlers...");
//        // DEPRECATED
//        self.me = nil;
//        self.conversationsHandler = nil;
////        ChatManager *chat = [ChatManager getInstance];
////        [chat dispose];
//        NSLog(@"reloadData !loggedUser && self.me");
//        [self.tableView reloadData];
//    }
//    else if (!loggedUser) { // logged out
//        NSAssert(false, @"Signed out you can't be here! This code must be unreacheable!");
//        NSLog(@"**** User still not logged in.");
//        // DEPRECATED
//        // not signed in
//        // do nothing
//    }
    else if (loggedUser && [loggedUserId isEqualToString:self.me.userId]) {
        NSLog(@"**** You are logged in with the same user. Do nothing.");
    }
}

-(void)initChat {
    [self initConversationsHandler];
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
    ChatConversationsHandler *handler = [chatm getConversationsHandler];
    NSLog(@"Conversations Handler instance already set.");
    [self subscribe:handler];
    self.conversationsHandler = handler;
}

//-(void)initConversationsHandler {
//    ChatManager *chatm = [ChatManager getInstance];
//    ChatConversationsHandler *handler = chatm.conversationsHandler; // [chatm getConversationsHandler];
//    if (!handler) {
//        NSLog(@"Conversations Handler not found. Creating & initializing a new one.");
//        handler = [chat createConversationsHandler];
//        self.conversationsHandler = handler;
//        [self subscribe:handler];
//
//        NSLog(@"Restoring DB archived conversations...");
//        [handler restoreConversationsFromDB];
//        NSLog(@"%lu archived conversations restored", (unsigned long)self.conversationsHandler.conversations.count);
//        [self update_unread];
//
//        NSLog(@"Connecting handler...");
//        [handler connect];
//    } else {
//        NSLog(@"Conversations Handler instance already set.");
//        [self subscribe:handler];
//        self.conversationsHandler = handler;
//    }
//}

-(void)subscribe:(ChatConversationsHandler *)handler {
    if (self.added_handle > 0) {
        NSLog(@"Subscribe(): just subscribed to conversations handler. Do nothing.");
        return;
    }
    NSLog(@"Subscribing to conversationsHandler");
    self.added_handle = [handler observeEvent:ChatEventConversationAdded withCallback:^(ChatConversation *conversation) {
        [self conversationReceived:conversation];
    }];
    self.changed_handle = [handler observeEvent:ChatEventConversationChanged withCallback:^(ChatConversation *conversation) {
        [self conversationReceived:conversation];
    }];
    self.deleted_handle = [handler observeEvent:ChatEventConversationDeleted withCallback:^(ChatConversation *conversation) {
        [self conversationDeleted:conversation];
    }];
    NSLog(@"Subscription handles: added_handle = %lu, changed_handle = %lu, deleted_handle = %lu", (unsigned long)self.added_handle, (unsigned long)self.changed_handle, (unsigned long)self.deleted_handle);
}

-(void)removeSubscribers {
    [self.conversationsHandler removeObserverWithHandle:self.added_handle];
    [self.conversationsHandler removeObserverWithHandle:self.changed_handle];
    [self.conversationsHandler removeObserverWithHandle:self.deleted_handle];
    self.added_handle = 0;
    self.changed_handle = 0;
    self.deleted_handle = 0;
    ChatManager *chatm = [ChatManager getInstance];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.connectedHandle];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.disconnectedHandle];
    self.connectedHandle = 0;
    self.disconnectedHandle = 0;
}

//-(void)initContactsSynchronizer {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatContactsSynchronizer *synchronizer = chat.contactsSynchronizer;
//    if (!synchronizer) {
//        NSLog(@"Contacts Synchronizer not found. Creating & initializing a new one.");
//        synchronizer = [chat createContactsSynchronizerForUser:self.me];
//        [synchronizer startSynchro];
//    } else {
//        [synchronizer startSynchro];
//    }
//}

//-(void)initPresenceHandler {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatPresenceHandler *handler = chat.presenceHandler;
//    if (!handler) {
//        NSLog(@"Presence Handler not found. Creating & initializing a new one.");
//        handler = [chat createPresenceHandlerForUser:self.me];
//        handler.delegate = self;
//        self.presenceHandler = handler;
//        NSLog(@"Connecting handler to firebase.");
//        [self.presenceHandler setupMyPresence];
//    }
//}

//-(void)initGroupsHandler {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatGroupsHandler *handler = chat.groupsHandler;
//    if (!handler) {
//        NSLog(@"Groups Handler not found. Creating & initializing a new one.");
//        handler = [chat createGroupsHandlerForUser:self.me];
//        [handler restoreGroupsFromDB]; // not thread-safe, call this method before firebase synchronization start
//        [handler connect]; // firebase synchronization starts
//    }
//}

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
    NSLog(@"Deleting conversation...");
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
        
//        UIImage *userImage = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
//        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:conversation.sender];
//        ChatImageWrapper *cached_image_wrap = [self.imageCache getImage:imageURL];
//        UIImage *cached_image = cached_image_wrap.image;
//        UIImage *_circled_cached_image = [SHPImageUtil circleImage:cached_image];
//        if(_circled_cached_image) {
//            userImage = _circled_cached_image;
//        }
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
}

#pragma mark - Table view data source

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"commitEditingStyle");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        NSString *title = [ChatLocal translate:@"DeleteConversationTitle"];
        NSString *msg = [ChatLocal translate:@"DeleteConversationMessage"];
        NSString *cancel = [ChatLocal translate:@"CancelLKey"];
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:@"OK", nil];
        self.removingConversationAtIndexPath = indexPath;
        [alertView show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
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
    if (indexPath.section == 0) {
        if (self.groupsMode) {
            return 44;
        } else {
            return 0;
        }
    }
    return UITableViewAutomaticDimension;// else 70;//
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *menuCellName = @"menuCell";
    static NSString *messageCellName = @"MessageCell";
    
    UITableViewCell *cell;
    NSArray *conversations = self.conversationsHandler.conversations;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:menuCellName forIndexPath:indexPath];
        // Chat
        UIButton *new_group_button = [cell viewWithTag:10];
        [new_group_button setTitle:[ChatLocal translate:@"NewGroup"] forState:UIControlStateNormal];
        UIButton *groups_button = [cell viewWithTag:20];
        [groups_button setTitle:[ChatLocal translate:@"Groups"] forState:UIControlStateNormal];
    }
    else if (indexPath.section == 1) {
        if (conversations && conversations.count > 0) {
            ChatConversation *conversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
//            NSLog(@"Conversation.sender %@", conversation.sender);
            cell = [CellConfigurator configureConversationCell:conversation tableView:tableView indexPath:indexPath conversationsVC:self];
        } else {
            NSLog(@"*conversations.count = 0");
            NSLog(@"Rendering NO CONVERSATIONS CELL...");
            cell = [tableView dequeueReusableCellWithIdentifier:messageCellName forIndexPath:indexPath];
            UILabel *message1 = (UILabel *)[cell viewWithTag:50];
            message1.text = [ChatLocal translate:@"NoConversationsYet"];
            cell.userInteractionEnabled = NO;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) { // toolbar
        return;
    }
    NSArray *conversations = self.conversationsHandler.conversations;
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
    ChatManager *chatm = [ChatManager getInstance];
    [chatm updateConversationIsNew:selectedConversation.ref is_new:selectedConversation.is_new];
    
    
    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CHAT_SEGUE"]) {
        NSLog(@"Preparing chat_segue...");
        ChatMessagesVC *vc = (ChatMessagesVC *)[segue destinationViewController];
        
        NSLog(@"vc %@", vc);
        // conversationsHandler will update status of new conversations (they come with is_new = true) with is_new = false (because the conversation is open and so new messages are all read)
        self.conversationsHandler.currentOpenConversationId = self.selectedConversationId;
        NSLog(@"self.selectedConversationId = %@", self.selectedConversationId);
        NSLog(@"self.conversationsHandler.currentOpenConversationId = %@", self.selectedConversationId);
        NSLog(@"self.selectedRecipient: %@", self.selectedRecipientId);
        if (self.selectedRecipientId) {
            ChatUser *recipient = [[ChatUser alloc] init:self.selectedRecipientId fullname:self.selectedRecipientFullname];
            vc.recipient = recipient;
        }
        else {
            vc.recipient = nil;
        }
        if (self.selectedGroupId) {
            vc.group = [[ChatManager getInstance] groupById:self.selectedGroupId];
            NSLog(@"INFO GROUP OK: %@", vc.group.name);
            if (!vc.group) {
                NSLog(@"INFO X GRUPPO %@ NON TROVATE. PROBABILMENTE GRUPPI NON ANCORA SINCRONIZZATI. CARICO INFO GRUPPO DIRETTAMENTE DA VISTA MESSAGGI (CON ID GRUPPO)", self.selectedGroupId);
                ChatGroup *emptyGroup = [[ChatGroup alloc] init];
                emptyGroup.name = self.selectedGroupName;
                emptyGroup.members = nil; // signals no group metadata
                emptyGroup.groupId = self.selectedGroupId;
                vc.group = emptyGroup;
            }
        }
        vc.unread_count = self.unread_count;
        vc.textToSendAsChatOpens = self.selectedRecipientTextToSend;
        vc.attributesToSendAsChatOpens = self.selectedRecipientAttributesToSend;
        [self resetSelectedConversationStatus];
    }
//    else if ([[segue identifier] isEqualToString:@"SelectUser"]) {
//        UINavigationController *navigationController = [segue destinationViewController];
//        ChatSelectUserLocalVC *vc = (ChatSelectUserLocalVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.modalCallerDelegate = self;
//    }
//    else if ([[segue identifier] isEqualToString:@"CreateGroup"]) {
//        NSLog(@"CreateGroup");
////        NSString *newGroupId = [[ChatManager getInstance] newGroupId];
////        [self.applicationContext setVariable:@"newGroupId" withValue:newGroupId];
////        NSLog(@"Creating group with ID: %@", newGroupId);
//        UINavigationController *navigationController = [segue destinationViewController];
//        SHPChatCreateGroupVC *vc = (SHPChatCreateGroupVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.modalCallerDelegate = self;
//    }
//    else if ([[segue identifier] isEqualToString:@"ChooseGroup"]) {
//        UINavigationController *navigationController = [segue destinationViewController];
//        ChatSelectGroupLocalTVC *vc = (ChatSelectGroupLocalTVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.modalCallerDelegate = self;
//    }
}

-(void)openConversationWithUser:(ChatUser *)user {
    [self openConversationWithUser:user orGroup:nil sendMessage:nil attributes:nil];
}

-(void)openConversationWithUser:(ChatUser *)user orGroup:(ChatGroup *)group sendMessage:(NSString *)text attributes:(NSDictionary *)attributes {
    NSLog(@"Opening conversation with recipient: %@ or group: %@", user.userId, group.groupId);
    [self loadViewIfNeeded];
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.selectedRecipientTextToSend = text;
    if (user) {
        self.selectedRecipientId = user.userId;
        self.selectedRecipientFullname = user.fullname;
        self.selectedConversationId = user.userId;
        self.selectedRecipientAttributesToSend = attributes;
    }
    else {
        self.selectedGroupId = group.groupId;
        self.selectedGroupName = group.name;
        self.selectedConversationId = group.groupId;
    }
    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
}

-(void)resetCurrentConversation {
    NSLog(@"resetting current conversationId");
    self.conversationsHandler.currentOpenConversationId = nil;
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

//- (void)startIconDownload:(NSString *)imageURL forIndexPath:(NSIndexPath *)indexPath
//{
////    NSString *imageURL = [SHPUser photoUrlByUsername:username];
//    NSLog(@"START DOWNLOADING IMAGE: %@", imageURL);
//    SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:imageURL];
//    //    NSLog(@"IconDownloader..%@", iconDownloader);
//    if (iconDownloader == nil)
//    {
//        iconDownloader = [[SHPImageDownloader alloc] init];
//        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
//        [options setObject:indexPath forKey:@"indexPath"];
//        iconDownloader.options = options;
//        iconDownloader.imageURL = imageURL;
//        iconDownloader.delegate = self;
//        [self.imageDownloadsInProgress setObject:iconDownloader forKey:imageURL];
//        [iconDownloader startDownload];
//    }
//}

//- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *imageURL = [SHPUser photoUrlByUsername:username];
//    NSLog(@"START DOWNLOADING IMAGE: %@ imageURL: %@", username, imageURL);
//    SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:imageURL];
//    //    NSLog(@"IconDownloader..%@", iconDownloader);
//    if (iconDownloader == nil)
//    {
//        iconDownloader = [[SHPImageDownloader alloc] init];
//        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
//        [options setObject:indexPath forKey:@"indexPath"];
//        iconDownloader.options = options;
//        iconDownloader.imageURL = imageURL;
//        iconDownloader.delegate = self;
//        [self.imageDownloadsInProgress setObject:iconDownloader forKey:imageURL];
//        [iconDownloader startDownload];
//    }
//}

//// callback for the icon loaded
//- (void)appImageDidLoad:(UIImage *)image withURL:(NSString *)imageURL downloader:(SHPImageDownloader *)downloader {
//    NSLog(@"+******** IMAGE AT URL: %@ DID LOAD: %@", imageURL, image);
//    if (!image) {
//        return;
//    }
//    //UIImage *circled = [SHPImageUtil circleImage:image];
//    [self.imageCache addImage:image withKey:imageURL];
//    NSDictionary *options = downloader.options;
//    NSIndexPath *indexPath = [options objectForKey:@"indexPath"];
////    NSLog(@"+******** appImageDidLoad row: %ld", indexPath.row);
//
//    // if the cell for the image is visible updates the cell
//    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *index in indexes) {
//        if (index.row == indexPath.row && index.section == indexPath.section) {
//            UITableViewCell *cell = [(UITableView *)self.tableView cellForRowAtIndexPath:index];
//            UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
//            iv.image = [SHPImageUtil circleImage:image];
//        }
//    }
//    [self.imageDownloadsInProgress removeObjectForKey:imageURL];
//}

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

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
            // cancel
            NSLog(@"Delete canceled");
            break;
        }
        case 1:
        {
            // ok
            NSLog(@"Deleting conversation...");
            NSInteger conversationIndex = self.removingConversationAtIndexPath.row;
            [self removeConversationAtIndex:conversationIndex];
        }
    }
}

-(void)removeConversationAtIndex:(NSInteger)conversationIndex {
    ChatConversation *removingConversation = (ChatConversation *)[self.conversationsHandler.conversations objectAtIndex:conversationIndex];
    NSLog(@"Removing conversation id %@ / ref %@",removingConversation.conversationId, removingConversation.ref);
    
    [self.tableView beginUpdates];
    ChatManager *chat = [ChatManager getInstance];
    [chat removeConversation:removingConversation];
    [self.conversationsHandler.conversations removeObjectAtIndex:conversationIndex];
    [self.tableView deleteRowsAtIndexPaths:@[self.removingConversationAtIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    /* http://stackoverflow.com/questions/5454708/nsinternalinconsistencyexception-invalid-number-of-rows
     If you delete the last row in your table, the UITableView code expects there to be 0 rows remaining. It
     calls your UITableViewDataSource methods to determine how many are left. Since you have a "No data"
     cell, it returns 1, not 0. So when you delete the last row in your table, try calling
     insertRowsAtIndexPaths:withRowAnimation: to insert your "No data" row.
     */
    if (self.conversationsHandler.conversations.count <= 0) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:self.removingConversationAtIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    
    [self update_unread];
    
    // verify
    ChatConversation *conv = [[ChatDB getSharedInstance] getConversationById:removingConversation.conversationId];
    NSLog(@"Verifying conv %@", conv);
    NSArray *messages = [[ChatDB getSharedInstance] getAllMessagesForConversation:removingConversation.conversationId];
    NSLog(@"resting messages count %lu", (unsigned long)messages.count);
}

-(void)disposeResources {
//    [self terminatePendingImageConnections];
}

//-(void)printDBConvs {
//    NSString *current_user = self.me.userId;
//    NSLog(@"Conversations for user %@...", current_user);
//    NSArray *convs = [[ChatDB getSharedInstance] getAllConversations];//ForUser:current_user];
//    for (ChatConversation *conv in convs) {
//        NSLog(@"[%@] new?%d sender:%@ recip: %@ groupId: %@ \"%@\"", conv.conversationId, conv.is_new, conv.sender, conv.recipient, conv.groupId, conv.last_message_text);
//    }
//}

//-(void)printDBGroups {
//    NSString *current_user = [ChatManager getSharedInstance].loggedUser.userId;
//    NSLog(@"Groups for user %@...", current_user);
//    NSArray *groups = [[ChatGroupsDB getSharedInstance] getAllGroupsForUser:current_user];
//    NSLog(@"GROUPS >>");
//    for (ChatGroup *g in groups) {
//        NSLog(@"ID:%@ NAME:%@ OWN:%@ MBRS:%@", g.groupId, g.name, g.owner, [ChatGroup membersDictionary2String:g.members]);
//    }
//}

//- (void)setupViewController:(UIViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo {
//    NSLog(@"setupViewController...");
//    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
//    {
//        ChatUser *user = nil;
//        if ([setupInfo objectForKey:@"user"]) {
//            user = [setupInfo objectForKey:@"user"];
//            NSLog(@">>>>>> SELECTED: user %@", user.userId);
//        }
//        [self dismissViewControllerAnimated:YES completion:^{
//            if (user) {
////                self.selectedRecipientFullname = user.fullname;
//                [self openConversationWithUser:user];
//            }
//        }];
//    }
//    if([controller isKindOfClass:[ChatSelectGroupLocalTVC class]])
//    {
//        ChatGroup *group = nil;
//        if ([setupInfo objectForKey:@"group"]) {
//            group = [setupInfo objectForKey:@"group"];
//            NSLog(@">>>>>> SELECTED: group %@", group.groupId);
//        }
//        [self dismissViewControllerAnimated:YES completion:^{
//            if (group) {
//                self.selectedGroupId = group.groupId;
//                [self openConversationWithUser:nil orGroup:group.groupId sendMessage:nil attributes:nil];
//            }
//        }];
//    }
//    else if([controller isKindOfClass:[ChatSelectGroupMembersLocal class]])
//    {
//        [self dismissViewControllerAnimated:YES completion:nil];
//        NSMutableArray<ChatUser *> *groupMembers = (NSMutableArray<ChatUser *> *)[setupInfo objectForKey:@"groupMembers"];
//        NSMutableArray *membersIDs = [[NSMutableArray alloc] init];
//        for (ChatUser *u in groupMembers) {
//            [membersIDs addObject:u.userId];
//        }
//        // adding group's owner to members
//        [membersIDs addObject:self.me.userId];
//        NSString *groupId = (NSString *)[setupInfo objectForKey:@"newGroupId"];
//        NSLog(@"New Group ID: %@", groupId);
//        NSString *groupName = (NSString *)[setupInfo objectForKey:@"groupName"];
//        NSLog(@"New Group Name: %@", groupName);
//        ChatManager *chat = [ChatManager getInstance];
//        [chat createGroup:groupId name:groupName owner:self.me.userId members:membersIDs];
//    }
//}

//- (void)setupViewController:(UIViewController *)controller didCancelSetupWithInfo:(NSDictionary *)setupInfo {
//    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
//    {
//        NSLog(@"User selection Canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//    else if([controller isKindOfClass:[SHPChatCreateGroupVC class]])
//    {
//        NSLog(@"Group creation canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//    else
//    if([controller isKindOfClass:[ChatSelectGroupLocalTVC class]])
//    {
//        NSLog(@"Group selection canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//}

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
