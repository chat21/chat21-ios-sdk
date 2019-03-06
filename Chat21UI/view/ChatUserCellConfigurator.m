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
#import "ChatImageUtil.h"
#import "CellConfigurator.h"

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
//    NSLog(@"Decoding cell (vc: %@ - table: %@ -  synch: %d) for indexpath.row: %ld .section: %ld", self.vc,  self.vc.tableView, self.vc.synchronizing, (long)indexPath.row, (long)indexPath.section);
    if (self.vc.synchronizing) {
//        NSLog(@"decoded cell WaitCell");
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
        [indicator startAnimating];
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
        messageLabel.text = [ChatLocal translate:@"Synchronizing contacts"];
    }
    else if (self.vc.users) {
//        NSLog(@"decoded cell UserCell");
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.vc.users objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        [self setImageForCell:cell imageURL:user.profileThumbImageURL];
    }
//    else {
//        NSLog(@"cannot decode a valid cell for indexpath.row: %ld .section: %ld", (long)indexPath.row, (long)indexPath.section);
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
    int size = SELECT_USER_LIST_CELL_SIZE;
    //UIImage *image = [self setupPhotoCell:cell imageURL:imageURL];
    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
    UIImage *image = [CellConfigurator setupPhotoCell:image_view typeDirect:YES imageURL:imageURL imageCache:self.imageCache size:size];
    // then from remote
    if (image == nil) {
        NSURLSessionDataTask *task = [self.imageCache getImage:imageURL sized:size circle:YES completionHandler:^(NSString *imageURL, UIImage *image) {
            NSLog(@"requested-image-url-user-CONFIGURATOR: %@ > image: %@", imageURL, image);
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
                // find indexpath of this imageURL (aka conversation).
                int index_path_row = 0;
                int index_path_section = 0; //self.vc.users ? 0 : 1;
                NSIndexPath *cellIndexPath = nil;
                for (ChatUser *user in self.vc.users) {
                    if ([user.profileThumbImageURL isEqualToString:imageURL]) {
                        cellIndexPath = [NSIndexPath indexPathForRow:index_path_row inSection:index_path_section];
                        break;
                    }
                    index_path_row++;
                }
                
                 if (cellIndexPath && [CellConfigurator isIndexPathVisible:cellIndexPath tableView:self.tableView] && !self.vc.synchronizing) {
               // if (cellIndexPath && [self isIndexPathVisible:cellIndexPath] && !self.vc.synchronizing) {
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
        if (task != nil) {
            [self.tasks setObject:task forKey:imageURL];
        }
    }
}

-(void)teminatePendingTasks {
    for (NSString *k in self.tasks.allKeys) {
        NSURLSessionDataTask *task = self.tasks[k];
        [task cancel];
        NSLog(@"Cancel TCP connection: %@", task);
    }
}

@end
