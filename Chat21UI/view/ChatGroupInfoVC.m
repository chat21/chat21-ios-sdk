//
//  ChatGroupInfoVC.m
//  Smart21
//
//  Created by Andrea Sponziello on 04/05/15.
//
//

#import "ChatGroupInfoVC.h"
#import "ChatDB.h"
#import "ChatGroup.h"
#import "ChatGroupMembersVC.h"
#import "ChatManager.h"
#import "ChatUtil.h"
#import "ChatUploadsController.h"
#import "ChatDiskImageCache.h"
//#import "ChatImageWrapper.h"
#import "ChatChangeGroupNameVC.h"
#import "ChatUser.h"
#import "ChatLocal.h"
#import "ChatImageUtil.h"
#import "ChatShowImage.h"
#import "SVProgressHUD.h"

@interface ChatGroupInfoVC ()

@end

@implementation ChatGroupInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = [ChatLocal translate:@"group info"];
    
    //    ChatDB *db = [ChatDB getSharedInstance];
    //    self.group = [db getGroupById:self.groupId];
    
//    self.group = [[ChatManager getInstance] groupById:self.groupId];
    
    // group image
//    UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
//    UITapGestureRecognizer *tapLabelView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    
    
    UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProfilePhoto:)];
//    UITapGestureRecognizer *tapLabelView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProfilePhoto:)];
    [self.profilePhotoImageView addGestureRecognizer:tapImageView];
//    [self.addPhotoLabelOverloaded addGestureRecognizer:tapLabelView];
//    self.addPhotoLabelOverloaded.userInteractionEnabled = YES;
    self.profilePhotoImageView.userInteractionEnabled = YES;
    self.profileId = self.group.groupId;
    
    self.imageCache = [ChatManager getInstance].imageCache;
    [self setupProfileImage:self.group.groupId];
}

-(void)setupProfileImage:(NSString *)profileId {
    self.imageCache = [ChatManager getInstance].imageCache;
    
    // setup circle image view
    self.profilePhotoImageView.layer.cornerRadius = self.profilePhotoImageView.frame.size.width / 2;
    self.profilePhotoImageView.clipsToBounds = YES;
    
    // try to get image from cache
    NSString *imageURL = [ChatManager profileImageURLOf:profileId];
    NSURL *url = [NSURL URLWithString:imageURL];
    NSString *cache_key = [self.imageCache urlAsKey:url];
    UIImage *cachedProfileImage = [self.imageCache getCachedImage:cache_key];
    [self setupCurrentProfileViewWithImage:cachedProfileImage];
    [self.imageCache getImage:imageURL completionHandler:^(NSString *imageURL, UIImage *image) {
        [self setupCurrentProfileViewWithImage:image];
    }];
}

-(void)setupCurrentProfileViewWithImage:(UIImage *)image {
    self.currentProfilePhoto = image;
    if (image == nil) {
        [self resetProfilePhoto];
    }
    else {
        self.profilePhotoImageView.image = image;
//        self.addPhotoLabelOverloaded.hidden = YES;
    }
}

-(void)resetProfilePhoto {
    self.profilePhotoImageView.image = [UIImage imageNamed:@"group-conversation-avatar"];
//    self.addPhotoLabelOverloaded.hidden = NO;
}

//-(BOOL)imGroupAdmin {
//    ChatManager *chatm = [ChatManager getInstance];
//    return [chatm.loggedUser.userId isEqualToString:self.group.owner] ? YES : NO;
//}

-(void)tapProfilePhoto:(UITapGestureRecognizer *)gestureRecognizer {
    
    if (self.currentProfilePhoto == nil && !self.group.imAdmin) {
        // no photo and no admin: no menu makes sense. there is nothing you can do
        return;
    }
    else if (self.currentProfilePhoto && !self.group.imAdmin) {
        // photo ok but not admin. on tap you see the group's photo.
        [self showPhoto];
        return;
    }
    
    // else you are an admin. ok for menu
    
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:nil
                                   message:NSLocalizedString(@"Change Profile Photo", nil)
                                   preferredStyle:UIAlertControllerStyleActionSheet];
//    UIAlertAction* delete = [UIAlertAction
//                             actionWithTitle:NSLocalizedString(@"Remove Current Photo", nil)
//                             style:UIAlertActionStyleDestructive
//                             handler:^(UIAlertAction * action)
//                             {
//                                 [self deleteImage];
//                             }];
    
    UIAlertAction* show = [UIAlertAction
                           actionWithTitle:NSLocalizedString(@"Show Photo", nil)
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
                               NSLog(@"Show photo");
                               [self showPhoto];
                           }];
    
    UIAlertAction* photo = [UIAlertAction
                            actionWithTitle:NSLocalizedString(@"Photo", nil)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                NSLog(@"Open photo");
                                [self takePhoto];
                            }];
    UIAlertAction* photo_from_library = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Photo from library", nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             NSLog(@"Open photo");
                                             [self chooseExisting];
                                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel", nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 NSLog(@"cancel");
                             }];
    if (self.currentProfilePhoto != nil) {
//        [alert addAction:delete];
        [alert addAction:show];
    }
    NSLog(@"groupsowner %@", self.group.owner);
    if (self.group.imAdmin) {
        [alert addAction:photo];
        [alert addAction:photo_from_library];
    }
    [alert addAction:cancel];
    UIPopoverPresentationController *popPresenter = [alert
                                                     popoverPresentationController];
    UIView *view = gestureRecognizer.view;
    popPresenter.sourceView = view;
    popPresenter.sourceRect = view.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showPhoto {
    [self performSegueWithIdentifier:@"imagePreview" sender:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"reloading data group members: %@", self.group.members);
    [self setupUI];
}

