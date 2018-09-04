//
//  CellConfigurator.m
//  Chat21
//
//  Created by Andrea Sponziello on 28/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "CellConfigurator.h"
#import "ChatConversation.h"
#import "ChatImageCache.h"
#import "ChatConversationsVC.h"
#import "ChatImageWrapper.h"
#import "ChatManager.h"
#import "ChatGroupsHandler.h"
#import "ChatGroup.h"
#import "ChatUtil.h"
#import <QuartzCore/QuartzCore.h>
#import "ChatLocal.h"
#import "ChatDiskImageCache.h"

@implementation CellConfigurator

-(id)initWithTableView:(UITableView *)tableView imageCache:(ChatDiskImageCache *)imageCache {
    if (self = [super init]) {
//        self.imageUrlAtIndexPath = [[NSMutableDictionary alloc] init];
        self.tableView = tableView;
        self.imageCache = imageCache;
    }
    return self;
}

-(UITableViewCell *)configureConversationCell:(ChatConversation *)conversation indexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (!conversation.isDirect) {
        cell = [self configureGroupConversationCell:conversation indexPath:indexPath];
    } else {
        cell = [self configureDirectConversationCell:conversation indexPath:indexPath];
    }
    return cell;
}

-(UITableViewCell *)configureGroupConversationCell:(ChatConversation *)conversation indexPath:(NSIndexPath *)indexPath {
    
    //    NSLog(@"Configuring group cell.");
    NSString *groupId = conversation.recipient;
    ChatGroup *group = [[ChatManager getInstance] groupById:groupId];
    
    NSString *me = [ChatManager getInstance].loggedUser.userId;
    static NSString *conversationCellName = @"conversationGroupCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:conversationCellName forIndexPath:indexPath];
    
    UILabel *subject_label = (UILabel *)[cell viewWithTag:2];
    UILabel *message_label = (UILabel *)[cell viewWithTag:3];
    UILabel *group_message_label = (UILabel *)[cell viewWithTag:22];
    UILabel *sender_label = (UILabel *)[cell viewWithTag:20];
    
    UILabel *date_label = (UILabel *)[cell viewWithTag:4];
    
    // SUBJECT LABEL
    
    NSString *groupName = conversation.recipientFullname;
    subject_label.text = groupName;
    
    if (conversation.status == CONV_STATUS_FAILED) {
        message_label.hidden = NO;
        sender_label.hidden = YES;
        group_message_label.hidden = YES;
        message_label.text = [[NSString alloc] initWithFormat:@"Errore nella creazione del gruppo. Tocca per riprovare"];
    }
    else if (conversation.status == CONV_STATUS_JUST_CREATED) {
        message_label.hidden = NO;
        sender_label.hidden = YES;
        group_message_label.hidden = YES;
        message_label.text = conversation.last_message_text;
    }
    else if (conversation.status == CONV_STATUS_LAST_MESSAGE) {
        message_label.hidden = YES;
        sender_label.hidden = NO;
        group_message_label.hidden = NO;
        group_message_label.text = [conversation textForLastMessage:me];
        NSString *sender_display_text = [CellConfigurator displayUserOfGroupConversation:conversation];
        sender_label.text = sender_display_text;
    }
    [CellConfigurator archiveLabel:cell archived:conversation.archived];
    [self setImageForIndexPath:indexPath cell:cell imageURL:[ChatUtil profileThumbImageURLOf:group.groupId] typeDirect:NO];
    date_label.text = [conversation dateFormattedForListView];
    if (conversation.is_new) {
        // BOLD STYLE
        subject_label.font = [UIFont boldSystemFontOfSize:subject_label.font.pointSize];
        // CONV_STATUS_JUST_CREATED
        message_label.textColor = [UIColor blackColor];
        message_label.font = [UIFont boldSystemFontOfSize:message_label.font.pointSize];
        // CONV_STATUS_LAST_MESSAGE
        group_message_label.textColor = [UIColor blackColor];
        group_message_label.font = [UIFont boldSystemFontOfSize:message_label.font.pointSize];
    }
    else {
        // NORMAL STYLE
        subject_label.font = [UIFont systemFontOfSize:subject_label.font.pointSize];
        // CONV_STATUS_JUST_CREATED
        message_label.textColor = [UIColor lightGrayColor];
        message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
        // CONV_STATUS_LAST_MESSAGE
        group_message_label.textColor = [UIColor lightGrayColor];
        group_message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
    }
    return cell;
}

