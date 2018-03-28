//
//  ChatCreateGroupVC.m
//
//  Created by Andrea Sponziello on 25/03/16.
//

#import "ChatCreateGroupVC.h"
#import "ChatSelectGroupMembersLocal.h"
#import "ChatUtil.h"
#import "ChatLocal.h"

@implementation ChatCreateGroupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    [self photoMenu];
}

-(void)initUI {
    self.title = self.navigationItem.title = [ChatLocal translate:@"new group"];
    self.addPhotoLabelOverloaded.text = [ChatLocal translate:@"add photo placeholder"];
    self.messageLabel.text = [ChatLocal translate:@"create group info message"];
    self.groupNameTextField.placeholder = [ChatLocal translate:@"GroupNamePlaceholder"];
    self.nextButton.title = [ChatLocal translate:@"next"];
    self.cancelButton.title = [ChatLocal translate:@"cancel"];
    [self.groupNameTextField becomeFirstResponder];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self addControlChangeTextField:self.groupNameTextField];
    
    // group image
    UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    UITapGestureRecognizer *tapLabelView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    [self.groupImageView addGestureRecognizer:tapImageView];
    [self.addPhotoLabelOverloaded addGestureRecognizer:tapLabelView];
    self.addPhotoLabelOverloaded.userInteractionEnabled = YES;
    self.groupImageView.userInteractionEnabled = YES;
}

-(void)photoMenu {
    // init the photo action menu
    NSString *takePhotoButtonTitle = [ChatLocal translate:@"TakePhotoLKey"];
    NSString *chooseExistingButtonTitle = NSLocalizedString(@"PhotoFromGalleryLKey", nil);
    
    self.photoMenuSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CancelLKey", nil) destructiveButtonTitle:nil otherButtonTitles:takePhotoButtonTitle, chooseExistingButtonTitle, nil];
    self.photoMenuSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
}

-(void)photoMenuWithRemoveButton {
    // init the photo action menu
    NSString *removePhotoButtonTitle = NSLocalizedString(@"RemovePhotoLKey", nil);
    NSString *takePhotoButtonTitle = NSLocalizedString(@"TakePhotoLKey", nil);
    NSString *chooseExistingButtonTitle = NSLocalizedString(@"PhotoFromGalleryLKey", nil);
    
    self.photoMenuSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"CancelLKey", nil) destructiveButtonTitle:nil otherButtonTitles:removePhotoButtonTitle, takePhotoButtonTitle, chooseExistingButtonTitle, nil];
    self.photoMenuSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
}

- (void)tapImage:(UITapGestureRecognizer *)gesture {
//    UIImageView* imageView = (UIImageView*)gesture.view;
    NSLog(@"tapped");
    [self.view endEditing:YES];
    if (self.groupImageView.image) {
        [self photoMenuWithRemoveButton];
    } else {
        [self photoMenu];
    }
    [self.photoMenuSheet showInView:self.parentViewController.tabBarController.view];
}

- (IBAction)nextAction:(id)sender {
    [self performSegueWithIdentifier:@"AddMembers" sender:self];
}

- (IBAction)cancelAction:(id)sender {
    [self.view endEditing:YES];
//    [self.modalCallerDelegate setupViewController:self didCancelSetupWithInfo:nil];
    if (self.completionCallback) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.completionCallback(nil, YES);
        }];
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddMembers"]) {
        NSLog(@"AddMembers");
        [self uploadImage];
        ChatSelectGroupMembersLocal *vc = (ChatSelectGroupMembersLocal *)[segue destinationViewController];
        NSString *text = [self.groupNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        [self.applicationContext setVariable:@"groupName" withValue:text];
        vc.groupName = text;
        vc.completionCallback = self.completionCallback;
//        if (self.uploader) {
//            [self.applicationContext setVariable:@"groupIconID" withValue:self.uploader.imageID];
//        }
//        vc.applicationContext = self.applicationContext;
//        vc.modalCallerDelegate = self.modalCallerDelegate;
    }
}

