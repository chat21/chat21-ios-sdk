//
//  ChatTextMessageRightCell.m
//  chat21
//
//  Created by Andrea Sponziello on 18/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatTextMessageRightCell.h"
#import "ChatMessage.h"
#import "ChatUtil.h"
#import "ChatLocal.h"
#import "ChatStyles.h"

@implementation ChatTextMessageRightCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents {
    ChatStyles *styles = [ChatStyles sharedInstance];
    NSString *dateChat;
    NSDate *dateToday = [NSDate date];
    int numberDaysPrevChat = 0;
    int numberDaysNextChat = 0;
    ChatMessage *previousMessage;
    ChatMessage *nextMessage;
    UIView *backBox = self.messageBackgroundView;
    backBox.backgroundColor = styles.ballonRightBackgroundColor;
    backBox.layer.masksToBounds = YES;
    backBox.layer.cornerRadius = 8.0;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *labelMessage = self.messageLabel;
    
    UIGestureRecognizer *longTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:viewController action:@selector(longTapOnCell:)];
    UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:viewController action:@selector(tapOnCell:)];
    [labelMessage addGestureRecognizer:longTapGestureRecognizer];
    [labelMessage addGestureRecognizer:tapGestureRecognizer];
    labelMessage.userInteractionEnabled = YES;
    [labelMessage setFont:styles.ballonFont];
    [labelMessage setTextColor:styles.ballonRightTextColor];
    
    [self attributedString:labelMessage text:message indexPath:indexPath rowComponents:rowComponents right_cell:YES];
    
    UILabel *labelTime = self.timeLabel;//(UILabel *)[cell viewWithTag:40];
    labelTime.text = [message dateFormattedForListView];
    
//    UILabel *labelNameUser = self.user//(UILabel *)[cell viewWithTag:20];
//    NSString *text_name_user = [self displayUserOfMessage:message];
//    labelNameUser.text = text_name_user;
    
    UILabel *labelDay = self.dateLabel;//(UILabel *)[cell viewWithTag:30];
    if(indexPath.row>0){
        previousMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row-1)];
        if(messages.count > (indexPath.row+1)){
            nextMessage = (ChatMessage *)[messages objectAtIndex:(indexPath.row+1)];
            numberDaysNextChat = (int)[ChatUtil daysBetweenDate:message.date andDate:nextMessage.date];
        }
        numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:previousMessage.date andDate:message.date];
        dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
    }else{
        numberDaysPrevChat = (int)[ChatUtil daysBetweenDate:message.date andDate:dateToday];
        dateChat = [self formatDateMessage:numberDaysPrevChat message:message row:indexPath.row];
    }
    if(numberDaysPrevChat>0){
        labelDay.text = dateChat;
    }else{
        labelDay.text = @"";
    }
    
    UIImageView *status_image_view = self.statusImageView;
    [ChatMessageCell setStatusImage:message statusImage:status_image_view];
}

@end
