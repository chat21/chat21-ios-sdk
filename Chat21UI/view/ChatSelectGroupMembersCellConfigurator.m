//
//  ChatSelectGroupMembersCellConfigurator.m
//  chat21
//
//  Created by Andrea Sponziello on 11/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatSelectGroupMembersCellConfigurator.h"
#import "ChatSelectGroupMembersLocal.h"
#import "ChatManager.h"
#import "ChatUser.h"
#import "ChatUtil.h"
#import "ChatLocal.h"
#import "UIView+Property.h"
#import "ChatDiskImageCache.h"

@implementation ChatSelectGroupMembersCellConfigurator

-(id)initWith:(ChatSelectGroupMembersLocal *)vc {
    if (self = [super init]) {
        self.vc = vc;
        self.tableView = vc.tableView;
        self.imageCache = [ChatManager getInstance].imageCache;
        self.tasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(UITableViewCell *)configureCellAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (self.vc.users && self.vc.users.count > 0) {
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.vc.users objectAtIndex:userIndex];
        UILabel *fullnameLabel = (UILabel *) [cell viewWithTag:2];
        UILabel *usernameLabel = (UILabel *) [cell viewWithTag:3];
        fullnameLabel.text = user.fullname;
        usernameLabel.text = user.userId;
        
        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
//        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
//        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
//        image_view.image = circled;
        
        // it's just a member
        
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
        ChatUser *user = [self.vc.members objectAtIndex:userIndex];
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
        
        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
//        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
//        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
//        image_view.image = circled;
    }
//    if (indexPath.section == 0 && self.vc.synchronizing) {
//        cell = [self.tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
//        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
//        [indicator startAnimating];
//        UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
//        messageLabel.text = [ChatLocal translate:@"Synchronizing contacts"];
//    }
//    else if (indexPath.section == 0 && self.vc.users) {
//        long userIndex = indexPath.row;
//        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
//        ChatUser *user = [self.vc.users objectAtIndex:userIndex];
//
//        [self setupUserLabel:user cell:cell];
//        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
//    }
    return cell;
}

-(void)removeButtonPressed:(id)sender {
    [self.vc removeButtonPressed:sender];
}

-(BOOL)userIsMember:(ChatUser *) user {
    for (ChatUser *u in self.vc.members) {
        if ([u.userId isEqualToString:user.userId]) {
            return YES;
        }
    }
    return NO;
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
                // find indexpath of this imageURL
                NSIndexPath *cellIndexPath = nil;
                NSArray *users;
                if (self.vc.users && self.vc.users.count > 0) {
                    users = self.vc.users;
                }
                else {
                    users = self.vc.members;
                }
                int index_path_row = 0;
                int index_path_section = 0;
                for (ChatUser *user in users) {
                    if ([user.profileThumbImageURL isEqualToString:imageURL]) {
                        cellIndexPath = [NSIndexPath indexPathForRow:index_path_row inSection:index_path_section];
                        break;
                    }
                    index_path_row++;
                }
                if (cellIndexPath && [self isIndexPathVisible:cellIndexPath]) {
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
