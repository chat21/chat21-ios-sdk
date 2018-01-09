//
//  NotificationAlertView.m
//  Chat21
//
//  Created by Andrea Sponziello on 16/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "NotificationAlertView.h"
#import "ChatConversationsVC.h"
#import "ChatManager.h"

@interface NotificationAlertView () {
    SystemSoundID soundID;
}
@end

@implementation NotificationAlertView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)initViewWithHeight:(float)height {
    NSLog(@"NotificationAlertVC loaded.");
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:singleFingerTap];
    
    float alert_height = height;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    float alert_width = window.frame.size.width;
    UIWindow *notificationAlertWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, -alert_height, alert_width, alert_height)];
    self.frame = CGRectMake(0, 0, alert_width, alert_height);
    self.myWindow = notificationAlertWindow;
    [notificationAlertWindow addSubview:self];
    notificationAlertWindow.windowLevel = UIWindowLevelStatusBar + 1;
    
//    self.mainWindow = [[[UIApplication sharedApplication] delegate] window];
    // adjusting close button position on the right side of the view
//    self.closeButton.translatesAutoresizingMaskIntoConstraints = YES;
//    CGRect rect = self.closeButton.frame;
//    float view_width = self.view.frame.size.width;
//    float close_button_width = self.closeButton.frame.size.width;
//    float close_button_x = view_width - close_button_width;
//    CGRect close_rect = CGRectMake(close_button_x, rect.origin.y, rect.size.width, rect.size.height);
//    [self.closeButton setFrame:close_rect];
}

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    //    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    NSLog(@"View tapped!! Moving to conversation tab.");
    [self animateClose];
    int chat_tab_index = [ChatManager getInstance].tabBarIndex; // tabIndexByName:@"ChatController"];
    // move to the converstations tab
//    if (chat_tab_index >= 0) {
//        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
//        UITabBarController *tabController = (UITabBarController *)window.rootViewController;
//        NSArray *controllers = [tabController viewControllers];
//        ChatRootNC *nc = [controllers objectAtIndex:chat_tab_index];
//        ChatConversationsVC *vc = nc.viewControllers[0];
//        if (vc.presentedViewController) {
//            NSLog(@"THERE IS A MODAL PRESENTED! NOT SWITCHING TO ANY CONVERSATION VIEW.");
//        } else {
//            NSLog(@"SWITCHING TO CONVERSATION VIEW. DISABLED.");
//            // IF YOU ENABLE THIS IS MANDATORY TO FIND A WAY TO DISMISS OR HANDLE THE CURRENT MODAL VIEW
//            //            [nc popToRootViewControllerAnimated:NO];
//            //            [vc openConversationWithRecipient:self.sender];
//            //            tabController.selectedIndex = chat_tab_index;
//        }
//    }
}

static float animationDurationShow = 0.5;
static float animationDurationClose = 0.3;
static float showTime = 4.0;

-(void)animateShow {
//    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
//    [window setWindowLevel:UIWindowLevelStatusBar+1];
    
    //    CGRect rect = self.closeButton.frame;
    //    NSLog(@"....close x:%f y:%f w:%f h:%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    //    CGRect rectimg = self.userImage.frame;
    //    NSLog(@"....image x:%f y:%f w:%f h:%f", rectimg.origin.x, rectimg.origin.y, rectimg.size.width, rectimg.size.height);
    //    float view_width = self.view.frame.size.width;
    //    float close_button_width = self.closeButton.frame.size.width;
    //    NSLog(@"....view_width: %f", view_width);
    //    NSLog(@"....close_button_width: %f", close_button_width);
    
    
    
    [self playSound];
    self.animating = YES;
    
    UIWindow *w = (UIWindow *)self.superview;
//    [w makeKeyAndVisible];
    w.hidden = NO;
    
    [UIView animateWithDuration:animationDurationShow
                          delay:0
                        options: (UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         //self.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
                         w.frame = CGRectMake(0, 0, w.frame.size.width, w.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         self.animating = NO;
                         self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:showTime target:self selector:@selector(animateClose) userInfo:nil repeats:NO];
                     }
     ];
}

-(void)animateClose {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.animating = YES;
    
    UIWindow *w = (UIWindow *)self.superview;
    
    [UIView animateWithDuration:animationDurationClose
                          delay:0
                        options: (UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         w.frame = CGRectMake(0, -w.frame.size.height, w.frame.size.width, w.frame.size.height);
                     } completion:^(BOOL finished) {
                         self.animating = NO;
//                         [self.mainWindow makeKeyWindow];
                     }
     ];
}

- (IBAction)closeAction:(id)sender {
    NSLog(@"Closing alert");
    [self animateClose];
}

-(void)playSound {
    // convert mp3 > caf
    // afconvert -f caff -d LEI16@44100 -c 1 sounds-1065-just-like-that.mp3 newnotif2.caf
    // on completion play a sound
    // help: https://github.com/TUNER88/iOSSystemSoundsLibrary
    // help: http://developer.boxcar.io/blog/2014-10-08-notification_sounds/
    //    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/Modern/sms_alert_bamboo.caf"];
    // Construct URL to sound file
    NSString *path = [NSString stringWithFormat:@"%@/newnotif.caf", [[NSBundle mainBundle] resourcePath]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    //    NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: ofType:];
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL,&soundID);
    AudioServicesPlaySystemSound(soundID);
}

@end