+(void)changeReadStatus:(ChatConversation *)conversation forCell:(UITableViewCell *)cell {
    UILabel *subject_label = (UILabel *)[cell viewWithTag:2];
    UILabel *message_label = (UILabel *)[cell viewWithTag:3];
    UILabel *group_message_label = (UILabel *)[cell viewWithTag:22];
    if (conversation.is_new) {
        // BOLD STYLE
        subject_label.font = [UIFont boldSystemFontOfSize:subject_label.font.pointSize];
        // CONV_STATUS_JUST_CREATED
        message_label.textColor = [UIColor blackColor];
        message_label.font = [UIFont boldSystemFontOfSize:message_label.font.pointSize];
        // CONV_STATUS_LAST_MESSAGE
        group_message_label.textColor = [UIColor blackColor];
        group_message_label.font = [UIFont boldSystemFontOfSize:message_label.font.pointSize];
    }
    else {
        // NORMAL STYLE
        subject_label.font = [UIFont systemFontOfSize:subject_label.font.pointSize];
        // CONV_STATUS_JUST_CREATED
        message_label.textColor = [UIColor lightGrayColor];
        message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
        // CONV_STATUS_LAST_MESSAGE
        group_message_label.textColor = [UIColor lightGrayColor];
        group_message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
    }
}

-(UITableViewCell *)configureDirectConversationCell:(ChatConversation *)conversation indexPath:(NSIndexPath *)indexPath {
    NSLog(@"Rendering conversation cell for user: %@", conversation.conversWith);
    //    NSLog(@"-------------- DIRECT %@ SENDR %@" , conversation.last_message_text, conversation.sender);
    NSString *me = [ChatManager getInstance].loggedUser.userId;
    static NSString *conversationCellName = @"conversationDMCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:conversationCellName forIndexPath:indexPath];
    UILabel *subject_label = (UILabel *)[cell viewWithTag:2];
    UILabel *message_label = (UILabel *)[cell viewWithTag:3];
    //    UILabel *sender_label = (UILabel *)[cell viewWithTag:20];
    
    UILabel *date_label = (UILabel *)[cell viewWithTag:4];
    //    NSLog(@"DATELABEL..... %@", date_label);
    subject_label.text = conversation.conversWith_fullname ? conversation.conversWith_fullname : conversation.conversWith;
    
    message_label.hidden = NO;
    //    sender_label.hidden = YES;
    message_label.text = [conversation textForLastMessage:me];
    [self setImageForIndexPath:indexPath cell:cell imageURL:[ChatUtil profileThumbImageURLOf:conversation.conversWith] typeDirect:YES];
    date_label.text = [conversation dateFormattedForListView];
    //    NSLog(@"date lebel text %@", date_label.text);
    if (conversation.status == CONV_STATUS_LAST_MESSAGE) {
        if (conversation.is_new) {
            // BOLD STYLE
            subject_label.font = [UIFont boldSystemFontOfSize:subject_label.font.pointSize];
            message_label.textColor = [UIColor blackColor];
            message_label.font = [UIFont boldSystemFontOfSize:message_label.font.pointSize];
        }
        else {
            // NORMAL STYLE
            subject_label.font = [UIFont systemFontOfSize:subject_label.font.pointSize];
            // direct
            message_label.textColor = [UIColor lightGrayColor];
            message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
        }
    } else {
        // NORMAL STYLE
        subject_label.font = [UIFont systemFontOfSize:subject_label.font.pointSize];
        message_label.textColor = [UIColor lightGrayColor];
        message_label.font = [UIFont systemFontOfSize:message_label.font.pointSize];
    }
    
    [CellConfigurator archiveLabel:cell archived:conversation.archived];
    return cell;
}