-(void)setupUI {
    ChatGroup *group = self.group;
    self.groupNameLabel.text = group.name;
    if (group.membersFull) {
        self.membersLabel.text = [ChatUtil groupMembersFullnamesAsStringForUI:group.membersFull];
    }
    else {
        self.membersLabel.text = [ChatUtil groupMembersAsStringForUI:group.members];
    }
    self.idLabel.text = [[NSString alloc] initWithFormat:@"Id: %@", group.groupId];
    self.createdByLabel.text = [NSString stringWithFormat:[ChatLocal translate:@"group created by"], [group ownerFullname]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd LLLL yyyy"];
    NSString *createdOn_s = [formatter stringFromDate:self.group.createdOn];
    //    NSString *created_on_msg = @"Creato il";
    //    self.createdOnLabel.text = [[NSString alloc] initWithFormat:@"%@ %@.", created_on_msg, createdOn_s];
    self.createdOnLabel.text = [NSString stringWithFormat:[ChatLocal translate:@"group created on"], createdOn_s];
    
    self.adminLabel.text = [group ownerFullname];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

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
        ChatGroupMembersVC *vc = (ChatGroupMembersVC *)[segue destinationViewController];
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
    else if ([[segue identifier] isEqualToString:@"imagePreview"]) {
        ChatShowImage *vc = (ChatShowImage *)[segue destinationViewController];
        NSLog(@"vc %@", vc);
        vc.image = self.currentProfilePhoto;
    }
}

// **************************************************
// **************** TAKE PHOTO SECTION **************
// **************************************************

- (void)takePhoto {
    //    NSLog(@"taking photo with user %@...", self.applicationContext.loggedUser);
    if (self.imagePickerController == nil) {
        [self initializeCamera];
    }
    [self presentViewController:self.imagePickerController animated:YES completion:^{}];
}

- (void)chooseExisting {
    NSLog(@"choose existing...");
    if (self.photoLibraryController == nil) {
        [self initializePhotoLibrary];
    }
    [self presentViewController:self.photoLibraryController animated:YES completion:nil];
}

-(void)initializeCamera {
    NSLog(@"cinitializeCamera...");
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.allowsEditing = YES;
}

-(void)initializePhotoLibrary {
    NSLog(@"initializePhotoLibrary...");
    self.photoLibraryController = [[UIImagePickerController alloc] init];
    self.photoLibraryController.delegate = self;
    self.photoLibraryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;// SavedPhotosAlbum;
    self.photoLibraryController.allowsEditing = YES;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // TODO apri showImagePreview
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self afterPickerCompletion:picker withInfo:info];
}

-(void)afterPickerCompletion:(UIImagePickerController *)picker withInfo:(NSDictionary *)info {
    UIImage *bigImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    NSURL *local_image_url = [info objectForKey:@"UIImagePickerControllerImageURL"];
    NSString *image_original_file_name = [local_image_url lastPathComponent];
    NSLog(@"image_original_file_name: %@", image_original_file_name);
    self.scaledImage = bigImage;
    NSLog(@"image: %@", self.scaledImage);
    self.scaledImage = [ChatImageUtil adjustEXIF:self.scaledImage];
    self.scaledImage = [ChatImageUtil scaleImage:self.scaledImage toSize:CGSizeMake(1200, 1200)];
    //    [self performSegueWithIdentifier:@"imagePreview" sender:nil];
    [self sendImage:self.scaledImage];
}

-(void)sendImage:(UIImage *)image {
    NSLog(@"Sending image...");
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    [[ChatManager getInstance] uploadProfileImage:image profileId:self.profileId completion:^(NSString *downloadURL, NSError *error) {
        NSLog(@"Image uploaded. Download url: %@", downloadURL);
        [SVProgressHUD dismiss];
        if (error) {
            NSLog(@"Error during image upload.");
        }
        else {
            [self setupCurrentProfileViewWithImage:image];
            [self.imageCache updateProfile:self.profileId image:image];
        }
    } progressCallback:^(double fraction) {
        // NSLog(@"progress: %f", fraction);
    }];
}

//-(void)deleteImage {
//    NSLog(@"deleting profile image");
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
//    [SVProgressHUD show];
//    [[ChatManager getInstance] deleteProfileImage:self.profileId completion:^(NSError *error) {
//        [SVProgressHUD dismiss];
//        // remove this three lines of code
//        self.currentProfilePhoto = nil;
//        [self resetProfilePhoto];
//        ChatUser *loggedUser = [ChatManager getInstance].loggedUser;
//        [self.imageCache deleteImageFromCacheWithKey:[self.imageCache urlAsKey:[NSURL URLWithString:loggedUser.profileImageURL]]];
//        if (error) {
//            NSLog(@"Error while deleting profile image.");
//        }
//        else {
//            self.currentProfilePhoto = nil;
//            [self resetProfilePhoto];
//            ChatUser *loggedUser = [ChatManager getInstance].loggedUser;
//            [self.imageCache deleteImageFromCacheWithKey:[self.imageCache urlAsKey:[NSURL URLWithString:loggedUser.profileImageURL]]];
//        }
//    }];
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

