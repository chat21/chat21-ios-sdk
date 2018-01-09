//
//  GroupInfoVC.m
//  Smart21
//
//  Created by Andrea Sponziello on 04/05/15.
//
//

#import "GroupInfoVC.h"
#import "ChatDB.h"
#import "ChatGroup.h"
#import "GroupMembersVC.h"
#import "ChatManager.h"
#import "ChatUtil.h"
#import "ChatUploadsController.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatChangeGroupNameVC.h"
#import "ChatUser.h"

@interface GroupInfoVC ()

@end

@implementation GroupInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = NSLocalizedString(@"group info", nil);
    
    //    ChatDB *db = [ChatDB getSharedInstance];
    //    self.group = [db getGroupById:self.groupId];
    
    self.group = [[ChatManager getInstance] groupById:self.groupId];
    
    // group image
    UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    UITapGestureRecognizer *tapLabelView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    [self.groupImageView addGestureRecognizer:tapImageView];
    [self.addPhotoLabelOverloaded addGestureRecognizer:tapLabelView];
    //    self.addPhotoLabelOverloaded.userInteractionEnabled = YES;
    self.addPhotoLabelOverloaded.hidden = YES;
    self.groupImageView.userInteractionEnabled = YES;
    [self initImageCache];
    [self setupImage];
    [self photoMenu];
}

-(void)initImageCache {
    //    // cache setup
    //    self.imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
    //    if (!self.imageCache) {
    //        self.imageCache = [[ChatImageCache alloc] init];
    //        self.imageCache.cacheName = @"chatUserIcons";
    //        // test
    //        // [self.imageCache listAllImagesFromDisk];
    //        // [self.imageCache empty];
    //        [self.applicationContext setVariable:@"chatUserIcons" withValue:self.imageCache];
    //    }
}

-(void)setupImage {
    //    [ChatUtil groupImageUrlById:self.group.groupId]
    // CONVERSATION IMAGE
    
    NSString *imageURL = self.group.iconUrl;
    ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
    UIImage *image = cached_image_wrap.image;
    if(!image) {
        NSLog(@"IMAGE %@ NOT CACHED. DOWNLOADING...", imageURL);
        //        [self downloadImage:imageURL];
        UIImage *circled = [ChatUtil circleImage:[UIImage imageNamed:@"group-conversation-avatar"]];
        self.groupImageView.image = circled;
    } else {
        NSLog(@"IMAGE CACHED %@", imageURL);
        self.addPhotoLabelOverloaded.hidden = YES;
        self.groupImageView.image = [ChatUtil circleImage:image];
        // update too old images
        double now = [[NSDate alloc] init].timeIntervalSince1970;
        double reload_timer_secs = 86400; // one day
        if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
            //            [self downloadImage:imageURL];
        }
    }
}

//-(void)downloadImage:(NSString *)imageURL {
//    SHPImageRequest *imageRquest = [[SHPImageRequest alloc] init];
//    __weak GroupInfoVC *weakSelf = self;
//    [imageRquest downloadImage:imageURL
//             completionHandler:
//     ^(UIImage *image, NSString *imageURL, NSError *error) {
//         if (image) {
//             [weakSelf updateImage:image];
//         } else {
//             // optionally put an image that indicates an error
//         }
//     }];
//}

-(void)updateImage:(UIImage *)image {
    [self.imageCache addImage:image withKey:self.group.iconUrl];
    self.groupImageView.image = [ChatUtil circleImage:image];
    self.addPhotoLabelOverloaded.hidden = YES;
}

-(void)photoMenu {
    // init the photo action menu
    NSString *takePhotoButtonTitle = NSLocalizedString(@"TakePhotoLKey", nil);
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
    ChatManager *chat = [ChatManager getInstance];
    if (![chat.loggedUser.userId isEqualToString:self.group.owner]) {
        return;
    }
    
    [self.view endEditing:YES];
    UIImage *groupImage = [self.imageCache getImage:self.group.iconUrl].image;
    NSLog(@"IMAGE ON! %@ for URL %@", groupImage, self.group.iconUrl);
    if (groupImage) {
        [self photoMenuWithRemoveButton];
    } else {
        [self photoMenu];
    }
    [self.photoMenuSheet showInView:self.parentViewController.tabBarController.view];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"reloading data group members: %@", self.group.members);
    [self setupUI];
}

