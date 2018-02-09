//
//  ChatSelectGroupMembersLocal.m
//  bppmobile
//
//  Created by Andrea Sponziello on 14/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatSelectGroupMembersLocal.h"
#import "ChatModalCallerDelegate.h"
#import "UIView+Property.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatUtil.h"
#import "ChatDB.h"
#import "ChatUser.h"
#import "ChatManager.h"
#import "ChatContactsDB.h"
#import "ChatGroup.h"
#import "ChatProgressView.h"
#import "ChatLocal.h"

@interface ChatSelectGroupMembersLocal () {
    ChatProgressView *HUD;
}
@end

@implementation ChatSelectGroupMembersLocal

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [ChatLocal translate:@"add members"];
    self.users = nil;
    
    //    self.imageCache = self.applicationContext.smallImagesCache;
    
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    NSLog(@"tableView %@", self.tableView);
    
    self.searchBar.delegate = self;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.members = [[NSMutableArray alloc] init];
    self.createButton.title = [ChatLocal translate:@"create"];
    self.searchBar.placeholder = [ChatLocal translate:@"contact name"];
    
    [self.searchBar becomeFirstResponder];
    
    [self enableCreateButton];
    [self initImageCache];
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

//-(void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //    NSLog(@"VIEW WILL DISAPPEAR...");
    //    if (self.isMovingFromParentViewController) {
    //        NSLog(@"VIEW WILL DISAPPEAR...DISMISSING..");
    //        [self disposeResources];
    //    }
}

//-(void)disposeResources {
//    self.userDC.delegate = nil;
//    NSLog(@"Disposing userDC...");
//    [self.userDC cancelConnection];
//    NSLog(@"Disposing pending image connections...");
//    [self terminatePendingImageConnections];
//}

