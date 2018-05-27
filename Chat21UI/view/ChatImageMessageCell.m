//
//  ChatImageMessageCell.m
//  chat21
//
//  Created by Andrea Sponziello on 06/05/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatImageMessageCell.h"
#import "ChatMessage.h"
#import "ChatUtil.h"
#import "ChatLocal.h"
#import "ChatMessageMetadata.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatImageUtil.h"

@implementation ChatImageMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents imageCache:(ChatImageCache *)imageCache completion:(void(^)(UIImage *image)) callback {
    NSString *dateChat;
    NSDate *dateToday = [NSDate date];
    int numberDaysPrevChat = 0;
    int numberDaysNextChat = 0;
    ChatMessage *previousMessage;
    ChatMessage *nextMessage;
    UIView *backBox = self.messageBackgroundView;
    backBox.layer.masksToBounds = YES;
    backBox.layer.cornerRadius = 8.0;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.timeLabel.text = [message dateFormattedForListView];
    UILabel *labelDay = self.dateLabel;//(UILabel *)[cell viewWithTag:30];
    if (indexPath.row>0) {
        previousMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row-1)];
        if(messages.count > (indexPath.row+1)){
            nextMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row+1)];
            numberDaysNextChat = (int)[ChatUtil daysBetweenDate:message.date andDate:nextMessage.date];
        }
        numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:previousMessage.date andDate:message.date];
        dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
    }
    else {
        numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:message.date andDate:dateToday];
        dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
    }
    if (numberDaysPrevChat>0) {
        labelDay.text = dateChat;
    }
    else {
        labelDay.text = @"";
    }
    UIImageView *status_image_view = self.statusImageView;
    [ChatMessageCell setStatusImage:message statusImage:status_image_view];
    
    // image
    
    // events
    UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:viewController action:@selector(tapOnCell:)];
    UIGestureRecognizer *longTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:viewController action:@selector(longTapOnCell:)];
    [self.messageImageView addGestureRecognizer:tapGestureRecognizer];
    [self.messageImageView addGestureRecognizer:longTapGestureRecognizer];
    
    self.messageImageView.userInteractionEnabled = YES;
    
    UIImage *cached_image = ((ChatImageWrapper *)[imageCache getImage:message.messageId]).image;
    if (cached_image) {
        CGSize size = [ChatMessageCell computeImageSize:message];
        self.imageHeightConstraint.constant = size.height;
        self.imageWidthConstraint.constant = size.width;
        self.messageImageView.image = cached_image;
        return;
    }
    else {
        CGSize size = [ChatMessageCell computeImageSize:message];
        self.imageHeightConstraint.constant = size.height;
        self.imageWidthConstraint.constant = size.width;
        //        UIImage *placeholder_image = [message imagePlaceholder];
        self.messageImageView.image = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            if ([message imageExistsInMediaFolder]) {
                UIImage *image = [message imageFromMediaFolder];
//                NSLog(@"image on disk size w: %f h: %f", image.size.width, image.size.height);
                UIImage *scaled_image = [ChatImageUtil scaleImage:image toSize:size];
//                NSLog(@"image resized size w: %f h: %f", scaled_image.size.width, scaled_image.size.height);
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(scaled_image);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(nil); // -> start download
                });
            }
        });
    }
}

@end
