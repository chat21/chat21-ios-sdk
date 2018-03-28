//
//  ChatSelectUserLocalVC.m
//  bppmobile
//
//  Created by Andrea Sponziello on 13/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatSelectUserLocalVC.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatGroup.h"
#import "ChatDB.h"
#import "ChatUser.h"
#import "ChatContactsDB.h"
#import "ChatManager.h"
#import "ChatContactsSynchronizer.h"
#import "ChatUtil.h"
#import "ChatLocal.h"

@interface ChatSelectUserLocalVC () {
    ChatContactsSynchronizer *contacts;
}

@end

@implementation ChatSelectUserLocalVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.users = nil;
    if (self.group) {
        self.navigationItem.title = [ChatLocal translate:@"Add member"];
    } else {
        self.navigationItem.title = [ChatLocal translate:@"NewMessage"];
    }
    
    //    self.imageCache = self.applicationContext.smallImagesCache;
    
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    self.searchBar.delegate = self;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self initImageCache];
    ChatManager *chatm = [ChatManager getInstance];
    contacts = chatm.contactsSynchronizer;
    [self setupSynchronizing];
    [contacts addSynchSubscriber:self];
}

// SYNCH PROTOCOL

-(void)synchStart {
    NSLog(@"SYNCH-START");
    [self setupSynchronizing];
    [self.tableView reloadData];
}

-(void)synchEnd {
    NSLog(@"SYNCH-END");
    [self setupSynchronizing];
    [self.tableView reloadData];
}

-(void)setupSynchronizing {
    self.synchronizing = contacts.synchronizing;
    if (!self.synchronizing) {
        [self.searchBar becomeFirstResponder];
        [self search];
    } else {
        self.searchBar.userInteractionEnabled = NO;
    }
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //    [self search];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //    NSLog(@"AAA viewDidDisappear...isMoving: %d, isBeingDismissed: %d", self.isMovingFromParentViewController, self.isBeingDismissed);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //    NSLog(@"SEARCH USERS VIEW WILL DISAPPEAR...isMoving: %d, isBeingDismissed: %d", self.isMovingFromParentViewController, self.isBeingDismissed);
    //    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
    //        NSLog(@"SEARCH USERS VIEW WILL DISAPPEAR...DISMISSING..");
    //        [self disposeResources];
    //    }
}