-(void)disposeResources {
//    if (self.currentRequest) {
//        [self.currentRequest cancel];
//    }
    NSLog(@"Disposing pending image connections...");
    [self terminatePendingImageConnections];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"numberOfRowsInSection");
    if(self.users && self.users.count > 0) {
        NSInteger num = self.users.count;
        NSLog(@"rows %ld", num);
        return num;
    } else if (self.members && self.members > 0) {
        NSInteger num = self.members.count;
        NSLog(@"rows %ld", num);
        return num;
    }
    else {
        NSLog(@"0 rows.");
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (self.users && self.users.count > 0) {
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        //        cell.contentView.backgroundColor = [UIColor whiteColor];
        ChatUser *user = [self.users objectAtIndex:userIndex];
        //        NSLog(@"USER:::::::::::::::::: %@", user);
        UILabel *fullnameLabel = (UILabel *) [cell viewWithTag:2];
        UILabel *usernameLabel = (UILabel *) [cell viewWithTag:3];
        //        NSLog(@"LABEL::::::: %@", usernameLabel);
        fullnameLabel.text = user.fullname;
        usernameLabel.text = user.userId;
        
        
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        image_view.image = circled;
        //        // USER IMAGE
        //        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        //        NSString *imageURL = [SHPUser photoUrlByUsername:user.username];
        //        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        //        UIImage *user_image = cached_image_wrap.image;
        //        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
        //            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
        //            [self startIconDownload:user.username forIndexPath:indexPath];
        //            // if a download is deferred or in progress, return a placeholder image
        //            UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
        //            image_view.image = circled;
        //        } else {
        //            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
        //            image_view.image = [SHPImageUtil circleImage:user_image];
        //            // update too old images
        //            double now = [[NSDate alloc] init].timeIntervalSince1970;
        //            double reload_timer_secs = 86400; // one day
        //            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
        //                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
        //                [self startIconDownload:user.username forIndexPath:indexPath];
        //            } else {
        //                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
        //            }
        //        }
        
        // is just a member'
        
        if(![self userIsMember:user])
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.userInteractionEnabled = YES;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.userInteractionEnabled = NO;
        }
        
    } else {
        // show members
        
        long userIndex = indexPath.row;
        ChatUser *user = [self.members objectAtIndex:userIndex];
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserMemberCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //remove member button
        UIButton *removeButton = (UIButton *)[cell viewWithTag:4];
        [removeButton setTitle:[ChatLocal translate:@"remove"] forState:UIControlStateNormal];
        NSLog(@"REMOVE BUTTON %@", removeButton);
        [removeButton addTarget:self action:@selector(removeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        removeButton.property = user.userId; //[NSNumber numberWithInt:(int)indexPath.row];
        
        UILabel *fullnameLabel = (UILabel *) [cell viewWithTag:2];
        UILabel *usernameLabel = (UILabel *) [cell viewWithTag:3];
        fullnameLabel.text = user.fullname;
        usernameLabel.text = user.userId;
        
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        image_view.image = circled;
        // USER IMAGE
        //        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        //        NSString *imageURL = [SHPUser photoUrlByUsername:user.username];
        //        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        //        UIImage *user_image = cached_image_wrap.image;
        //        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
        //            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
        //            [self startIconDownload:user.username forIndexPath:indexPath];
        //            // if a download is deferred or in progress, return a placeholder image
        //            UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
        //            image_view.image = circled;
        //        } else {
        //            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
        //            image_view.image = [SHPImageUtil circleImage:user_image];
        //            // update too old images
        //            double now = [[NSDate alloc] init].timeIntervalSince1970;
        //            double reload_timer_secs = 86400; // one day
        //            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
        //                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
        //                [self startIconDownload:user.username forIndexPath:indexPath];
        //            } else {
        //                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
        //            }
        //        }
        
        //        UIImageView *iv = (UIImageView *) [cell viewWithTag:1];
        //        NSString *imageURL = [SHPUser photoUrlByUsername:user.username];
        //        if(![self.imageCache getImage:imageURL]) {
        //            [self startIconDownload:user forIndexPath:indexPath];
        //            // if a download is deferred or in progress, return a placeholder image
        //            //            iv.image = [UIImage imageNamed:@"grid-big-empty-image.png"];
        //            iv.image = nil;
        //        } else {
        //            iv.image = [self.imageCache getImage:imageURL];
        //        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath indexpath %ld %ld", (long)indexPath.row, (long)indexPath.section);
    //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger userIndex = indexPath.row;
    ChatUser *selectedUser = nil;
    if (self.users) {
        selectedUser = [self.users objectAtIndex:userIndex];
        [self addGroupMember:selectedUser];
        [self dismissUsersMode];
        //        self.users = nil; // dismiss users list & show members list
        //        [self.tableView reloadData];
        //        self.searchBar.text = @"";
    }
}

-(void)dismissUsersMode {
    self.users = nil; // dismiss users list & enable show members list
    [self.tableView reloadData];
    self.searchBar.text = @"";
    self.tableView.allowsSelection = NO;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// UISEARCHBAR DELEGATE

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar {
    NSLog(@"start editing.");
}

//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
//    NSLog(@"SEARCH BUTTON PRESSED!");
//}

//-(void)searchBar:(UISearchBar *)_searchBar textDidChange:(NSString *)text {
-(void)searchBar:(UISearchBar*)_searchBar textDidChange:(NSString*)text {
    NSLog(@"_searchBar textDidChange...");
//    [self.currentRequest cancel];
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    NSLog(@"Scheduling new search for: %@", text);
    NSString *preparedText = [self prepareTextToSearch:text]; // [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![preparedText isEqualToString:@""]) {
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
    } else {
        // test reset. show "members" or nothing
        NSLog(@"show members...");
        [self dismissUsersMode];
    }
}

//-(void) userPaused:(NSTimer *)timer {
//    NSLog(@"(SHPSearchViewController) userPaused:");
//    NSString *text = self.searchBar.text;
//    self.textToSearch = [self prepareTextToSearch:text];
//    NSLog(@"timer on userPaused: searching for %@", self.textToSearch);
//
////    self.userDC = [[SHPUserDC alloc] init];
//    self.userDC = [[ChatUsersDC alloc] init];
//    self.userDC.delegate = self;
//    [self.userDC findByText:self.textToSearch page:0 pageSize:30 withUser:self.applicationContext.loggedUser];
////    [self.userDC searchByText:self.textToSearch location:nil page:0 pageSize:30 withUser:self.applicationContext.loggedUser];
//}

-(void) userPaused:(NSTimer *)timer {
    NSLog(@"(SHPSearchViewController) userPaused:");
    NSString *text = self.searchBar.text;
    self.textToSearch = [self prepareTextToSearch:text];
    NSLog(@"timer on userPaused: searching for %@", self.textToSearch);
    ChatContactsDB *db = [ChatContactsDB getSharedInstance];
    [db searchContactsByFullnameSynchronized:self.textToSearch completion:^(NSArray<ChatUser *> *users) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"USERS LOADED! %lu", (unsigned long)users.count);
            NSMutableArray<ChatUser *> *m_users = [users mutableCopy];
            ChatUser *me = [ChatManager getInstance].loggedUser;
            for (int i=0; i < m_users.count; i++) {
                ChatUser *user = [m_users objectAtIndex:i];
                NSLog(@"user-id: %@/%@", user.userId, user.fullname);
                if ([user.userId isEqualToString:me.userId]) {
                    NSLog(@"Admin user %@ removed.", me.userId);
                    [m_users removeObjectAtIndex:i];
                    break;
                }
            }
            self.users = m_users;
            self.tableView.allowsSelection = YES;
            [self.tableView reloadData];
        });
    }];
