//
//  ChatChangeGroupNameVC.m
//  Chat21
//
//  Created by Andrea Sponziello on 28/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatChangeGroupNameVC.h"
#import "ChatGroup.h"
#import "ChatManager.h"
#import "ChatLocal.h"

@interface ChatChangeGroupNameVC ()

@end

@implementation ChatChangeGroupNameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"group %@", self.group);
    self.navigationItem.title = [ChatLocal translate:@"GroupNameTitle"];
    self.saveButton.title = [ChatLocal translate:@"ChatSave"];
    self.cancelButton.title = [ChatLocal translate:@"ChatCancel"];
    self.groupNameTextField.placeholder = [ChatLocal translate:@"GroupNamePlaceholder"];
    self.groupNameTextField.text = self.group.name;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self addControlChangeTextField:self.groupNameTextField];
    [self.groupNameTextField becomeFirstResponder];
}

-(void)addControlChangeTextField:(UITextField *)textField
{
    [textField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
}
//


-(void)textFieldDidChange:(UITextField *)textField {
    NSString *text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([text length] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
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
    [self performSegueWithIdentifier:@"unwindToGroupInfoVC" sender:self];
}

- (IBAction)saveAction:(id)sender {
    NSLog(@"saving...");
    NSString *text = [self.groupNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    ChatManager *chatm = [ChatManager getInstance];
    [chatm updateGroupName:text forGroup:self.group withCompletionBlock:^(NSError *error) {
        if (!error) {
            NSLog(@"Group name successfully changed.");
            [self performSegueWithIdentifier:@"unwindToGroupInfoVC" sender:self];
        } else {
            NSLog(@"Problems updating group name.");
        }
        
    }];
}

@end
