//
//  ChatUserCellConfigurator.m
//  chat21
//
//  Created by Andrea Sponziello on 10/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatUserCellConfigurator.h"
#import "ChatLocal.h"
#import "ChatUser.h"
#import "ChatGroup.h"
#import "ChatDiskImageCache.h"
#import "ChatUtil.h"
#import "ChatSelectUserLocalVC.h"
#import "ChatManager.h"

@implementation ChatUserCellConfigurator

-(id)initWith:(ChatSelectUserLocalVC *)vc {
    if (self = [super init]) {
        self.vc = vc;
        self.tableView = vc.tableView;
        self.imageCache = [ChatManager getInstance].imageCache;
        self.group = vc.group;
        self.tasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(UITableViewCell *)configureCellAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0 && self.vc.synchronizing) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
        [indicator startAnimating];
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
        messageLabel.text = [ChatLocal translate:@"Synchronizing contacts"];
    }
    else if (indexPath.section == 0 && self.vc.users) {
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.vc.users objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
    }
//    else if (indexPath.section == 0 && recentUsers.count > 0) {
//        // show recents
//        long userIndex = indexPath.row;
//        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
//        ChatUser *user = [recentUsers objectAtIndex:userIndex];
//
//        [self setupUserLabel:user cell:cell];
//    }
//    else if (indexPath.section == 1 && self.vc.allUsers.count > 0) {
//        long userIndex = indexPath.row;
//        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
//        ChatUser *user = [self.vc.allUsers objectAtIndex:userIndex];
//        [self setupUserLabel:user cell:cell];
//        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
//    }
    return cell;
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

-(void)setImageForCell:(UITableViewCell *)cell imageURL:(NSString *)imageURL {
    // get from cache first
    UIImage *image = [self setupPhotoCell:cell imageURL:imageURL];
    // then from remote
    if (image == nil) {
        NSURLSessionDataTask *task = [self.imageCache getImage:imageURL sized:120 circle:YES completionHandler:^(NSString *imageURL, UIImage *image) {
            NSLog(@"requested-image-url: %@ > image: %@", imageURL, image);
            if (!image) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"REQ-IMAGE-URL: %@ > IMAGE: %@", imageURL, image);
                // find indexpath of this imageURL (aka conversation).
                int index_path_row = 0;
                int index_path_section = 0; //self.vc.users ? 0 : 1;
//                NSArray <ChatUser *> *users;
//                if (index_path_section == 0) {
//                    users = self.vc.users;
//                }
//                else {
//                    users = self.vc.allUsers;
//                }
                NSIndexPath *cellIndexPath = nil;
                for (ChatUser *user in self.vc.users) {
                    if ([user.profileThumbImageURL isEqualToString:imageURL]) {
                        cellIndexPath = [NSIndexPath indexPathForRow:index_path_row inSection:index_path_section];
                        break;
                    }
                    index_path_row++;
                }
                if (cellIndexPath && [self isIndexPathVisible:cellIndexPath] && !self.vc.synchronizing) {
                    UITableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:cellIndexPath];
                    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
                    if (!cell) {
                        return;
                    }
                    else if (image) {
                        image_view.image = image;
                    }
                    else {
                        [self setupDefaultImageFor:image_view];
                    }
                }
            });
        }];
        [self.tasks setObject:task forKey:imageURL];
    }
}

-(void)setupDefaultImageFor:(UIImageView *)imageView {
    UIImage *avatar_circle_image = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
    imageView.image = avatar_circle_image;
}

-(UIImage *)setupPhotoCell:(UITableViewCell *)cell imageURL:(NSString *)imageURL {
    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
    NSURL *url = [NSURL URLWithString:imageURL];
//    NSLog(@"IMAGEURL_URL: %@", url);
    NSString *cache_key = [self.imageCache urlAsKey:url];
    NSLog(@"cache_key: %@", cache_key);
    UIImage *image = [self.imageCache getCachedImage:cache_key sized:120 circle:YES];
    if (image) {
        image_view.image = image;
    }
    else {
        [self setupDefaultImageFor:image_view];
    }
    return image;
}

-(BOOL)isIndexPathVisible:(NSIndexPath *)indexPath {
    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *index in indexes) {
        if (indexPath.row == index.row && indexPath.section == index.section) {
            return YES;
        }
    }
    return NO;
}

-(void)teminatePendingTasks {
    for (NSString *k in self.tasks.allKeys) {
        [self.tasks[k] cancel];
    }
}

@end
