//
//  ChatShowImage.m
//  chat21
//
//  Created by Andrea Sponziello on 01/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatShowImage.h"

@interface ChatShowImage ()

@end

@implementation ChatShowImage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = self.image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