+(NSString *)displayUserOfGroupConversation:(ChatConversation *)c {
    NSString *displayName;
    // use fullname if available
    if (c.senderFullname) {
        NSString *trimmedFullname = [c.senderFullname stringByTrimmingCharactersInSet:
                                     [NSCharacterSet whitespaceCharacterSet]];
        if (trimmedFullname.length > 0) {
            displayName = trimmedFullname;
        }
    }
    
    // if fullname not available use username instead
    if (!displayName) {
        displayName = c.sender;
    }
    NSString *_displayName = [[NSString alloc] initWithFormat:@"%@:", displayName];
    return _displayName;
}

+(void)archiveLabel:(UITableViewCell *)cell archived:(BOOL)archived {
    UILabel *label = (UILabel *)[cell viewWithTag:80];
    if (label) {
        if (archived) {
            label.hidden = NO;
            label.layer.cornerRadius = 5.0f;
            label.layer.masksToBounds = NO;
            label.layer.borderWidth = .5f;
            label.layer.borderColor = [UIColor grayColor].CGColor;
        }
        else {
            label.hidden = YES;
        }
    }
    label.text = [ChatLocal translate:@"ArchivedBadgeLabel"];
}

-(void)setImageForIndexPath:(NSIndexPath *)indexPath cell:(UITableViewCell *)cell imageURL:(NSString *)imageURL typeDirect:(BOOL)typeDirect {
    UIImage *image = [self setupCellPhotoForCell:cell typeDirect:typeDirect imageURL:imageURL];
    if (image == nil) {
        [self.imageCache getImage:imageURL sized:120 circle:YES completionHandler:^(NSString *imageURL, UIImage *image) {
            UIImage *circle_image = image; //[ChatUtil circleImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self isIndexPathVisible:indexPath]) {
                    UITableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
                    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
                    if (!cell) {
                        return;
                    }
                    if (image) {
                        image_view.image = circle_image;
                    }
                    else {
                        [self setupDefaultImageFor:image_view typeDirect:typeDirect];
                    }
                }
            });
        }];
    }
}

-(void)setupDefaultImageFor:(UIImageView *)imageView typeDirect:(BOOL)typeDirect {
    UIImage *avatar_circle_image = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
    UIImage *group_avatar_image = [UIImage imageNamed:@"group-conversation-avatar"];
    if (typeDirect) {
        imageView.image = avatar_circle_image;
    }
    else {
        imageView.image = group_avatar_image;
    }
}

-(UIImage *)setupCellPhotoForCell:(UITableViewCell *)cell typeDirect:(BOOL)typeDirect imageURL:(NSString *)imageURL {
    UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
    NSURL *url = [NSURL URLWithString:imageURL];
    NSLog(@"IMAGEURLK %@", imageURL);
    NSString *cache_key = [self.imageCache urlAsKey:url];
    UIImage *image = [self.imageCache getCachedImage:cache_key sized:120 circle:YES];
    
    if (image) {
//        UIImage *circle_image = image; //[ChatUtil circleImage:image];
        image_view.image = image;
    }
    else {
        [self setupDefaultImageFor:image_view typeDirect:typeDirect];
//        UIImage *avatar_circle_image = [ChatUtil circleImage:[UIImage imageNamed:@"avatar"]];
//        UIImage *group_avatar_image = [UIImage imageNamed:@"group-conversation-avatar"];
//        if (typeDirect) {
//            image_view.image = avatar_circle_image;
//        }
//        else {
//            image_view.image = group_avatar_image;
//        }
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

@end

