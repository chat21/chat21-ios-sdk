//
//  ChatMessageCell.h
//  Chat21
//
//  Created by Andrea Sponziello on 08/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *rightMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftMessageLabel;

@end
