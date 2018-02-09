//
//  ChatChangeGroupNameVC.h
//  Chat21
//
//  Created by Andrea Sponziello on 28/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatGroup;

@interface ChatChangeGroupNameVC : UIViewController

@property (strong, nonatomic) ChatGroup *group;

@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
