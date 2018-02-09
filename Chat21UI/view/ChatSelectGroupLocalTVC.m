//
//  ChatSelectGroupLocalTVC.m
//  bppmobile
//
//  Created by Andrea Sponziello on 26/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatSelectGroupLocalTVC.h"
//#import "ChatModalCallerDelegate.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatGroup.h"
#import "ChatManager.h"
#import "ChatUser.h"
#import "ChatUtil.h"
#import "ChatLocal.h"

@interface ChatSelectGroupLocalTVC ()

@end

@implementation ChatSelectGroupLocalTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.groups = nil;
    
    self.navigationItem.title = [ChatLocal translate:@"Select group"];
    self.cancelButton.title = [ChatLocal translate:@"cancel"];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self loadGroups];
//    [self initImageCache];
}

-(void)disposeResources {
    NSLog(@"Disposing pending image connections...");
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
    if (self.groups) {
        return self.groups.count;
    }
    else {
        return 0;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (self.groups) {
        long groupIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"group_cell"];
        ChatGroup *group = [self.groups objectAtIndex:groupIndex];
        UILabel *name_label = (UILabel *)[cell viewWithTag:2];
        name_label.text = group.name;
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"group-conversation-avatar"]];
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        image_view.image = circled;
    }
    else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"message_cell"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger userIndex = indexPath.row;
    ChatGroup *selectedGroup = nil;
    if (self.groups) {
        selectedGroup = [self.groups objectAtIndex:userIndex];
    }
    [self selectGroup:selectedGroup];
}

-(void)selectGroup:(ChatGroup *)selectedGroup {
//    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
//    [options setObject:selectedGroup forKey:@"group"];
//    [self.modalCallerDelegate setupViewController:self didFinishSetupWithInfo:options];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(selectedGroup, NO);
        }];
    }
}

-(void)loadGroups {
//    ChatGroupsDB *db = [ChatGroupsDB getSharedInstance];
//    ChatUser *user = [ChatManager getSharedInstance].loggedUser;
//    NSMutableArray *groups = [db getAllGroupsForUserSyncronized:user.userId];
    NSDictionary *groups_dict = [[ChatManager getInstance] allGroups];
    NSLog(@"GROUPS LOADED! %lu", (unsigned long) self.groups.count);
    self.groups = [[NSMutableArray alloc] init];
    for(NSString *key in [groups_dict allKeys]) {
        [self.groups addObject:[groups_dict objectForKey:key]];
    }
    [self.tableView reloadData];
}

// dismiss modal

- (IBAction)CancelAction:(id)sender {
//    NSLog(@"dismissing %@", self.modalCallerDelegate);
    [self disposeResources];
    [self.view endEditing:YES];
//    [self.modalCallerDelegate setupViewController:self didCancelSetupWithInfo:nil];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(nil, YES);
        }];
    }
}

-(void)dealloc {
    NSLog(@"SEARCH USERS VIEW DEALLOCATING...");
}

@end
