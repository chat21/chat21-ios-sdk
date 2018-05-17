//
//  ChatTextMessageLeftCell.h
//  chat21
//
//  Created by Andrea Sponziello on 17/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatMessageCell.h"

@interface ChatTextMessageLeftCell : ChatMessageCell

@property (weak, nonatomic) IBOutlet UIView *messageBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents;

@end
