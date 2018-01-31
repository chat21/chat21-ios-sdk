//
//  ChatMessagesVC.m
//  Chat21
//
//  Created by Dario De Pascalis on 22/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatMessagesVC.h"

#import "ChatMessage.h"
#import "ChatUtil.h"
#import "ChatDB.h"
#import "ChatConversation.h"
#import "ChatManager.h"
#import "ChatConversationHandler.h"
#import "ChatConversationsVC.h"
#import "ChatStringUtil.h"
#import "ChatGroupInfoVC.h"
#import "QBPopupMenu.h"
#import "QBPopupMenuItem.h"
#import "ChatTitleVC.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatMessagesTVC.h"
#import "ChatGroup.h"
#import "ChatStatusTitle.h"
#import "ChatGroupsHandler.h"
#import "ChatUIManager.h"
#import "ChatConnectionStatusHandler.h"
#import "ChatPresenceHandler.h"
#import "ChatContactsDB.h"

@interface ChatMessagesVC (){
    SystemSoundID soundID;
}
@end

@implementation ChatMessagesVC

//int MAX_WIDTH_TEXTCHAT = 230;//250.0;
//int WIDTH_BOX_DATE = 50.0;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTitle];
    
    NSLog(@"self.recipient.fullname: %@", self.recipient.fullname);
    keyboardShow = NO;
    
    self.me = [ChatManager getInstance].loggedUser;
    self.senderId = self.me.userId;
    [self registerForKeyboardNotifications];
    [self backgroundTapToDismissKB:YES];
    
    originalViewHeight = self.view.bounds.size.height;
    heightTable = 0;// self.tableView.bounds.size.height;
    self.bottomReached = YES;
    
    [self setupLabels];
    [self buildUnreadBadge];
    
    //    self.group.name = nil; // TEST DOWNLOAD GRUPPO METADATI PARZIALI
    if (self.recipient) { // online status only in DM mode
        [self setupForDirectMessageMode];
    }
//    else if (self.group && !self.group.completeData) {
//        // group's metadata not available, downloading
//        // the conversationHandler object needs all group's metadata (members)
//        // so it can't be initialized without completing group's info
//        [self loadGroupInfo];
//    }
    else if (self.group) { // all group metadata ok
        [self setupForGroupMode];
    }
    else {
        NSLog(@"Error: impossible configuration! No Group and no recipient!");
    }
    
    if (self.isModal) {
        UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
        [self.navigationItem setLeftBarButtonItem:leftBarButton];
        //self.cancelButton.title = NSLocalizedString(@"cancel", nil);
    }
    [self setContainer];
}

-(BOOL)ImInGroup {
    NSLog(@"can I write in this group?");
    if (!self.group) {
        return NO;
    }
    NSDictionary *members = self.group.members;
    NSString *user_found = [members objectForKey:self.me.userId];
    return user_found ? YES : NO;
}

-(void)setupForDirectMessageMode {
    [self setupConnectionStatus];
    [self initConversationHandler];
    [self setupRecipientOnlineStatus];
    [self sendTextAsChatOpens];
    self.recipient.fullname ? [self setTitle:self.recipient.fullname] : [self setTitle:self.recipient.userId];
}

-(void)setupForGroupMode {
    self.activityIndicator.hidden = YES;
    [self initConversationHandler];
    [self writeBoxEnabled];
    if ([self ImInGroup]) {
        [self sendTextAsChatOpens];
    }
    //    [self.usernameButton setTitle:self.group.name forState:UIControlStateNormal];
    [self setTitle:self.group.name];
    [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
        [self setSubTitle:[ChatUtil groupMembersFullnamesAsStringForUI:self.group.membersFull]];
    }];
//    ChatContactsDB *db = [ChatContactsDB getSharedInstance];
//    NSArray<NSString *> *contact_ids = [self.group.members allKeys];
//    [db getMultipleContactsByIdsSyncronized:contact_ids completion:^(NSArray<ChatUser *> *contacts) {
//        self.group.membersFull = contacts;
//        [self setSubTitle:[ChatUtil groupMembersFullnamesAsStringForUI:contacts]];
//    }];
}

//-(void)loadGroupInfo {
//    self.usernameButton.hidden = YES;
//    self.activityIndicator.hidden = NO;
//    [self.activityIndicator startAnimating];
//    [self setSubTitle:@""];
//    //    self.statusLabel.text = @"";
//    ChatManager *chatm = [ChatManager getInstance];
//    NSString *group_id = self.group.groupId;
//    __weak ChatMessagesVC *weakSelf = self;
//    [chatm loadGroup:group_id completion:^(ChatGroup *group, BOOL error) {
//        NSLog(@"Group %@ info loaded", group.name);
//        weakSelf.usernameButton.hidden = NO;
//        weakSelf.activityIndicator.hidden = YES;
//        [weakSelf.activityIndicator stopAnimating];
//        if (error) {
//            [weakSelf setSubTitle:@"Errore gruppo"];
//            //            weakSelf.statusLabel.text = @"Errore gruppo";
//        }
//        else {
//            weakSelf.group = group;
//            [weakSelf setupForGroupMode];
//        }
//    }];
//}

