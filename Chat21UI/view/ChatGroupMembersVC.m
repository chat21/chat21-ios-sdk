//
//  ChatGroupMembersVC.m
//  Smart21
//
//  Created by Andrea Sponziello on 05/05/15.
//
//

#import "ChatGroupMembersVC.h"
#import "ChatManager.h"
#import "ChatGroup.h"
#import "ChatUtil.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatUser.h"
#import "ChatSelectUserLocalVC.h"
#import "ChatUser.h"
#import "ChatUIManager.h"

@interface ChatGroupMembersVC ()

@end

@implementation ChatGroupMembersVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.members_array = [ChatGroup membersDictionary2Array:self.group.members];
    self.navigationItem.title = NSLocalizedString(@"Members", nil);
}

-(void)viewWillAppear:(BOOL)animated {
    ChatUser *loggeduser = [ChatManager getInstance].loggedUser;
    if ([loggeduser.userId isEqualToString:self.group.owner]) {
        self.addMemberButton.enabled = YES;
        [self.addMemberButton setTintColor:nil];
    } else {
        self.addMemberButton.enabled = NO;
        [self.addMemberButton setTintColor: [UIColor clearColor]];
    }
}

-(void)showMemberMenu:(NSIndexPath *)indexPath {
    NSString *memberId = [self.group.membersFull objectAtIndex:indexPath.row].userId;
    UIAlertController *view = [UIAlertController
                               alertControllerWithTitle:nil
                               message:memberId
                               preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *info = [UIAlertAction
                           actionWithTitle:NSLocalizedString(@"Member info", nil)
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
                               NSLog(@"Go to profile");
                               [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                               [self goToProfileOf:memberId];
                           }];
    
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"CancelLKey", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 NSLog(@"Cancel");
                                 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                             }];
    
    UIAlertAction* remove = nil;
    if ([self canIRemoveMember:memberId]) {
        remove = [UIAlertAction
                  actionWithTitle:NSLocalizedString(@"Member remove", nil)
                  style:UIAlertActionStyleDestructive
                  handler:^(UIAlertAction * action)
                  {
                      NSLog(@"Removing...");
                      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                      [self removeMember:memberId];
                  }];
    }
    
    UIAlertAction* send_message = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Send message", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       NSLog(@"Send message");
                                       //                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                                       //                ChatUser *member = [[ChatUser alloc] init];
                                       //                member.userId = memberId;
                                       //                [ChatUtil moveToConversationViewWithUser:member sendMessage:nil];
                                   }];
    
    
    if (remove) {
        [view addAction:remove];
    }
    [view addAction:info];
    [view addAction:send_message];
    [view addAction:cancel];
    
    [self presentViewController:view animated:YES completion:nil];
}

-(BOOL)canIRemoveMember:(NSString *)memberId {
    ChatUser *loggeduser = [ChatManager getInstance].loggedUser;
    return [loggeduser.userId isEqualToString:self.group.owner] && // I'm a admin?
    ![memberId isEqualToString:self.group.owner]; // memberId is not admin??? OK, remove!
}

-(void)removeMember:(NSString *)memberId {
    ChatManager *chat = [ChatManager getInstance];
    //    Firebase *member_ref =
    [chat removeMember:memberId fromGroup:self.group withCompletionBlock:^(NSError *error) {
        if (error) {
            NSLog(@"Member %@ not removed. Error %@", memberId, error);
        } else {
            NSLog(@"member %@ successfully removed.", memberId);
            [self.group.members removeObjectForKey:memberId];
            [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }];
        }
    }];
    // TODO remove member_ref handler before go back from this view, if hanlder is still active.
    // TODO usa una callback per stabilire l'esito dell'operazione.
}

