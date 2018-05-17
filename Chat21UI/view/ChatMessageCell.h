//
//  ChatMessageCell.h
//  Chat21
//
//  Created by Andrea Sponziello on 08/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ChatMessage;

@interface ChatMessageCell : UITableViewCell

-(void)attributedString:(UILabel *)label text:(ChatMessage *)message indexPath:(NSIndexPath *)indexPath rowComponents:(NSDictionary *)rowComponents;
-(NSString *)displayUserOfMessage:(ChatMessage *)m;
-(NSString*)formatDateMessage:(int)numberDaysBetweenChats message:(ChatMessage*)message row:(CGFloat)row;
+(void)setStatusImage:(ChatMessage *)message statusImage:(UIImageView *)status_image_view;
+(CGSize)computeImageSize:(ChatMessage *)message;

@end
