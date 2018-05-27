//
//  ChatMiniBrowserVC.h
//
//  Created by Andrea Sponziello on 27/07/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatModalCallerDelegate.h"

@interface ChatMiniBrowserVC : UIViewController<UIWebViewDelegate, UIActionSheetDelegate, ChatModalCallerDelegate>
{
    UIBarButtonItem *refreshButtonItem;
    UIActivityIndicatorView *activityIndicator;
    UIBarButtonItem *activityButtonItem;
    UIColor *tintColor;
    UIColor *colorBackground;
    
    enum actionSheetButtonIndex {
//        kChatSendButtonIndex,
        kCopyURLButtonIndex,
        kSafariButtonIndex,
        kChromeButtonIndex,
    };
}

@property (nonatomic, strong) NSString *urlPage;
@property (nonatomic, strong) NSString *titlePage;

@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (assign, nonatomic) BOOL hiddenToolBar;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

- (IBAction)actionCloseView:(id)sender;
- (IBAction)forwardLink:(id)sender;
- (IBAction)reloadPage:(id)sender;
- (IBAction)nextPage:(id)sender;
- (IBAction)backPage:(id)sender;
@end