//    AlfrescoUsersDC *service = [[AlfrescoUsersDC alloc] init];
//    self.currentRequest = [service usersByText:self.textToSearch completion:^(NSArray<SHPUser *> *users) {
//        NSLog(@"USERS LOADED OK!");
//        // remove group's admin
//        NSMutableArray *m_users = [users mutableCopy];
//        for (int i=0; i < m_users.count; i++) {
//            SHPUser *user = [m_users objectAtIndex:i];
//            if ([user.username isEqualToString:self.applicationContext.loggedUser.username]) {
//                NSLog(@"Admin user %@ removed.", user.username);
//                [m_users removeObjectAtIndex:i];
//                break;
//            }
//        }
//        self.users = m_users;
//        self.tableView.allowsSelection = YES;
//        [self.tableView reloadData];
//    }];
}

-(NSString *)prepareTextToSearch:(NSString *)text {
    return [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
// DC delegate

//- (void)usersDidLoad:(NSArray *)__users usersDC:usersDC error:(NSError *)error {
//    NSLog(@"USERS LOADED OK!");
//    if (error) {
//        NSLog(@"Error loading users!");
//    }
//    if (usersDC == self.userDC) {
//        self.users = __users;
//        [self.tableView reloadData];
//    } else {
//        self.recentUsers = [__users mutableCopy];
//        [self saveRecents];
//        [self.tableView reloadData];
//    }
//
//}

//- (void)usersDidLoad:(NSArray *)__users usersDC:usersDC error:(NSError *)error {
////- (void)usersDidLoad:(NSMutableArray *)__users error:(NSError *)error {
//    NSLog(@"USERS LOADED OK!");
//    if (error) {
//        NSLog(@"Error loading users!");
//    }
//    // remove group's admin
//    NSMutableArray *m_users = [__users mutableCopy];
//    for (int i=0; i < m_users.count; i++) {
//        SHPUser *user = [m_users objectAtIndex:i];
//        if ([user.username isEqualToString:self.applicationContext.loggedUser.username]) {
//            NSLog(@"Admin user %@ removed.", user.username);
//            [m_users removeObjectAtIndex:i];
//            break;
//        }
//    }
//    self.users = m_users;
//    self.tableView.allowsSelection = YES;
//    [self.tableView reloadData];
//}
//
//-(void)networkError {
//    NSString *title = NSLocalizedString(@"NetworkErrorTitle", nil);
//    NSString *msg = NSLocalizedString(@"NetworkError", nil);
//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
//}


// dismiss modal

- (IBAction)CancelAction:(id)sender {
//    NSLog(@"dismiss %@", self.modalCallerDelegate);
//    [self.modalCallerDelegate setupViewController:self didCancelSetupWithInfo:nil];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(nil, YES);
        }];
    }
}

// IMAGE HANDLING

