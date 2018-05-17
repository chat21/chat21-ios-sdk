//
//  ChatImagePreviewVC.h
//  chat21
//
//  Created by Andrea Sponziello on 16/05/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatImagePreviewVC : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString* recipientFullname;

@property (weak, nonatomic) IBOutlet UILabel *recipientFullnameLabel;

@end
