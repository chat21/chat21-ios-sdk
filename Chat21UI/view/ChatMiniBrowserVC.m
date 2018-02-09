//
//  ChatMiniBrowserVC.m
//  bppmobile
//
//  Created by Andrea Sponziello on 27/07/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatMiniBrowserVC.h"
//#import "ChatRootNC.h"
#import "ChatConversationsVC.h"

@interface ChatMiniBrowserVC ()

@end

@implementation ChatMiniBrowserVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"URL: %@", self.urlPage);
    
//    [self.tabBarController.tabBar setHidden:YES];
    self.webView.delegate=self;
    
//    NSDictionary *settingsDictionary = [self.applicationContext.plistDictionary objectForKey:@"Settings"];
    
    [self.toolBar setBarTintColor:colorBackground];
    /***********************************************************************************/
    //inizializzo un'activity indicator view
    refreshButtonItem = self.navigationItem.rightBarButtonItem;
    
//    bool statusBarStyle = [[settingsDictionary objectForKey:@"setStatusBarStyle"] boolValue];
//    if(statusBarStyle == YES){
//        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    }else{
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    }
    activityIndicator.frame = CGRectMake(0.0, 0.0, 20.0, 20.0);
    activityButtonItem = [[UIBarButtonItem alloc]initWithCustomView:activityIndicator];
    /***********************************************************************************/
    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [self initialize];
}

//-(void)viewWillDisappear:(BOOL)animated{
//    NSLog(@"viewWillDisappear");
//    [super viewWillDisappear:animated];
//    [self.tabBarController.tabBar setHidden:NO];
//}

- (void)initialize {
    NSLog(@"initialize %@", self.urlPage);
    self.urlPage = [self.urlPage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *url = [NSURL URLWithString:self.urlPage];
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:url];
    if (self.username && ![self.username isEqualToString:@""] && self.password && ![self.password isEqualToString:@""]) {
        NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)];
        [requestObj setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    [self.webView loadRequest:requestObj];
    if(self.titlePage){
        self.navigationItem.title = self.titlePage;
    }
//    [self.toolBar setHidden:self.hiddenToolBar];
}

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityIndicator startAnimating];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    [activityIndicator stopAnimating];
    //self.navigationItem.rightBarButtonItem = refreshButtonItem;
    self.navigationItem.rightBarButtonItem = self.forwardButton;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"error: %@",error);
    [activityIndicator stopAnimating];
    self.navigationItem.rightBarButtonItem = refreshButtonItem;
    UIAlertView *userAdviceAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NetworkErrorTitleLKey", nil) message:NSLocalizedString(@"NetworkErrorLKey", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [userAdviceAlert show];
    //[alertView release];
}


-(void)showActionSheet {
    NSString *urlString = @"";
    
    NSURL* url = [self.webView.request URL];
    urlString = [url absoluteString];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = urlString;
    actionSheet.delegate = self;
//    [actionSheet addButtonWithTitle:NSLocalizedString(@"Inoltra", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Copia URL", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
    
//    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
//        // Chrome is installed, add the option to open in chrome.
//        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Chrome", nil)];
//    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [actionSheet cancelButtonIndex]) return;
    NSURL *theURL = [self.webView.request URL];
    if (theURL == nil || [theURL isEqual:[NSURL URLWithString:@""]]) {
        //theURL = urlToLoad;
    }
    
//    if (buttonIndex == kChatSendButtonIndex) {
//        NSLog(@"chat send");
//        [self performSegueWithIdentifier:@"selectUserSegue" sender:self];
//    }
    if (buttonIndex == kCopyURLButtonIndex) {
        NSString *urlString = @"";
        NSURL* url = [self.webView.request URL];
        urlString = [url absoluteString];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = urlString;
    }
    else if (buttonIndex == kSafariButtonIndex) {
        [[UIApplication sharedApplication] openURL:theURL];
    }
    else if (buttonIndex == kChromeButtonIndex) {
        NSString *scheme = theURL.scheme;
        
        // Replace the URL Scheme with the Chrome equivalent.
        NSString *chromeScheme = nil;
        if ([scheme isEqualToString:@"http"]) {
            chromeScheme = @"googlechrome";
        } else if ([scheme isEqualToString:@"https"]) {
            chromeScheme = @"googlechromes";
        }
        
        // Proceed only if a valid Google Chrome URI Scheme is available.
        if (chromeScheme) {
            NSString *absoluteString = [theURL absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
            NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
            
            // Open the URL with Chrome.
            [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"selectUserSegue"]) {
//        UINavigationController *navigationController = [segue destinationViewController];
//        SHPSelectUserVC *vc = (SHPSelectUserVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.applicationContext = self.applicationContext;
//        vc.modalCallerDelegate = self;
//    }
}

- (void)setupViewController:(UIViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo {
    NSLog(@"setupViewController...");
}

- (void)setupViewController:(UIViewController *)controller didCancelSetupWithInfo:(NSDictionary *)setupInfo {
    NSLog(@"didCancelSetupWithInfo...");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)actionCloseView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)forwardLink:(id)sender {
    [self showActionSheet];
}

- (IBAction)reloadPage:(id)sender {
    [self.webView reload];
    //[self initialize];
}

- (IBAction)nextPage:(id)sender {
}

- (IBAction)backPage:(id)sender {
    [self.webView goBack];
}

@end
