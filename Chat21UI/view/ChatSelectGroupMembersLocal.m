//
//  ChatSelectGroupMembersLocal.m
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
#import "ChatManager.h"
#import "ChatDiskImageCache.h"
#import "ChatSelectGroupMembersCellConfigurator.h"

@interface ChatSelectGroupMembersLocal () {
    ChatProgressView *HUD;
}
@end

@implementation ChatSelectGroupMembersLocal

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [ChatLocal translate:@"add members"];
    self.users = nil;
    self.searchBar.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.members = [[NSMutableArray alloc] init];
    self.createButton.title = [ChatLocal translate:@"create"];
    self.searchBar.placeholder = [ChatLocal translate:@"contact name"];
    [self.searchBar becomeFirstResponder];
    [self enableCreateButton];
    self.cellConfigurator = [[ChatSelectGroupMembersCellConfigurator alloc] initWith:self];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //    NSLog(@"VIEW WILL DISAPPEAR...");
    if (self.isMovingFromParentViewController) {
        NSLog(@"VIEW WILL DISAPPEAR...DISMISSING..");
        [self disposeResources];
    }
}

-(void)disposeResources {
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
    if(self.users && self.users.count > 0) {
        NSInteger num = self.users.count;
        return num;
    } else if (self.members && self.members > 0) {
        NSInteger num = self.members.count;
        return num;
    }
    else {
        NSLog(@"0 rows.");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    cell = [self.cellConfigurator configureCellAtIndexPath:indexPath];
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
        [self resetSearchTimer];
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
    } else {
        // test reset. show "members" or nothing
        NSLog(@"show members...");
        [self dismissUsersMode];
    }
}

-(void)resetSearchTimer {
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
}

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
}

-(NSString *)prepareTextToSearch:(NSString *)text {
    return [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// dismiss modal

- (IBAction)CancelAction:(id)sender {
    [self disposeResources];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(nil, YES);
        }];
    }
}

-(void)terminatePendingImageConnections {
    [self.cellConfigurator teminatePendingTasks];
}

-(void)addGroupMember:(ChatUser *)user {
    NSLog(@"Adding member: %@/%@", user.userId, user.fullname);
    [self.members addObject:user];
    [self enableCreateButton];
    [self.tableView reloadData];
}

//-(BOOL)userIsMember:(ChatUser *) user {
//    for (ChatUser *u in self.members) {
//        if ([u.userId isEqualToString:user.userId]) {
//            return YES;
//        }
//    }
//    return NO;
//}

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
        [self showWaiting:[ChatLocal translate:@"Creating group"]];
        [chat createGroup:group withCompletionBlock:^(ChatGroup *group, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [self hideWaiting];
                    [self alert:[ChatLocal translate:@"Group creation error"]];
                }
                else if (self.profileImage) {
                    [[ChatManager getInstance] uploadProfileImage:self.profileImage profileId:group.groupId completion:^(NSString *downloadURL, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Image uploaded. Download url: %@", downloadURL);
                            if (error) {
                                NSLog(@"Error during image upload.");
                            }
                            ChatDiskImageCache *imageCache = [ChatManager getInstance].imageCache;
                            [imageCache addImageToCache:self.profileImage withKey:[imageCache urlAsKey:[NSURL URLWithString:downloadURL]]];
                            // adds also a local thumb in cache. The remote thumb get time to be created
                            // and the rendering of conversations will leave the new group conversation
                            // without a downloaded image.
                            NSString *thumbImageURL = [ChatManager profileThumbImageURLOf:group.groupId];
                            [imageCache addImageToCache:self.profileImage withKey:[imageCache urlAsKey:[NSURL URLWithString:thumbImageURL]]];
                            [imageCache getCachedImage:thumbImageURL sized:120 circle:true];
                            
                            [self dismiss:group];
                        });
                    } progressCallback:nil];
                }
                else {
                    [self dismiss:group];
                }
            });
        }];
    }
}

-(void)dismiss:(ChatGroup *)group {
    [self hideWaiting];
    [self disposeResources];
    [self dismissViewControllerAnimated:YES completion:^{
        self.completionCallback(group, NO);
    }];
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
