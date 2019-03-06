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
#import "CellConfigurator.h"
#import "ChatImageUtil.h"

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
    int size = SELECT_GROUP_MEMBER_LIST_CELL_SIZE;
    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
    UIImage *image = [CellConfigurator setupPhotoCell:image_view typeDirect:YES imageURL:imageURL imageCache:self.imageCache size:size];
    // then from remote
    if (image == nil) {
        NSURLSessionDataTask *task = [self.imageCache getImage:imageURL sized:size circle:YES completionHandler:^(NSString *imageURL, UIImage *image) {
            NSLog(@"requested-image-url-group-CONFIGURATOR: %@ > image: %@", imageURL, image);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"REQ-IMAGE-URL: %@ > IMAGE: %@", imageURL, image);
                if (!image) {
                    UIImage *avatar = [CellConfigurator avatarTypeDirect:YES];
                    NSString *key = [self.imageCache urlAsKey:[NSURL URLWithString:imageURL]];
                    NSString *sized_key = [ChatDiskImageCache sizedKey:key size:size];
                    UIImage *resized_image = [ChatImageUtil scaleImage:avatar toSize:CGSizeMake(size, size)];
                    [self.imageCache addImageToMemoryCache:resized_image withKey:sized_key];
                    return;
                }
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
                if (cellIndexPath && [CellConfigurator isIndexPathVisible:cellIndexPath tableView:self.tableView]) {
                    UITableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:cellIndexPath];
                    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
                    if (!cell) {
                        return;
                    }
                    else if (image) {
                        image_view.image = image;
                    }
                }
            });
        }];
//        NSLog(@"adding task: %@", task);
        if (task != nil) {
            [self.tasks setObject:task forKey:imageURL];
        }
    }
}

-(void)teminatePendingTasks {
    for (NSString *k in self.tasks.allKeys) {
        [self.tasks[k] cancel];
    }
}

@end
