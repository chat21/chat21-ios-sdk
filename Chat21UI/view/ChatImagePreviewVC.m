//
//  ChatImagePreviewVC.m
//  chat21
//
//  Created by Andrea Sponziello on 16/05/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatImagePreviewVC.h"

@interface ChatImagePreviewVC ()

@end

@implementation ChatImagePreviewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = self.image;
    self.recipientFullnameLabel.text = [[NSString alloc] initWithFormat:@"> %@", self.recipientFullname];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelAction:(id)sender {
    self.image = nil;
    [self performSegueWithIdentifier:@"unwindToMessagesVCsegue" sender:self];
}

@end
