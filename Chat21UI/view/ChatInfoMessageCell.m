//
//  ChatInfoMessageCell.m
//  chat21
//
//  Created by Andrea Sponziello on 18/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatInfoMessageCell.h"
#import "ChatMessage.h"

@implementation ChatInfoMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configure:(ChatMessage *)message indexPath:(NSIndexPath *)indexPath rowComponents:(NSDictionary *)rowComponents {
    UIView *sfondo = self.backgroundView;//(UIView *)[cell viewWithTag:50];
    sfondo.layer.masksToBounds = YES;
    sfondo.layer.shadowOffset = CGSizeMake(-15, 20);
    sfondo.layer.shadowRadius = 5;
    sfondo.layer.shadowOpacity = 0.5;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    UILabel *labelMessage = self.messageLabel;//(UILabel *)[cell viewWithTag:10];
    [self attributedString:labelMessage text:message indexPath:indexPath rowComponents:rowComponents];
}

@end
