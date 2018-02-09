//
//  SHPChatCreateGroupVC.h
//  Smart21
//
//  Created by Andrea Sponziello on 25/03/15.
//
//

#import <UIKit/UIKit.h>
@class ChatGroup;

@interface ChatCreateGroupVC : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *groupImageView;
@property (weak, nonatomic) IBOutlet UILabel *addPhotoLabelOverloaded;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (nonatomic, copy) void (^completionCallback)(ChatGroup *group, BOOL canceled);

// imagepicker
@property (strong, nonatomic) UIActionSheet *photoMenuSheet;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImagePickerController *photoLibraryController;
@property (nonatomic, strong) UIImage *scaledImage;
//@property (nonatomic, strong) ChatImageUploadSmart21DC *uploader;
@property (strong, nonatomic) UIImage *bigImage;

- (IBAction)nextAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
