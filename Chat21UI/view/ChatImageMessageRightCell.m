//
//  ChatImageMessageRightCell.m
//  chat21
//
//  Created by Andrea Sponziello on 21/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatImageMessageRightCell.h"
#import "ChatMessage.h"
#import "ChatUtil.h"
#import "ChatLocal.h"
#import "ChatMessageMetadata.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatImageUtil.h"

@implementation ChatImageMessageRightCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configure:(ChatMessage *)message messages:(NSArray *)messages indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController rowComponents:(NSMutableDictionary *)rowComponents imageCache:(ChatImageCache *)imageCache completion:(void(^)(UIImage *image)) callback {
    
    [super configure:message messages:messages indexPath:indexPath viewController:viewController rowComponents:rowComponents imageCache:imageCache completion:callback];
    
    UIImageView *status_image_view = self.statusImageView;
    [ChatMessageCell setStatusImage:message statusImage:status_image_view];
}

@end
