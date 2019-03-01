//
//  ChatGroupConversationCell.h
//  chat21
//
//  Created by Andrea Sponziello on 01/03/2019.
//  Copyright © 2019 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatBaseConversationCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatGroupConversationCell : ChatBaseConversationCell

@property (weak, nonatomic) IBOutlet UILabel *infoMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;

@end

NS_ASSUME_NONNULL_END
