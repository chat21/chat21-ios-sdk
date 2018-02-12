// DEPRECATED

//  NotificationAlertVC.h
//  Chat21
//
//  Created by Andrea Sponziello on 22/12/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface NotificationAlertVC : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
- (IBAction)closeAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (strong, nonatomic) NSTimer *animationTimer;
@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) SystemSoundID sound;

@property (strong, nonatomic) NSString *sender;

-(void)animateShow;
-(void)animateClose;

@end