-(void)setupUI {
    self.groupNameLabel.text = self.group.name;
    NSLog(@"self.groupNameLabel %@ self.group.name %@", self.groupNameLabel, self.group.name);
    self.membersLabel.text = [ChatUtil groupMembersAsStringForUI:self.group.members];
    
    //NSString *created_by_msg = @"Gruppo creato da";
    //    self.createdByLabel.text = [[NSString alloc] initWithFormat:@"%@ %@.",created_by_msg, self.group.owner];
    self.createdByLabel.text = [NSString stringWithFormat:NSLocalizedString(@"group created by", nil), self.group.owner];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd LLLL yyyy"];
    NSString *createdOn_s = [formatter stringFromDate:self.group.createdOn];
    //    NSString *created_on_msg = @"Creato il";
    //    self.createdOnLabel.text = [[NSString alloc] initWithFormat:@"%@ %@.", created_on_msg, createdOn_s];
    self.createdOnLabel.text = [NSString stringWithFormat:NSLocalizedString(@"group created on", nil), createdOn_s];
    
    self.adminLabel.text = self.group.owner;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
//
//    // Configure the cell...
//
//    return cell;
//}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger index = indexPath.row;
    if (index == 0) {
        NSLog(@"cambio nome");
        ChatManager *chat = [ChatManager getInstance];
        if ([chat.loggedUser.userId isEqualToString:self.group.owner]) {
            [self performSegueWithIdentifier:@"ChangeGroupName" sender:self];
        }
    }
    if (index == 1) {
        [self performSegueWithIdentifier:@"GroupMembers" sender:self];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"GroupMembers"]) {
        GroupMembersVC *vc = (GroupMembersVC *)[segue destinationViewController];
        vc.group = self.group;
    }
    else if ([[segue identifier] isEqualToString:@"ChangeGroupName"]) {
        NSLog(@"preparing segue to modal");
        UINavigationController *nc = (UINavigationController *)[segue destinationViewController];
        NSLog(@"nc %@", nc);
        ChatChangeGroupNameVC *vc = (ChatChangeGroupNameVC *)nc.viewControllers[0];
        NSLog(@"vc %@", vc);
        vc.group = self.group;
    }
}

//-(void)uploadImage {
//    if (self.uploader) {
//        NSLog(@"Canceling previous image uploader...");
//        [self.uploader cancel];
//        self.uploader = nil;
//    }
//    if (!self.scaledImage) {
//        NSLog(@"No group image to upload. Eventually removing a previous uploaded image.");
//        ChatImageUploadDC *imageUpload = [[ChatImageUploadDC alloc] init];
//        imageUpload.removeMode = YES;
//        self.uploader = imageUpload;
//        imageUpload.imageID = self.group.groupId;
//        imageUpload.uploadId = imageUpload.imageID;
//        NSLog(@"IMAGE UPLOAD %@", imageUpload);
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
//    } else {
//        NSLog(@"Uploading image...");
//        ChatImageUploadDC *imageUpload = [[ChatImageUploadDC alloc] init];
//        imageUpload.image = self.scaledImage;
//        self.uploader = imageUpload;
//        imageUpload.imageID = self.group.groupId;
//        imageUpload.uploadId = imageUpload.imageID;
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
////        ChatImageCache *imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
////        if (imageCache) {
////            [imageCache addImage:self.scaledImage withKey:[ChatUtil groupImageUrlById:self.group.groupId]];
////        }
//    }
//}

