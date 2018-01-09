//
//  NotificationAlertView.h
//  Chat21
//
//  Created by Andrea Sponziello on 16/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface NotificationAlertView : UIView

-(void)initViewWithHeight:(float)height;

@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
- (IBAction)closeAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (strong, nonatomic) NSTimer *animationTimer;
@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) SystemSoundID sound;

@property (strong, nonatomic) UIWindow *myWindow;

@property (strong, nonatomic) NSString *sender;

-(void)animateShow;
-(void)animateClose;

@end