-(void)goToProfileOf:(NSString *)userId {
    //    UIStoryboard *profileSB = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    //    UINavigationController *profileNC = [profileSB instantiateViewControllerWithIdentifier:@"navigationProfile"];
    //    SHPHomeProfileTVC *profileVC = (SHPHomeProfileTVC *)[[profileNC viewControllers] objectAtIndex:0];
    //    profileVC.applicationContext = self.applicationContext;
    //    ChatUser *user = [[ChatUser alloc] init];
    //    user.userId = userId;
    //    profileVC.otherUser = user;
    //    NSLog(@"self.profileVC.otherUser %@", profileVC.otherUser.userId);
    //    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.group.membersFull.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    int index = (int) indexPath.row;
    
    UILabel *username = (UILabel *)[cell viewWithTag:1];
    NSString *user_id = [self.group.membersFull objectAtIndex:index].userId;
    NSString *user_display = [self.group.membersFull objectAtIndex:index].fullname;
    if ([user_id isEqualToString:self.group.owner]) {
        user_display = [[NSString alloc] initWithFormat:@"%@ (%@)", user_display, NSLocalizedString(@"Group administrator", nil)];
    }
    username.text = user_display;
    
    UIImageView *image_view = (UIImageView *)[cell viewWithTag:10];
    NSString *imageURL = @""; //[SHPUser photoUrlByUsername:user_id];
    ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
    UIImage *user_image = cached_image_wrap.image;
    if(cached_image_wrap == nil || user_image == nil) {
        NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", user_id);
        [self startIconDownload:user_id forIndexPath:indexPath];
        // if a download is deferred or in progress, return a placeholder image
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
        image_view.image = circled;
    } else {
        //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
        image_view.image = [ChatUtil circleImage:user_image];
        // update too old images
        double now = [[NSDate alloc] init].timeIntervalSince1970;
        double reload_timer_secs = 30;//86400; // one day
        if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
            NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", user_id, cached_image_wrap.createdTime, [[NSDate alloc] init]);
            [self startIconDownload:user_id forIndexPath:indexPath];
        } else {
            //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showMemberMenu:indexPath];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"AddMember"]) {
//        UINavigationController *navigationController = [segue destinationViewController];
//        NSLog(@"CLASS %@", [[[navigationController viewControllers] objectAtIndex:0] class]);
//        ChatSelectUserLocalVC *vc = (ChatSelectUserLocalVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.group = self.group;
//    }
}

// ******************
// IMAGE HANDLING
// ******************

- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
{
    //    NSString *imageURL = @""; //[SHPUser photoUrlByUsername:username];
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
}

//// callback for the icon loaded
//- (void)appImageDidLoad:(UIImage *)image withURL:(NSString *)imageURL downloader:(SHPImageDownloader *)downloader {
//    //    NSLog(@"+******** IMAGE AT URL: %@ DID LOAD: %@", imageURL, image);
//    if (!image) {
//        return;
//    }
//    //UIImage *circled = [SHPImageUtil circleImage:image];
//    [self.imageCache addImage:image withKey:imageURL];
//    NSDictionary *options = downloader.options;
//    NSIndexPath *indexPath = [options objectForKey:@"indexPath"];
//    //    NSLog(@"+******** appImageDidLoad row: %ld", indexPath.row);
//
//    // if the cell for the image is visible updates the cell
//    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *index in indexes) {
//        if (index.row == indexPath.row && index.section == indexPath.section) {
//            UITableViewCell *cell = [(UITableView *)self.tableView cellForRowAtIndexPath:index];
//            UIImageView *iv = (UIImageView *)[cell viewWithTag:10];
//            iv.image = [SHPImageUtil circleImage:image];
//        }
//    }
//    [self.imageDownloadsInProgress removeObjectForKey:imageURL];
//}

-(void)terminatePendingImageConnections {
    //    NSLog(@"''''''''''''''''''''''   Terminate all pending IMAGE connections...");
    //    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    //    //    NSLog(@"total downloads: %d", allDownloads.count);
    //    for(SHPImageDownloader *obj in allDownloads) {
    //        obj.delegate = nil;
    //    }
    //    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

// ******************
// END IMAGE HANDLING
// ******************

- (IBAction)addMember:(id)sender {
    NSLog(@"Add member");
    [[ChatUIManager getInstance] openSelectContactViewAsModal:self withCompletionBlock:^(ChatUser *contact, BOOL canceled) {
        if (canceled) {
            NSLog(@"Select Contact canceled");
        }
        else {
            NSLog(@"Selected new member: %@/%@", contact.fullname, contact.userId);
            NSString *user_id = contact.userId;
            [[ChatManager getInstance] addMember:user_id toGroup:self.group withCompletionBlock:^(NSError *error) {
                if (error) {
                    NSLog(@"Member %@ not added. Error %@",user_id, error);
                } else {
                    NSLog(@"Member %@ successfully added.", user_id);
                    [self.group.members setObject:user_id forKey:user_id];
                    [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                        });
                    }];
                }
            }];
        }
    }];
    
//    [[ChatUIManager getInstance] openSelectGroupViewAsModal:self withCompletionBlock:^(ChatGroup *group, BOOL canceled) {
//        if (canceled) {
//            NSLog(@"Select group canceled.");
//        }
//        else {
//            if (group) {
//                self.selectedGroupId = group.groupId;
//                [self openConversationWithUser:nil orGroup:group sendMessage:nil attributes:nil];
//            }
//            NSString *user_id = user.userId;
//            [[ChatManager getInstance] addMember:user_id toGroup:self.group withCompletionBlock:^(NSError *error) {
//                if (error) {
//                    NSLog(@"Member %@ not added. Error %@",user_id, error);
//                } else {
//                    NSLog(@"Member %@ successfully added.", user_id);
//                    [self.group.members setObject:user_id forKey:user_id];
//                    [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self.tableView reloadData];
//                        });
//                    }];
//                }
//            }];
//        }
//    }];
//    [self performSegueWithIdentifier:@"AddMember" sender:self];
}

//- (void)setupViewController:(UIViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo {
//    NSLog(@"setupViewController...");
//    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
//    {
//        ChatUser *user = nil;
//        if ([setupInfo objectForKey:@"user"]) {
//            user = [setupInfo objectForKey:@"user"];
//            NSString *user_id = user.userId;
//            [[ChatManager getInstance] addMember:user_id toGroup:self.group withCompletionBlock:^(NSError *error) {
//                if (error) {
//                    NSLog(@"Member %@ not added. Error %@",user_id, error);
//                } else {
//                    NSLog(@"Member %@ successfully added.", user_id);
//                    [self.group.members setObject:user_id forKey:user_id];
//                    [self.group completeGroupMembersMetadataWithCompletionBlock:^() {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self.tableView reloadData];
//                        });
//                    }];
//                }
//            }];
//        }
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//}
//
//- (void)setupViewController:(UIViewController *)controller didCancelSetupWithInfo:(NSDictionary *)setupInfo {
//    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
//    {
//        NSLog(@"Member selection Canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
//}

@end