//-(void)uploadImage {
//    if (self.uploader) {
//        NSLog(@"Canceling previous image uploader...");
//        [self.uploader cancel];
//        self.uploader = nil;
//    }
//    if (!self.scaledImage) {
//        NSLog(@"No group image to upload. Eventually removing a previous uploaded image.");
//        ChatImageUploadSmart21DC *imageUpload = [[ChatImageUploadSmart21DC alloc] init];
//        imageUpload.removeMode = YES;
//        self.uploader = imageUpload;
//        imageUpload.imageID = self.group.groupId;
//        imageUpload.uploadId = imageUpload.imageID;
//        NSLog(@"IMAGE UPLOAD %@", imageUpload);
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
//    } else {
//        NSLog(@"Uploading image...");
//        ChatImageUploadSmart21DC *imageUpload = [[ChatImageUploadSmart21DC alloc] init];
//        imageUpload.image = self.scaledImage;
//        self.uploader = imageUpload;
//        imageUpload.imageID = self.group.groupId;
//        imageUpload.uploadId = imageUpload.imageID;
//        ChatUploadsController *uploads = [ChatUploadsController getSharedInstance];
//        [uploads addDataController:imageUpload];
//        [imageUpload start];
//        //        ChatImageCache *imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
//        //        if (imageCache) {
//        //            [imageCache addImage:self.scaledImage withKey:[ChatUtil groupImageUrlById:self.group.groupId]];
//        //        }
//    }
//}
//
//// **************************************************
//// **************** TAKE PHOTO SECTION **************
//// **************************************************
//
//-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//
//    NSString *option = [actionSheet buttonTitleAtIndex:buttonIndex];
//    if ([option isEqualToString:NSLocalizedString(@"TakePhotoLKey", nil)]) {
//        NSLog(@"Take Photo");
//        [self takePhoto];
//    }
//    else if ([option isEqualToString:NSLocalizedString(@"PhotoFromGalleryLKey", nil)]) {
//        NSLog(@"Choose from Gallery");
//        [self chooseExisting];
//    }
//    else if ([option isEqualToString:NSLocalizedString(@"RemovePhotoLKey", nil)]) {
//        NSLog(@"Remove Photo");
//        [self removePhoto];
//    }
//
//    //    switch (buttonIndex) {
//    //        case 0:
//    //        {
//    //            [self takePhoto];
//    //            break;
//    //        }
//    //        case 1:
//    //        {
//    //            [self chooseExisting];
//    //            break;
//    //        }
//    //    }
//}
//
//- (void)takePhoto {
//    NSLog(@"taking photo with user %@...", self.applicationContext.loggedUser);
//    if (self.imagePickerController == nil) {
//        [self initializeCamera];
//    }
//    [self presentViewController:self.imagePickerController animated:YES completion:^{NSLog(@"FINITO!");}];
//}
//
//- (void)chooseExisting {
//    NSLog(@"choose existing...");
//    if (self.photoLibraryController == nil) {
//        [self initializePhotoLibrary];
//    }
//    [self presentViewController:self.photoLibraryController animated:YES completion:nil];
//}
//
//-(void)removePhoto {
//
////    self.groupImageView.image = nil;
////    self.addPhotoLabelOverloaded.hidden = NO;
//    UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"group-conversation-avatar"]];
//    self.groupImageView.image = circled;
//
//    self.bigImage = nil;
//    self.scaledImage = nil;
//    if (self.uploader) {
//        [self.uploader cancel];
//        self.uploader = nil;
//    }
//    [self.imageCache deleteImage:self.group.iconUrl];
//    NSLog(@"VERIFY! IMAGE ON! %@ for URL %@", [self.imageCache getImage:self.group.iconUrl].image, self.group.iconUrl);
//    [self uploadImage];
//}
//
//-(void)initializeCamera {
//    NSLog(@"initializeCamera...");
//    self.imagePickerController = [[UIImagePickerController alloc] init];
//    self.imagePickerController.delegate = self;
//    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
//    // enable to crop
//    self.imagePickerController.allowsEditing = YES;
//}
//
//-(void)initializePhotoLibrary {
//    NSLog(@"initializePhotoLibrary...");
//    self.photoLibraryController = [[UIImagePickerController alloc] init];
//    self.photoLibraryController.delegate = self;
//    self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;// SavedPhotosAlbum;// SavedPhotosAlbum;
//    self.photoLibraryController.allowsEditing = YES;
//    //self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//}
//
//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    [picker dismissViewControllerAnimated:YES completion:nil];
//    [self afterPickerCompletion:picker withInfo:info];
//}
//
//-(void)afterPickerCompletion:(UIImagePickerController *)picker withInfo:(NSDictionary *)info {
//    self.bigImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
//    NSLog(@"BIG IMAGE: %@", self.bigImage);
//    // enable to crop
//    // self.scaledImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
//    NSLog(@"edited image w:%f h:%f", self.bigImage.size.width, self.bigImage.size.height);
//    if (!self.bigImage) {
//        self.bigImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
//        NSLog(@"original image w:%f h:%f", self.bigImage.size.width, self.bigImage.size.height);
//    }
//    // end
//
//    self.scaledImage = [SHPImageUtil scaleImage:self.bigImage toSize:CGSizeMake(self.applicationContext.settings.uploadImageSize, self.applicationContext.settings.uploadImageSize)];
//    NSLog(@"SCALED IMAGE w:%f h:%f", self.scaledImage.size.width, self.scaledImage.size.height);
//
//    // save image in photos
////    if (picker == self.imagePickerController) {
////        UIImageWriteToSavedPhotosAlbum(self.bigImage, self,
////                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
////    }
//
//    NSLog(@"image: %@", self.scaledImage);
//    UIImage *imageEXIFAdjusted = [SHPImageUtil adjustEXIF:self.scaledImage];
//    NSData *imageData = UIImageJPEGRepresentation(imageEXIFAdjusted, 90);
//
//    [self updateImage:self.scaledImage];
//    //self.groupImageView.image = self.scaledImage; //[SHPImageUtil circleImage:self.scaledImage];
//    //    [self.addPhotoLabelOverloaded removeFromSuperview];
//    //self.addPhotoLabelOverloaded.hidden = YES;
//    //    self.addPhotoLabelOverloaded.userInteractionEnabled = NO;
//    [self uploadImage];
//}
//
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//{
//    if (error != NULL) {
//        NSLog(@"(SHPTakePhotoViewController) Error saving image to camera roll.");
//    }
//    else {
//        //NSLog(@"(SHPTakePhotoViewController) Image saved to camera roll. w:%f h:%f", self.image.size.width, self.image.size.height);
//    }
//}

// **************************************************
// *************** END PHOTO SECTION ****************
// **************************************************

- (IBAction)unwindToGroupInfoVC:(UIStoryboardSegue *)sender {
    NSLog(@"unwindToGroupInfoVC");
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dealloc {
    NSLog(@"Deallocating GroupInfoVC.");
}

@end