//-(void)loadGroupInfo:(ChatGroup *)group completion:(void (^)(BOOL error))callback {
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    NSString *groups_path = [ChatUtil groupsPath];
//    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@", groups_path, group.groupId];
//    NSLog(@"Load Group on path: %@", path);
//    FIRDatabaseReference *groupRef = [rootRef child:path];
//
//    [groupRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
//        NSLog(@"NEW GROUP SNAPSHOT: %@", snapshot);
//        if (!snapshot || ![snapshot exists]) {
//            NSLog(@"Errore gruppo: !snapshot || !snapshot.exists");
//            callback(YES);
//        }
//        self.group = [ChatManager groupFromSnapshotFactory:snapshot];
//        ChatGroupsHandler *gh = [ChatManager getSharedInstance].groupsHandler;
//        [gh insertOrUpdateGroup:group];
//        callback(NO);
//    } withCancelBlock:^(NSError *error) {
//        NSLog(@"%@", error.description);
//    }];
//}

-(void)writeBoxEnabled {
    [self ImInGroup] ? [self hideBottomView:NO] : [self hideBottomView:YES];
}

-(void)hideBottomView:(BOOL)hide {
    if (hide) {
        NSLog(@"Hide write box");
        self.bottomView.hidden = YES;
        self.bottomViewHeightConstraint.constant = 0.0;
    } else {
        NSLog(@"Show write box");
        self.bottomView.hidden = NO;
        self.bottomViewHeightConstraint.constant = 44.0;
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden=YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    [self updateUnreadMessagesCount];
    [[ChatManager getInstance].groupsHandler addSubcriber:self];
}

-(void)subscribe:(ChatConversationHandler  *)handler {
    self.added_handle = [handler observeEvent:ChatEventMessageAdded withCallback:^(ChatMessage *message) {
        [self messageReceived:message];
    }];
    self.changed_handle = [handler observeEvent:ChatEventMessageChanged withCallback:^(ChatMessage *message) {
        [self messageUpdated:message];
    }];
    self.deleted_handle = [handler observeEvent:ChatEventMessageDeleted withCallback:^(ChatMessage *message) {
        [self messageDeleted:message];
    }];
    NSLog(@"added_handle: %lu, changed_handle: %lu, deleted_handle: %lu", (unsigned long)self.added_handle, (unsigned long)self.changed_handle, (unsigned long)self.deleted_handle);
}

-(void)removeSubscribers {
    if (self.conversationHandler) {
        [self.conversationHandler removeObserverWithHandle:self.added_handle];
        [self.conversationHandler removeObserverWithHandle:self.changed_handle];
        [self.conversationHandler removeObserverWithHandle:self.deleted_handle];
    }
    self.added_handle = 0;
    self.changed_handle = 0;
    self.deleted_handle = 0;
    //    [self.connectedRef removeObserverWithHandle:self.connectedRefHandle];
    ChatManager *chatm = [ChatManager getInstance];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.connectedHandle];
    [chatm.connectionStatusHandler removeObserverWithHandle:self.disconnectedHandle];
    self.connectedHandle = 0;
    self.disconnectedHandle = 0;
}

-(void)sendTextAsChatOpens {
    if (self.textToSendAsChatOpens) {
        [self sendMessage:self.textToSendAsChatOpens attributes:self.attributesToSendAsChatOpens];
        self.textToSendAsChatOpens = nil;
        self.attributesToSendAsChatOpens = nil;
        [self.messageTextField becomeFirstResponder];
    }
}


-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"VIEW WILL DISAPPEAR... %@", self);
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
    [self removeUnreadBadge];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
    if (self.isMovingFromParentViewController) {
        NSLog(@"isMovingFromParentViewController: OK");
        [self resetTitleView];
        self.tabBarController.tabBar.hidden=NO;
        [self removeSubscribers];
        [[ChatManager getInstance].groupsHandler removeSubcriber:self];
        
        //        for (NSString *k in self.imageDownloadsInProgress) {
        //            NSLog(@"Removing downloader: %@", k);
        //            SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:k];
        //            [iconDownloader cancelDownload];
        //            iconDownloader.delegate = nil;
        //        }
        [self freeKeyboardNotifications];
        containerTVC.vc = nil;
        containerTVC.conversationHandler = nil;
    }
}

// TIP: why this method? http://www.yichizhang.info/2015/03/02/prescroll-a-uitableview.html
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [containerTVC scrollToLastMessage:NO];
}

//---------------------------------------------------//
//START FUNCTIONS
//---------------------------------------------------//
-(void)setContainer {
    containerTVC = [self.childViewControllers objectAtIndex:0];
    containerTVC.vc = self;
    containerTVC.conversationHandler = self.conversationHandler;
    [containerTVC reloadDataTableView];
}


-(void)setupLabels {
    [self.sendButton setTitle:NSLocalizedString(@"ChatSend", nil) forState:UIControlStateNormal];
    self.messageTextField.placeholder = NSLocalizedString(@"digit message", nil);
}

//-(void)initImageCache {
//    // cache setup
//    self.imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
//    if (!self.imageCache) {
//        self.imageCache = [[ChatImageCache alloc] init];
//        self.imageCache.cacheName = @"chatUserIcons";
//        [self.applicationContext setVariable:@"chatUserIcons" withValue:self.imageCache];
//    }
//}

// ************************
// *** ONLINE / OFFLINE ***
// ************************