-(void)disposeResources {
    [contacts removeSynchSubscriber:self];
    [self terminatePendingImageConnections];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.users) { // users found matching search criteria
        return 1;
    }
    return 2; // recentUsers, allUsers
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0 && self.synchronizing) {
        return 1; // message cell
    }
    else if (section == 0 && self.users) {
        return self.users.count;
    }
    else if (section == 0) {
        return self.recentUsers.count;
    }
    else if (section == 1) {
        return self.allUsers.count;
    }
    else {
        return 0;
    }
    
    //    if(self.users && self.users.count > 0) {
    //        NSInteger num = self.users.count;
    //        return num;
    //    } else if (self.recentUsers && self.recentUsers > 0) {
    //        NSInteger num = self.recentUsers.count;
    //        return num;
    //    }
    //    else {
    //        NSLog(@"0 rows.");
    //        return 0;
    //    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1 && self.allUsers.count > 0) {
        return [ChatLocal translate:@"all contacts"];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0 && self.synchronizing) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
        [indicator startAnimating];
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
        messageLabel.text = [ChatLocal translate:@"Synchronizing contacts"];
    }
    else if (indexPath.section == 0 && self.users) {
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        //        cell.contentView.backgroundColor = [UIColor whiteColor];
        ChatUser *user = [self.users objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        image_view.image = circled;
    }
    else if (indexPath.section == 0 && self.recentUsers.count > 0) {
        // show recents
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.recentUsers objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        // USER IMAGE
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:user.userId];
        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        UIImage *user_image = cached_image_wrap.image;
        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
            [self startIconDownload:user.userId forIndexPath:indexPath];
            // if a download is deferred or in progress, return a placeholder image
            UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
            image_view.image = circled;
        } else {
            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
            image_view.image = [ChatUtil circleImage:user_image];
            // update too old images
            double now = [[NSDate alloc] init].timeIntervalSince1970;
            double reload_timer_secs = 86400; // one day
            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
                [self startIconDownload:user.userId forIndexPath:indexPath];
            } else {
                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
            }
        }
    }
    //    else {
    //        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    //    }
    else if (indexPath.section == 1 && self.allUsers.count > 0) {
        // show recents
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.allUsers objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        // USER IMAGE
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:user.userId];
        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        UIImage *user_image = cached_image_wrap.image;
        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
            [self startIconDownload:user.userId forIndexPath:indexPath];
            // if a download is deferred or in progress, return a placeholder image
            UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
            image_view.image = circled;
        } else {
            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
            image_view.image = [ChatUtil circleImage:user_image];
            // update too old images
            double now = [[NSDate alloc] init].timeIntervalSince1970;
            double reload_timer_secs = 86400; // one day
            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
                [self startIconDownload:user.userId forIndexPath:indexPath];
            } else {
                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger userIndex = indexPath.row;
    ChatUser *selectedUser = nil;
    if (self.synchronizing) {
        return;
    }
    else if (self.users) {
        selectedUser = [self.users objectAtIndex:userIndex];
    }
    else if (indexPath.section == 0){
        selectedUser = [self.recentUsers objectAtIndex:userIndex];
    }
    else if (indexPath.section == 1) {
        selectedUser = [self.allUsers objectAtIndex:userIndex];
    }
    
    if (self.group) {
        if (![self.group isMember:selectedUser.userId]) {
            NSLog(@"Just in this group!");
            [self addUserToGroup:selectedUser];
        }
    } else {
        [self selectUser:selectedUser];
    }
}

-(void)setupUserLabel:(ChatUser *)user cell:(UITableViewCell *)cell {
    UILabel *fullnameLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *usernameLabel = (UILabel *) [cell viewWithTag:3];
    if (self.group && [self.group isMember:user.userId]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        fullnameLabel.textColor = [UIColor grayColor];
        usernameLabel.textColor = [UIColor grayColor];
        fullnameLabel.text = [user fullname];
        usernameLabel.text = [ChatLocal translate:@"Just in group"];
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        fullnameLabel.textColor = [UIColor blackColor];
        usernameLabel.textColor = [UIColor blackColor];
        fullnameLabel.text = user.fullname;
        usernameLabel.text = user.userId;
    }
}

-(void)addUserToGroup:(ChatUser *)selectedUser {
    NSString *message = [NSString stringWithFormat:[ChatLocal translate:@"Add user to group"], selectedUser.fullname, self.group.name];
    
    UIAlertController *view = [UIAlertController
                               alertControllerWithTitle:message
                               message:nil
                               preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *confirm = [UIAlertAction
                              actionWithTitle:[ChatLocal translate:@"Add"]
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [self selectUser:selectedUser];
                              }];
    
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:[ChatLocal translate:@"CancelLKey"]
                             style:UIAlertActionStyleDefault
                             handler:nil];
    
    [view addAction:confirm];
    [view addAction:cancel];
    
    [self presentViewController:view animated:YES completion:nil];
}

-(void)selectUser:(ChatUser *)selectedUser {
    //    [self updateRecentUsersWith:selectedUser];
    //    [self saveRecents];
    [self disposeResources];
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    [options setObject:selectedUser forKey:@"user"];
    [self.view endEditing:YES];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(selectedUser, NO);
        }];
    }
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
    //    NSLog(@"start editing.");
}

//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
//    NSLog(@"SEARCH BUTTON PRESSED!");
//}

//-(void)searchBar:(UISearchBar *)_searchBar textDidChange:(NSString *)text {
-(void)searchBar:(UISearchBar*)_searchBar textDidChange:(NSString*)text {
    NSLog(@"_searchBar textDidChange");
    //    [self.currentRequest cancel];
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    //    NSString *preparedText = [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
    //    if (![preparedText isEqualToString:@""]) {
    //        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
    //    } else {
    //        // test reset. show "recents" (when supported) or nothing
    //        NSLog(@"show recents...");
    //        self.users = nil;
    //        [self.tableView reloadData];
    //    }
}

