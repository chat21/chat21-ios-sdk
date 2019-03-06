//
//  ChatBaseConversationCell.h
//  chat21
//
//  Created by Andrea Sponziello on 01/03/2019.
//  Copyright © 2019 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatBaseConversationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *is_newMessageIcon;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *archivedImageView;

@end

NS_ASSUME_NONNULL_END