-(void)terminatePendingImageConnections {
//    NSLog(@"''''''''''''''''''''''   Terminate all pending IMAGE connections...");
//    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
//    NSLog(@"total downloads: %ld", (long)allDownloads.count);
//    for(SHPImageDownloader *obj in allDownloads) {
//        obj.delegate = nil;
//    }
//    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
{
//    NSString *imageURL = [SHPUser photoUrlByUsername:username];
//    //    NSLog(@"START DOWNLOADING IMAGE: %@ imageURL: %@", username, imageURL);
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
}

//- (void)startIconDownload:(SHPUser *)user forIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *imageURL = [SHPUser photoUrlByUsername:user.username];
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

//// called by our ImageDownloader when an icon is ready to be displayed
//- (void)appImageDidLoad:(UIImage *)image withURL:(NSString *)imageURL downloader:(SHPImageDownloader *)downloader
//{
//    image = [SHPImageUtil circleImage:image];
//    [self.imageCache addImage:image withKey:imageURL];
//    NSDictionary *options = downloader.options;
//    NSIndexPath *indexPath = [options objectForKey:@"indexPath"];
//    // if the cell for the image is visible updates the cell
//    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *index in indexes) {
//        if (index.row == indexPath.row && index.section == indexPath.section) {
//            UITableViewCell *cell = [(UITableView *)self.tableView cellForRowAtIndexPath:index];
//            UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
//            iv.image = image;
//        }
//    }
//    [self.imageDownloadsInProgress removeObjectForKey:imageURL];
//}

// members

//-(void)restoreMembers {
//    self.members = (NSMutableArray *) [self.applicationContext getVariable:@"groupMembers"];
//    if (!self.members) {
//        self.members = [[NSMutableArray alloc] init];
//        [self.applicationContext setVariable:@"groupMembers" withValue:self.members];
//    }
//}

-(void)addGroupMember:(ChatUser *)user {
    NSLog(@"Adding member: %@/%@", user.userId, user.fullname);
    [self.members addObject:user];
    [self enableCreateButton];
    [self.tableView reloadData];
}

-(BOOL)userIsMember:(ChatUser *) user {
    for (ChatUser *u in self.members) {
        if ([u.userId isEqualToString:user.userId]) {
            return YES;
        }
    }
    return NO;
}

-(void)removeButtonPressed:(id)sender {
    NSLog(@"removeButtonPressed!");
    
    UIButton *button = (UIButton *)sender;
    NSString *userid = (NSString *)button.property;
    
    int username_found_at_index = -1;
    int index = 0;
    for (ChatUser *u in self.members) {
        if ([u.userId isEqualToString:userid]) {
            NSLog(@"usr found at index %d", index);
            username_found_at_index = index;
        }
        index++;
    }
    
    if (username_found_at_index >= 0) {
        [self.members removeObjectAtIndex:username_found_at_index];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:username_found_at_index inSection:0];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [self enableCreateButton];
    }
    else {
        NSLog(@"ERROR: username_found_at_index can't be -1");
    }
    
}

-(void)enableCreateButton {
    if (self.members.count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

// scroll delegate

// Somewhere in your implementation file:
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

// end

-(void)dealloc {
    NSLog(@"SEARCH USERS VIEW DEALLOCATING...");
}

- (IBAction)createGroupAction:(id)sender {
    if (self.completionCallback) {
        ChatGroup *group = [[ChatGroup alloc] init];
        group.groupId = [[ChatManager getInstance] newGroupId];
        NSMutableArray *membersIDs = [[NSMutableArray alloc] init];
        for (ChatUser *u in self.members) {
            [membersIDs addObject:u.userId];
        }
        NSString *me = [ChatManager getInstance].loggedUser.userId;
        [membersIDs addObject:me];
        group.members = [ChatGroup membersArray2Dictionary:membersIDs];
        group.name = self.groupName;
        group.owner = me;
        group.user = me;
        group.createdOn = [[NSDate alloc] init];
        ChatManager *chat = [ChatManager getInstance];
        NSLog(@"Creating group: %@", group.name);
        [self showWaiting:@"Creo gruppo..."];
        [chat createGroup:group withCompletionBlock:^(ChatGroup *group, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideWaiting];
                if (error) {
                    [self alert:[ChatLocal translate:@"Group creation error"]];
                }
                else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        self.completionCallback(group, NO);
                    }];
                }
            });
        }];
    }
}

-(void)showWaiting:(NSString *)label {
    if (!HUD) {
        HUD = [[ChatProgressView alloc] initWithWindow:self.view.window];
        [self.view.window addSubview:HUD];
    }
    HUD.center = self.view.center;
    HUD.labelText = label;
    HUD.animationType = ChatProgressViewAnimationZoom;
    [HUD show:YES];
}

-(void)hideWaiting {
    [HUD hide:YES];
}

-(void)alert:(NSString *)msg {
    UIAlertController *view = [UIAlertController
                               alertControllerWithTitle:msg
                               message:nil
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction
                              actionWithTitle:@"OK"
                              style:UIAlertActionStyleDefault
                              handler:nil];
    [view addAction:confirm];
    [self presentViewController:view animated:YES completion:nil];
}

@end
