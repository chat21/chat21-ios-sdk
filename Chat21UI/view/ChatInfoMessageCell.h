//
//  ChatInfoMessageCell.h
//  chat21
//
//  Created by Andrea Sponziello on 18/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatMessageCell.h"

@interface ChatInfoMessageCell : ChatMessageCell

@property (weak, nonatomic) IBOutlet UIView *messageBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

-(void)configure:(ChatMessage *)message indexPath:(NSIndexPath *)indexPath rowComponents:(NSDictionary *)rowComponents;

@end
