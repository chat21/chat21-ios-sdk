//
//  ChatSelectUserLocalVC.m
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
#import "ChatUserCellConfigurator.h"

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
    
    self.searchBar.delegate = self;
    self.cancelButton.title = [ChatLocal translate:@"cancel"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    ChatManager *chatm = [ChatManager getInstance];
    contacts = chatm.contactsSynchronizer;
    [self setupSynchronizing];
    [contacts addSynchSubscriber:self];
    self.cellConfigurator = [[ChatUserCellConfigurator alloc] initWith:self];
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

-(void)disposeResources {
    [contacts removeSynchSubscriber:self];
    [self terminatePendingImageConnections];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    if (self.users || self.synchronizing) { // users found matching search criteria
//        return 1;
//    }
//    return 0;
//    return 2; // recentUsers, allUsers
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.synchronizing) {
        return 1; // message cell
    }
    else if (section == 0 && self.users) {
        return self.users.count;
    }
    else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    if (section == 1 && self.allUsers.count > 0) {
//        return [ChatLocal translate:@"all contacts"];
//    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
//    NSLog(@"Inside-Decoding cell (vc: %@ - table: %@ -  synch: %d) for indexpath.row: %ld .section: %ld", self,  self.tableView, self.synchronizing, (long)indexPath.row, (long)indexPath.section);
    NSLog(@"self.cellConfigurator: %@", self.cellConfigurator);
    cell = [self.cellConfigurator configureCellAtIndexPath:indexPath];
//    NSLog(@"Got cell: %@", cell);
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
    if (self.group) {
        if (![self.group isMember:selectedUser.userId]) {
            NSLog(@"Just in this group!");
            [self addUserToGroup:selectedUser];
        }
    } else {
        [self selectUser:selectedUser];
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
                             actionWithTitle:[ChatLocal translate:@"Cancel"]
                             style:UIAlertActionStyleDefault
                             handler:nil];
    
    [view addAction:confirm];
    [view addAction:cancel];
    
    [self presentViewController:view animated:YES completion:nil];
}

-(void)selectUser:(ChatUser *)selectedUser {
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

// UISEARCHBAR DELEGATE

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar {
    //    NSLog(@"start editing.");
}

-(void)searchBar:(UISearchBar*)_searchBar textDidChange:(NSString*)text {
    NSLog(@"_searchBar textDidChange");
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
}

-(void)userPaused:(NSTimer *)timer {
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    [self search];
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
    [self.cellConfigurator teminatePendingTasks];
}

// all users

static NSString* const chatAllUsers = @"chatAllUsers";

// scroll delegate

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

