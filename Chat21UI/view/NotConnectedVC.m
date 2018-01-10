//
//  NotConnectedVC.m
//  Chat21
//
//  Created by Andrea Sponziello on 30/12/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import "NotConnectedVC.h"

@interface NotConnectedVC ()

@end

@implementation NotConnectedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)goToAuthentication {
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Authentication" bundle:nil];
//    CZAuthenticationVC *vc = (CZAuthenticationVC *)[sb instantiateViewControllerWithIdentifier:@"StartAuthentication"];
//    vc.applicationContext = self.applicationContext;
//    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;//UIModalTransitionStyleFlipHorizontal;
//    [self presentViewController:vc animated:YES completion:NULL];
}

- (IBAction)actionLogin:(id)sender {
    [self goToAuthentication];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