-(void)setupConnectionStatus {
    // initial status UI
    [self offlineStatus];
    
    ChatManager *chatm = [ChatManager getInstance];
    ChatConnectionStatusHandler *connectionStatusHandler = chatm.connectionStatusHandler;
    if (connectionStatusHandler) {
        [connectionStatusHandler isStatusConnectedWithCompletionBlock:^(BOOL connected, NSError *error) {
            if (connectionStatusHandler) {
                [self connectedStatus];
            }
            else {
                [self offlineStatus];
            }
        }];
        //        self.connectedHandle = [connectionStatusHandler observeEvent:ChatConnectionStatusEventConnected withCallback:^{
        //            NSLog(@"connected");
        //            [self connectedStatus];
        //        }];
        //        self.disconnectedHandle = [connectionStatusHandler observeEvent:ChatConnectionStatusEventDisconnected withCallback:^{
        //            NSLog(@"not connected");
        //            [self offlineStatus];
        //        }];
    }
    
    //    // initial status UI
    //    [self offlineStatus];
    //
    ////    ChatManager *chat = [ChatManager getSharedInstance];
    //    NSString *url = @"/.info/connected";
    //    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    //    self.connectedRef = [rootRef child:url];
    //    self.connectedRefHandle = [self.connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
    //        if([snapshot.value boolValue]) {
    //            NSLog(@"connected");
    //            [self connectedStatus];
    //        } else {
    //            NSLog(@"not connected");
    //            [self offlineStatus];
    //        }
    //    }];
}

-(void)connectedStatus {
    self.usernameButton.hidden = NO;
    self.activityIndicator.hidden = YES;
    self.sendButton.enabled = YES;
    [self.activityIndicator stopAnimating];
    //    if (self.group) {
    //        self.statusLabel.text = [ChatUtil groupMembersAsStringForUI:self.group.members];
    //    } else {
    [self onlineStatus];
    //    }
}

-(void)offlineStatus {
    self.usernameButton.hidden = YES;
    self.activityIndicator.hidden = NO;
    self.sendButton.enabled = NO;
    [self.activityIndicator startAnimating];
    [self setSubTitle:NSLocalizedString(@"ChatDisconnected", nil)];
    //    self.statusLabel.text = NSLocalizedString(@"ChatDisconnected", nil);
}

-(void)onlineStatus {
    if (self.online) {
        [self setSubTitle:NSLocalizedString(@"online", nil)];
    } else {
        NSString *last_online_status;
        if (self.lastOnline) {
            NSString *last_seen = NSLocalizedString(@"last seen", nil);
            NSString *short_date = [ChatStringUtil timeFromNowToString:self.lastOnline];
            last_online_status = [[NSString alloc] initWithFormat:@"%@ %@",last_seen, short_date];
        } else {
            last_online_status = NSLocalizedString(@"offline", nil);
        }
        [self setSubTitle:last_online_status];
        //        self.statusLabel.text = last_online_status;
    }
}

-(void)setupRecipientOnlineStatus {
    
    ChatManager *chatm = [ChatManager getInstance];
    [chatm.presenceHandler onlineStatusForUser:self.recipient.userId withCallback:^(BOOL status) {
        self.online = status;
        [self onlineStatus];
    }];
    
    [chatm.presenceHandler lastOnlineDateForUser:self.recipient.userId withCallback:^(NSDate *lastOnlineDate) {
        self.lastOnline = lastOnlineDate;
        [self onlineStatus];
    }];
    //    [chatm.presenceHandler ]
    //    // apps/{TENANT}/presence/{USERID}/connections
    //    self.onlineRef = [ChatPresenceHandler onlineRefForUser:self.recipient.userId];
    //    self.online_ref_handle = [self.onlineRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
    //        if(snapshot.exists) {
    //            NSLog(@"ONLINE: %@", snapshot);
    //            self.online = YES;
    //            [self onlineStatus];
    //        } else {
    //            self.online = NO;
    //            [self onlineStatus];
    //        }
    //    }];
    
    // LAST ONLINE
    
    // apps/{TENANT}/presence/{USERID}/lastOnline
    //    self.lastOnlineRef = [ChatPresenceHandler lastOnlineRefForUser:self.recipient.userId];
    //    NSLog(@"last online ref: %@", self.lastOnlineRef);
    //    self.last_online_ref_handle = [self.lastOnlineRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
    //        [self snapshotDate:snapshot];
    //        [self onlineStatus];
    //    }];
    
    
}

//-(void)snapshotDate:(FIRDataSnapshot *)snapshot {
//    if (!snapshot.exists) {
//        return;
//    }
//    self.lastOnline = [NSDate dateWithTimeIntervalSince1970:[snapshot.value longValue]/1000];
//}


// ************************
// *** ONLINE / OFFLINE ***
// ************************
// ********* END **********
// ************************


-(void)buildUnreadBadge {
    self.unreadLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, 16, 16)];
    [self.unreadLabel setBackgroundColor:[UIColor redColor]];
    [self.unreadLabel setTextColor:[UIColor whiteColor]];
    self.unreadLabel.font = [UIFont systemFontOfSize:11];
    self.unreadLabel.textAlignment = NSTextAlignmentCenter;
    self.unreadLabel.layer.masksToBounds = YES;
    self.unreadLabel.layer.cornerRadius = 8.0;
    [self.navigationController.navigationBar addSubview:self.unreadLabel];
    self.unreadLabel.hidden = YES;
}

-(void)updateUnreadMessagesCount {
    if (self.unread_count > 0) {
        self.unreadLabel.hidden = NO;
        self.unreadLabel.text = [[NSString alloc] initWithFormat:@"%d", self.unread_count];
    } else {
        self.unreadLabel.hidden = YES;
    }
}

