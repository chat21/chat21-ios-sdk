//
//  ChatImageMessageRightCell.h
//  chat21
//
//  Created by Andrea Sponziello on 21/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

//#import <UIKit/UIKit.h>
//#import "ChatMessageCell.h"
#import "ChatImageMessageCell.h"
@class ChatImageCache;

@interface ChatImageMessageRightCell : ChatImageMessageCell

//@property (weak, nonatomic) IBOutlet UIView *messageBackgroundView;
//@property (weak, nonatomic) IBOutlet UIImageView *messageImageView;
//@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
//@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
//@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
//@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents imageCache:(ChatImageCache *)imageCache completion:(void(^)(UIImage *image))callback;

@end