-(void)uploadImage {
//    if (self.uploader) {
//        NSLog(@"Canceling previous image uploader...");
//        [self.uploader cancel];
//    }
//    if (!self.scaledImage) {
//        NSLog(@"No group image to upload. Eventually removing a previous uploaded image.");
//        ChatImageUploadSmart21DC *imageUpload = [[ChatImageUploadSmart21DC alloc] init];
//        imageUpload.removeMode = YES;
//        self.uploader = imageUpload;
//        imageUpload.imageID = (NSString *)[self.applicationContext getVariable:@"newGroupId"]; //[[NSUUID UUID] UUIDString];
//        imageUpload.uploadId = imageUpload.imageID;
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
//    } else {
//        NSLog(@"Uploading image...");
//        ChatImageUploadSmart21DC *imageUpload = [[ChatImageUploadSmart21DC alloc] init];
//        imageUpload.image = self.scaledImage;
//        self.uploader = imageUpload;
//        imageUpload.imageID = (NSString *)[self.applicationContext getVariable:@"newGroupId"]; //[[NSUUID UUID] UUIDString];
//        imageUpload.uploadId = imageUpload.imageID;
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
//    }
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

// **************************************************
// **************** TAKE PHOTO SECTION **************
// **************************************************

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([option isEqualToString:NSLocalizedString(@"TakePhotoLKey", nil)]) {
        NSLog(@"Take Photo");
        [self takePhoto];
    }
    else if ([option isEqualToString:NSLocalizedString(@"PhotoFromGalleryLKey", nil)]) {
        NSLog(@"Choose from Gallery");
        [self chooseExisting];
    }
    else if ([option isEqualToString:NSLocalizedString(@"RemovePhotoLKey", nil)]) {
        NSLog(@"Remove Photo");
        [self removePhoto];
    }
    
//    switch (buttonIndex) {
//        case 0:
//        {
//            [self takePhoto];
//            break;
//        }
//        case 1:
//        {
//            [self chooseExisting];
//            break;
//        }
//    }
}

- (void)takePhoto {
    if (self.imagePickerController == nil) {
        [self initializeCamera];
    }
    [self presentViewController:self.imagePickerController animated:YES completion:^{NSLog(@"FINITO!");}];
}

- (void)chooseExisting {
    NSLog(@"choose existing...");
    if (self.photoLibraryController == nil) {
        [self initializePhotoLibrary];
    }
    [self presentViewController:self.photoLibraryController animated:YES completion:nil];
}

-(void)removePhoto {
//    self.groupImageView.image = nil;
//    self.bigImage = nil;
//    self.scaledImage = nil;
//    if (self.uploader) {
//        [self.uploader cancel];
//        self.uploader = nil;
//    }
//    self.addPhotoLabelOverloaded.hidden = NO;
}

-(void)initializeCamera {
    NSLog(@"initializeCamera...");
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    // enable to crop
    self.imagePickerController.allowsEditing = YES;
}

-(void)initializePhotoLibrary {
    NSLog(@"initializePhotoLibrary...");
    self.photoLibraryController = [[UIImagePickerController alloc] init];
    self.photoLibraryController.delegate = self;
    self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;// SavedPhotosAlbum;// SavedPhotosAlbum;
    self.photoLibraryController.allowsEditing = YES;
    //self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self afterPickerCompletion:picker withInfo:info];
}

-(void)afterPickerCompletion:(UIImagePickerController *)picker withInfo:(NSDictionary *)info {
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        NSLog(@"(SHPTakePhotoViewController) Error saving image to camera roll.");
    }
    else {
        //NSLog(@"(SHPTakePhotoViewController) Image saved to camera roll. w:%f h:%f", self.image.size.width, self.image.size.height);
    }
}

// **************************************************
// *************** END PHOTO SECTION ****************
// **************************************************

@end