-(void)removeUnreadBadge {
    NSLog(@"Removing unread label... %@", self.unreadLabel);
    [self.unreadLabel removeFromSuperview];
}

-(void)setTitle:(NSString *)title {
    self.navigationItem.title = title;
    [self.usernameButton setTitle:title forState:UIControlStateNormal];
}

-(void)setSubTitle:(NSString *)subtitle {
    self.statusLabel.text = subtitle;
}

-(void)customizeTitle {
    self.navigationItem.titleView = nil;
    
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"status_title_ios11" owner:self options:nil];
    ChatStatusTitle *view = [subviewArray objectAtIndex:0];
    //    view.frame = CGRectMake(0, 0, 200, 40);
    self.statusLabel = view.statusLabel;
    self.activityIndicator = view.activityIndicator;
    self.usernameButton = view.usernameButton;
    //    [view.usernameButton setTitle:title forState:UIControlStateNormal];
    [view.usernameButton addTarget:self
                            action:@selector(goToProfile:)
                  forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = view;
}

-(void)resetTitleView {
    NSLog(@"RESETTING TITLE VIEW");
    self.usernameButton = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.navigationItem.titleView = nil;
    self.titleVC = nil;
}

-(void)chatTitleButtonPressed {
    NSLog(@"title button pressed");
}