-(void)userPaused:(NSTimer *)timer {
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    [self search];
    //    dispatch_queue_t serialDatabaseQueue;
    //    serialDatabaseQueue = dispatch_queue_create("db.sqllite", DISPATCH_QUEUE_SERIAL);
    //    NSLog(@"search queue %@", serialDatabaseQueue);
    //    dispatch_async(serialDatabaseQueue, ^{
    //    });
    
    //    AlfrescoUsersDC *service = [[AlfrescoUsersDC alloc] init];
    //    self.currentRequest = [service usersByText:self.textToSearch completion:^(NSArray<SHPUser *> *users) {
    //        NSLog(@"USERS LOADED OK!");
    //        self.users = users;
    //        [self.tableView reloadData];
    //    }];
}

-(void)search {
    NSString *text = self.searchBar.text;
    self.textToSearch = [self prepareTextToSearch:text];
    ChatContactsDB *db = [ChatContactsDB getSharedInstance];
    [db searchContactsByFullnameSynchronized:self.textToSearch completion:^(NSArray<ChatUser *> *users) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.users = users;
            [self.tableView reloadData];
        });
    }];
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
//        self.allUsers = [__users mutableCopy];
//        [self saveAllUsers];
//        [self.tableView reloadData];
//    }
//
//}

//-(void)networkError {
//    NSString *title = NSLocalizedString(@"NetworkErrorTitle", nil);
//    NSString *msg = NSLocalizedString(@"NetworkError", nil);
//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
//}


// dismiss modal

- (IBAction)CancelAction:(id)sender {
    [self disposeResources];
    [self.view endEditing:YES];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(nil, YES);
        }];
    }
}

// IMAGE HANDLING

-(void)terminatePendingImageConnections {
    //    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    //    for(SHPImageDownloader *obj in allDownloads) {
    //        obj.delegate = nil;
    //    }
    //    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
{
    
}



// all users

static NSString* const chatAllUsers = @"chatAllUsers";

//-(void)saveAllUsers {
//    [SHPCaching saveArray:self.allUsers inFile:chatAllUsers];
//}
//
//-(void)deleteAllUsers {
//    [SHPCaching deleteFile:chatAllUsers];
//}
//
//-(void)restoreAllUsers {
//    self.allUsers = [SHPCaching restoreArrayFromFile:chatAllUsers];
//    if (!self.allUsers) {
//        self.allUsers = [[NSMutableArray alloc] init];
//    }
//}

// recent users

//static NSString* const chatRecentUsers = @"chatRecentUsers";
//
//-(void)saveRecents {
//    [SHPCaching saveArray:self.recentUsers inFile:chatRecentUsers];
//}
//
//-(void)deleteRecents {
//    [SHPCaching deleteFile:chatRecentUsers];
//}
//
//-(void)restoreRecents {
//    self.recentUsers = [SHPCaching restoreArrayFromFile:chatRecentUsers];
//    if (!self.recentUsers) {
//        self.recentUsers = [[NSMutableArray alloc] init];
//    }
//}
//
//-(void)updateRecentUsersWith:(ChatUser *)user {
//    int index = 0;
//    for (ChatUser *u in self.recentUsers) {
//        if([u.userId isEqualToString: user.userId]) {
//            //            found = YES;
//            NSLog(@"Found this user AT INDEX %d. Removing.", index);
//            [self.recentUsers removeObjectAtIndex:index];
//            break;
//        }
//        index++;
//    }
//    [self.recentUsers insertObject:user atIndex:0];
//}

// scroll delegate

// Somewhere in your implementation file:
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
    //    NSLog(@"Will begin dragging");
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    NSLog(@"Did Scroll");
//}

// end

-(void)dealloc {
    NSLog(@"SEARCH USERS VIEW DEALLOCATING...");
}

@end