-(void)goToProfile:(UIButton*)sender {
    //NSLog(@"goToProfile");
    //    self.profileVC = (SHPHomeProfileTVC *)[self.applicationContext getVariable:@"profileVC"];
    NSLog(@"RECIPIENT FULL NAME: %@", self.recipient.fullname);
    if (self.group) {
        [self performSegueWithIdentifier:@"GroupInfo" sender:self];
    } else {
        if (![ChatUIManager getInstance].pushProfileCallback) {
            NSLog(@"Default profile view not implemented.");
            //            self.profileSB = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
            //            self.profileNC = [self.profileSB instantiateViewControllerWithIdentifier:@"navigationProfile"];
            //            SHPHomeProfileTVC *profileVC = (SHPHomeProfileTVC *)[[self.profileNC viewControllers] objectAtIndex:0];
            //            ChatUser *authorProfile = [[ChatUser alloc] init];
            //            authorProfile.userId = self.recipient.userId;
            //            authorProfile.fullname = self.recipient.fullname;
            //            profileVC.otherUser = authorProfile;
            //            NSLog(@"self.profileVC.otherUser %@ fullname: %@", profileVC.otherUser.userId, profileVC.otherUser.fullname);
            //            [self.navigationController pushViewController:profileVC animated:YES];
        }
        else {
            ChatUser *user = [[ChatUser alloc] init];
            user.userId = self.recipient.userId;
            user.fullname = self.recipient.fullname;
            [ChatUIManager getInstance].pushProfileCallback(user, self);
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

-(void)initConversationHandler {
    ChatManager *chatm = [ChatManager getInstance];
    ChatConversationHandler *handler;
    if (self.recipient) {
        handler = [chatm getConversationHandlerForRecipient:self.recipient];
    } else {
        NSLog(@"*** CONVERSATION HANDLER IN GROUP MOD!!!!!!!");
        handler = [chatm getConversationHandlerForGroup:self.group];
    }
    [handler connect];
    [self subscribe:handler];
    self.conversationHandler = handler;
    [self checkImGroupMember];
}

//-(void)initConversationHandler {
//    ChatManager *chatm = [ChatManager getInstance];
//    ChatConversationHandler *handler = [chatm getConversationHandlerByConversationId:self.recipient.userId]; // [chatm getConversationHandlerByRecipient:self.recipient];
//    if (!handler) {
//        NSLog(@"Conversation Handler not found. Creating & initializing a new one with conv-id %@", self.recipient.userId);
//        // GROUP_MOD
//        if (self.recipient) {
//            handler = [[ChatConversationHandler alloc] initWithRecipient:self.recipient.userId recipientFullName:self.recipient.fullname];
//        } else {
//            NSLog(@"*** CONVERSATION HANDLER IN GROUP MOD!!!!!!!");
//            handler = [[ChatConversationHandler alloc] initWithGroupId:self.group.groupId];
//        }
//        [chatm addConversationHandler:handler];
//        [self subscribe:handler];
//        self.conversationHandler = handler;
//
//        // db
//        NSLog(@"Restoring DB archived conversations.");
//        [self.conversationHandler restoreMessagesFromDB];
//        NSLog(@"Archived messages count %lu", (unsigned long)self.conversationHandler.messages.count);
//
//        if (self.recipient) {
//            NSLog(@"Connecting handler to firebase.");
//            [handler connect];
//        }
//        else {
//            [self checkImGroupMember];
//        }
//        NSLog(@"Handler ref: %@", handler.messagesRef);
//        NSLog(@"Adding new handler %@ to Conversations Manager.", handler);
//    }
//    else {
////        [handler addSubcriber:self];
//        [handler connect];
//        [self subscribe:handler];
//        self.conversationHandler = handler;
//        [self checkImGroupMember];
//    }
//    [self setContainer];
//}

-(void)checkImGroupMember {
    if (self.group) {
        if ([self.group isMember:self.me.userId]) {
            [self.conversationHandler connect];
        }
        else {
            [self.conversationHandler dispose];
        }
    }
}

//-(void)didFinishInitConversationHandler:(ChatConversationHandler *)handler error:(NSError *)error {
//    if (!error) {
//        NSLog(@"ChatConversationHandler Initialization finished with success.");
//    } else {
//        NSLog(@"ChatConversationHandler Initialization finished with error: %@", error);
//    }
//}
//---------------------------------------------------//
//START FUNCTIONS
//---------------------------------------------------//

//---------------------------------------------------//
//INIZIO GESTIONE KEYBOARD
//---------------------------------------------------//
-(void)backgroundTapToDismissKB:(BOOL)activate
{
    if (activate) {
        if (!self.tapToDismissKB) {
            self.tapToDismissKB = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
            self.tapToDismissKB.cancelsTouchesInView = YES;// without this, tap on buttons is captured by the view
        }
        [self.view addGestureRecognizer:self.tapToDismissKB];
    } else if (self.tapToDismissKB) {
        [self.view removeGestureRecognizer:self.tapToDismissKB];
    }
}

- (IBAction)addContentAction:(id)sender {
    //    UIAlertController * view=   [UIAlertController
    //                                 alertControllerWithTitle:nil
    //                                 message:@"Allega"
    //                                 preferredStyle:UIAlertControllerStyleActionSheet];
    //
    //    UIAlertAction* documenti = [UIAlertAction
    //                           actionWithTitle:@"Documenti"
    //                           style:UIAlertActionStyleDefault
    //                           handler:^(UIAlertAction * action)
    //                           {
    //                               NSLog(@"Documenti");
    //                               UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DocNavigator" bundle:nil];
    //                               UINavigationController *nc = [sb instantiateViewControllerWithIdentifier:@"NavigatorController"];
    //                               DocNavigatorTVC *navigatorVC = (DocNavigatorTVC *)[[nc viewControllers] objectAtIndex:0];
    //                               navigatorVC.selectionMode = YES;
    //                               navigatorVC.selectionDelegate = self;
    //                               [self.navigationController presentViewController:nc animated:YES completion:nil];
    //                           }];
    ////    UIAlertAction* dropbox = [UIAlertAction
    ////                           actionWithTitle:@"Dropbox"
    ////                           style:UIAlertActionStyleDefault
    ////                           handler:^(UIAlertAction * action)
    ////                           {
    ////                               NSLog(@"Open dropbox");
    ////                               [self openDropbox];
    ////                           }];
    //    UIAlertAction* cancel = [UIAlertAction
    //                             actionWithTitle:NSLocalizedString(@"CancelLKey", nil)
    //                             style:UIAlertActionStyleCancel
    //                             handler:^(UIAlertAction * action)
    //                             {
    //                                 NSLog(@"cancel");
    //                             }];
    //    [view addAction:documenti];
    ////    [view addAction:dropbox];
    //    [view addAction:cancel];
    //    [self presentViewController:view animated:YES completion:nil];
}

//-(void)openDropbox {
//    [[DBChooser defaultChooser] openChooserForLinkType:DBChooserLinkTypePreview
//                                    fromViewController:self completion:^(NSArray *results)
//     {
//         if ([results count]) {
//             // Process results from Chooser
//             DBChooserResult *r = results[0];
//             //             NSLog(@"r.name %@", r.name);
//             //             NSLog(@"r.link %@", r.link);
//             //             NSLog(@"r.size %lld", r.size);
//             //             NSLog(@"r.iconURL %@", r.iconURL);
//             NSDictionary *thumbs = r.thumbnails;
//             //             if (thumbs) {
//             //                 NSArray*keys=[thumbs allKeys];
//             //                 for (NSObject *k in keys) {
//             //                     NSLog(@"r.thumb[%@]: %@", k, thumbs[k]);
//             //                 }
//             //                 NSLog(@"r.thumbs.64x64px %@", thumbs[@"64x64"]);
//             //                 NSLog(@"r.thumbs.200x200px %@", thumbs[@"200x200"]);
//             //                 NSLog(@"r.thumbs.640x480px %@", thumbs[@"640x480"]);
//             //             } else {
//             //                 NSLog(@"No r.thumbs");
//             //             }
//             [self sendDropboxMessage:r.name link:[r.link absoluteString] size:[NSNumber numberWithLongLong:r.size] iconURL:[r.iconURL absoluteString] thumbs:thumbs];
//         } else {
//             // User canceled the action
//             NSLog(@"Action canceled");
//         }
//     }];
//}

//-(void)selectedDocument:(AlfrescoNode *)document {
//    NSLog(@"Document selected %@ url: %@", document.name, [DocNavigatorTVC documentURLByNode:document]);
//    [self sendAlfrescoMessage:document.name link:[DocNavigatorTVC documentURLByNode:document]];
//}

-(void)dismissKeyboardFromTableView:(BOOL)activated {
    //    NSLog(@"DISMISSING");
    [self backgroundTapToDismissKB:activated];
}

-(void)dismissKeyboard {
    //    NSLog(@"dismissing keyboard");
    [self.view endEditing:YES];
}

-(void) registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


-(void) freeKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


-(void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"Keyboard was shown %ld",(long)self.messageTextField.autocorrectionType);
    if(keyboardShow == NO){
        NSLog(@"KEYBOARD-SHOW == NO!");
        //CGFloat content_h = self.tableView.contentSize.height;
        NSDictionary* info = [aNotification userInfo];
        NSTimeInterval animationDuration;
        UIViewAnimationCurve animationCurve;
        CGRect keyboardFrame;
        [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
        [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
        [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
        
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:animationDuration animations:^{
            self.layoutContraintBottomBarMessageBottomView.constant = keyboardFrame.size.height;
            [self.view layoutIfNeeded];
        }];
        
        keyboardShow = YES;
    }
    else {
        NSLog(@"Suggestion hide/show");
        NSLog(@"KEYBOARD-SHOW == YES!");
        //START apertura e chiusura suggerimenti keyboard
        NSDictionary* info = [aNotification userInfo];
        CGRect keyboardFrame;
        [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
        CGFloat beginHeightKeyboard = keyboardFrame.size.height;
        NSLog(@"Keyboard info1 %f",beginHeightKeyboard);
        [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
        CGFloat endHeightKeyboard = keyboardFrame.size.height;
        NSLog(@"Keyboard info2 %f",endHeightKeyboard);
        CGFloat difference = beginHeightKeyboard-endHeightKeyboard;
        
        NSLog(@"Difference: %f", difference);
        NSTimeInterval animationDuration;
        [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
        //        CGFloat viewport_h_with_kb = self.view.frame.size.height + difference;
        //        CGFloat viewport_final_h = viewport_h_with_kb;
        
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:animationDuration animations:^{
            self.layoutContraintBottomBarMessageBottomView.constant = keyboardFrame.size.height;
            [self.view layoutIfNeeded];
        }];
        /////
    }
    
}

-(void) keyboardWillHide:(NSNotification*)aNotification
{
    NSLog(@"KEYBOARD HIDING...");
    NSDictionary* info = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    
    //START ANIMATION VIEW
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        self.layoutContraintBottomBarMessageBottomView.constant = 0;
        [self.view layoutIfNeeded];
    }];
    /////
    keyboardShow = NO;
    //END ANIMATION VIEW
    
}
//---------------------------------------------------//
//FINE GESTIONE KEYBOARD
//---------------------------------------------------//

-(NSString*)formatDateMessage:(int)numberDaysBetweenChats message:(ChatMessage*)message row:(CGFloat)row {
    NSString *dateChat;
    if(numberDaysBetweenChats>0 || row==0){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSDate *today;
        today = [NSDate date];
        int days = (int)[ChatStringUtil daysBetweenDate:message.date andDate:today];
        if(days==0){
            dateChat = NSLocalizedString(@"today", nil);
        }
        else if(days==1){
            dateChat = NSLocalizedString(@"yesterday", nil);
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

- (IBAction)sendAction:(id)sender {
    NSLog(@"sendAction()");
    NSString *text = self.messageTextField.text;
    [self sendMessage:text];
}

-(void)sendMessage:(NSString *)text {
    //    [DocChatUtil firebaseAuth:self.applicationContext.loggedUser.username password:self.applicationContext.loggedUser.password completion:^(NSError *error) {
    //        NSLog(@"CONNECTED!!!!");
    //    }];
    [self sendMessage:text attributes:nil];
}

-(void)sendMessage:(NSString *)text attributes:(NSDictionary *)attributes {
    
    // check: if in a group, are you still a member?
    if (self.group) {
        if (![self.group isMember:self.me.userId]) {
            [self hideBottomView:YES];
            [self.messageTextField resignFirstResponder];
            return;
        }
    }
    
    NSString *trimmed_text = [text stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceCharacterSet]];
    if(trimmed_text.length > 0) {
        [self.conversationHandler sendMessageWithText:text type:MSG_TYPE_TEXT attributes:attributes];
        self.messageTextField.text = @"";
    }
}

-(void)sendDropboxMessage:(NSString *)name link:(NSString *)link size:(NSNumber *)size iconURL:(NSString *)iconURL thumbs:(NSDictionary *)thumbs {
    
    // check: if in a group, are you still a member?
    if (self.group) {
        if ([self.group isMember:self.me.userId]) {
        } else {
            [self hideBottomView:YES];
            [self.messageTextField resignFirstResponder];
            return;
        }
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    NSLog(@"dropbox.link: %@", link);
    NSLog(@"dropbox.size: %@", size);
    NSLog(@"dropbox.iconurl: %@", iconURL);
    
    [attributes setValue:link forKey:@"link"];
    [attributes setValue:size forKey:@"size"];
    [attributes setValue:iconURL forKey:@"iconURL"];
    if (thumbs) {
        NSArray*keys=[thumbs allKeys];
        for (NSString *k in keys) {
            NSURL *turl = (NSURL *)thumbs[k];
            [attributes setValue:[turl absoluteString] forKey:k];
        }
    }
    NSString *text = [NSString stringWithFormat:@"%@ %@", name, link];
    [self.conversationHandler sendMessageWithText:text type:MSG_TYPE_DROPBOX attributes:attributes];
}

//-(void)sendAlfrescoMessage:(NSString *)name link:(NSString *)link {
//
//    // check: if in a group, are you still a member?
//    if (self.group) {
//        if ([self.group isMember:self.me.userId]) {
//        } else {
//            [self hideBottomView:YES];
//            [self.messageTextField resignFirstResponder];
//            return;
//        }
//    }
//
//    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
//    NSLog(@"alfresco.link: %@", link);
//
//    [attributes setValue:link forKey:@"link"];
//    [attributes setValue:name forKey:@"name"];
//
//    //    NSString *text = [NSString stringWithFormat:@"%@ %@", name, link];
//    NSString *text = link;
//    [self.conversationHandler sendMessageWithText:text type:MSG_TYPE_ALFRESCO attributes:attributes];
//}

//- (IBAction)prindb:(id)sender {
//    NSLog(@"Printing messages...");
//    //    [self printDBMessages];
//}

//-(void)printDBMessages {
//    NSLog(@"--- all messages for conv %@", self.conversationId);
//    NSArray *messages = [[ChatDB getSharedInstance] getAllMessagesForConversation:self.conversationId];
//    for (ChatMessage *msg in messages) {
//        NSLog(@"%@>%@:%@ [%@]", msg.sender, msg.recipient, msg.text, msg.messageId);
//    }
//}

//// conversation subscriber
//-(void)messageAdded:(ChatMessage *)message {
//    NSLog(@"messageAdded: %@", message.messageId);
//    [self finishedReceivingMessage:message];
//}
//
//-(void)messageChanged:(ChatMessage *)message {
//    NSLog(@"messageChanged: %@", message.messageId);
//    [self finishedReceivingMessage:message];
//}
//
//-(void)messageDeleted:(ChatMessage *)message {
//    NSLog(@"messageDeleted: %@", message.messageId);
//    [self finishedReceivingMessage:message];
//}
//// end subscriber

-(void)messageUpdated:(ChatMessage *)message {
    [containerTVC reloadDataTableView];
}

-(void)messageDeleted:(ChatMessage *)message {
    [containerTVC reloadDataTableView];
}

-(void)messageReceived:(ChatMessage *)message {
    // SE MESSAGGIO.TIMESTAMP < "1 SEC FA" MOSTRA SUBITO. SE MESSAGGIO >= 1 SEC FA IMPOSTA UN TIMER. SE ARRIVA UN ALTRO MESSAGGIO DURANTE IL TIMER FAI RIPARTIRE IL TIMER. AFTER THE TIMER ENDS, RELOAD TABLE.
    
//    double now = [[NSDate alloc] init].timeIntervalSince1970;
//    self.lastMessageArrivedTime = now;
    
    if (!self.messagesArriving) {
        NSLog(@"MESSAGE ARRIVED. RENDERING.");
        [self startNewMessageTimer];
        self.messagesArriving = YES;
        // fist message always shown
        [self renderMessages];
    }
    else {
        NSLog(@"MESSAGES STILL ARRIVING, NOT RENDERING!");
    }
}

static float messageTime = 0.5;

-(void)startNewMessageTimer {
    if (self.messageTimer != nil) {
        [self.messageTimer invalidate];
        self.messageTimer = nil;
    }
    self.messageTimer = [NSTimer scheduledTimerWithTimeInterval:messageTime target:self selector:@selector(endNewMessageTimer) userInfo:nil repeats:NO];
}

-(void)endNewMessageTimer {
    NSLog(@"END RECEIVING MESSAGES. RENDERING.");
    [self.messageTimer invalidate];
    self.messageTimer = nil;
    self.messagesArriving = NO;
    [self playSound];
    [self renderMessages];
}

-(void)renderMessages {
    [containerTVC reloadDataTableViewOnIndex:self.conversationHandler.messages.count];
    [self scrollTo];
}

-(void)scrollTo {
    [containerTVC scrollToLastMessage:NO];
}

-(void)groupConfigurationChanged:(ChatGroup *)group {
    NSLog(@"Notified to view that %@ changed. Checking possible view changes.", group.name);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.group = group;
        [self checkImGroupMember];
        [self writeBoxEnabled];
        [self setTitle:self.group.name];
        [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
            [self setSubTitle:[ChatUtil groupMembersFullnamesAsStringForUI:self.group.membersFull]];
        }];
    });
}

-(void)playSound {
//    double now = [[NSDate alloc] init].timeIntervalSince1970;
//    if (now - self.lastPlayedSoundTime < 3) {
//        NSLog(@"TOO EARLY TO PLAY ANOTHER SOUND");
//        return;
//    }
    // help: https://github.com/TUNER88/iOSSystemSoundsLibrary
    // help: http://developer.boxcar.io/blog/2014-10-08-notification_sounds/
    NSString *path = [NSString stringWithFormat:@"%@/inline.caf", [[NSBundle mainBundle] resourcePath]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL,&soundID);
    AudioServicesPlaySystemSound(soundID);
    //    [self startSoundTimer];
    
//    double now = [[NSDate alloc] init].timeIntervalSince1970;
//    self.lastMessageArrivedTime = now;
}

-(void)dealloc {
    NSLog(@"Deallocating MessagesViewController.");
}

//EXTRA
-(void)customRoundImage:(UIView *)customImageView
{
    customImageView.layer.cornerRadius = 15;
    customImageView.layer.masksToBounds = NO;
    customImageView.layer.borderWidth = 0;
    customImageView.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void)customcornerRadius:(UIView *)customImageView cornerRadius:(CGFloat)cornerRadius
{
    customImageView.layer.cornerRadius = cornerRadius;
    customImageView.layer.masksToBounds = NO;
    customImageView.layer.borderWidth = 0;
}

- (IBAction)menuAction:(id)sender {
    //[self.menuSheet showInView:self.parentViewController.tabBarController.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    //    if (actionSheet == self.menuSheet) {
    //        NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
    //
    //        if ([option isEqualToString:@"Info gruppo"]) {
    //            [self performSegueWithIdentifier:@"GroupInfo" sender:self];
    //        }
    //        else if ([option isEqualToString:@"Invia immagine"]) {
    //            NSLog(@"invia immagine");
    //            [self.photoMenuSheet showInView:self.parentViewController.tabBarController.view];
    //        }
    //    } else {
    //        switch (buttonIndex) {
    //            case 0:
    //            {
    //                [self takePhoto];
    //                break;
    //            }
    //            case 1:
    //            {
    //                [self chooseExisting];
    //                break;
    //            }
    //        }
    //    }
}

// ChatGroupsSubscriber protocol

-(void)groupAddedOrChanged:(ChatGroup *)group {
    NSLog(@"Group added or changed delegate. Group name: %@", group.name);
    if (![group.groupId isEqualToString:self.group.groupId]) {
        return;
    }
    if ([group isMember:self.me.userId]) {
        [self.conversationHandler connect];
        [self groupConfigurationChanged:group];
    }
    else {
        [self.conversationHandler dispose];
        [self groupConfigurationChanged:group];
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"GroupInfo"]) {
        ChatGroupInfoVC *vc = (ChatGroupInfoVC *)[segue destinationViewController];
        NSLog(@"vc %@", vc);
        //        vc.applicationContext = self.applicationContext;
        vc.group = self.group;
    }
}

// **************************************************
// **************** TAKE PHOTO SECTION **************
// **************************************************

- (void)takePhoto {
    //    NSLog(@"taking photo with user %@...", self.applicationContext.loggedUser);
    if (self.imagePickerController == nil) {
        [self initializeCamera];
    }
    [self presentViewController:self.imagePickerController animated:YES completion:^{NSLog(@"FINITO!");}];
}

- (void)chooseExisting {
    NSLog(@"choose existing...");
    if (self.photoLibraryController == nil) {
        [self initializePhotoLibrary];
    }
    [self presentViewController:self.photoLibraryController animated:YES completion:nil];
}

-(void)initializeCamera {
    NSLog(@"cinitializeCamera...");
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    // enable to crop
    self.imagePickerController.allowsEditing = YES;
}

-(void)initializePhotoLibrary {
    NSLog(@"initializePhotoLibrary...");
    self.photoLibraryController = [[UIImagePickerController alloc] init];
    self.photoLibraryController.delegate = self;
    self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;// SavedPhotosAlbum;// SavedPhotosAlbum;
    self.photoLibraryController.allowsEditing = YES;
    //self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self afterPickerCompletion:picker withInfo:info];
}

-(void)afterPickerCompletion:(UIImagePickerController *)picker withInfo:(NSDictionary *)info {
    //    self.bigImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    //    NSLog(@"BIG IMAGE: %@", self.bigImage);
    //    // enable to crop
    //    // self.scaledImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    //    NSLog(@"edited image w:%f h:%f", self.bigImage.size.width, self.bigImage.size.height);
    //    if (!self.bigImage) {
    //        self.bigImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    //        NSLog(@"original image w:%f h:%f", self.bigImage.size.width, self.bigImage.size.height);
    //    }
    //    // end
    //
    //    self.scaledImage = [SHPImageUtil scaleImage:self.bigImage toSize:CGSizeMake(self.applicationContext.settings.uploadImageSize, self.applicationContext.settings.uploadImageSize)];
    //    NSLog(@"SCALED IMAGE w:%f h:%f", self.scaledImage.size.width, self.scaledImage.size.height);
    //
    //    if (picker == self.imagePickerController) {
    //        UIImageWriteToSavedPhotosAlbum(self.bigImage, self,
    //                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    //    }
    //
    //    NSLog(@"image: %@", self.scaledImage);
    
    
    //    UIImage *imageEXIFAdjusted = [SHPImageUtil adjustEXIF:self.scaledImage];
    //    NSData *imageData = UIImageJPEGRepresentation(imageEXIFAdjusted, 90);
    
    //    PFFile *imageFile = [PFFile fileWithName:@"image.png" data:imageData];
    //    NSLog(@"imageFile: %@", imageFile);
    //
    //    PFObject *userPhoto = [PFObject objectWithClassName:@"Image"];
    //    NSLog(@"userPhoto: %@", userPhoto);
    //    userPhoto[@"file"] = imageFile;
    //    [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    //        if (succeeded) {
    //            NSLog(@"Image saved.");
    //            PFFile *imageFile = userPhoto[@"file"];
    //            [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
    //                if (!error) {
    //                    NSLog(@"Downloading image...");
    //                    UIImage *image = [UIImage imageWithData:imageData];
    //                    UIImageWriteToSavedPhotosAlbum(image, self,
    //                                                   @selector(image:didFinishSavingWithError:contextInfo:), nil);
    //                }
    //            }];
    //        }
    //    }];
    //    NSLog(@"userPhoto: %@", userPhoto);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        NSLog(@"(SHPTakePhotoViewController) Error saving image to camera roll.");
    }
    else {
        //NSLog(@"(SHPTakePhotoViewController) Image saved to camera roll. w:%f h:%f", self.image.size.width, self.image.size.height);
    }
}

// **************************************************
// *************** END PHOTO SECTION ****************
// **************************************************

- (void)cancelAction {
    NSLog(@"Dismissing Messages view.");
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.dismissModalCallback) {
            self.dismissModalCallback();
        }
    }];
}

@end

