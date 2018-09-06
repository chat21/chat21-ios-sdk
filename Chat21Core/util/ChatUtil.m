//
//  ChatUtil.m
//  Soleto
//
//  Created by Andrea Sponziello on 02/12/14.
//
//

#import "ChatUtil.h"
#import <Firebase/Firebase.h>
#import "ChatConversation.h"
#import "ChatManager.h"
//#import "NotificationAlertView.h"
#import "ChatConversationsVC.h"
#import "ChatLocal.h"
#import "ChatDiskImageCache.h"

@implementation ChatUtil

+(FIRDatabaseReference *)conversationRefForUser:(NSString *)userId conversationId:(NSString *)conversationId {
    NSString *relative_path = [self conversationPathForUser:userId conversationId:conversationId];
    FIRDatabaseReference *repoRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *conversation_ref_on_user = [repoRef child:relative_path];
    return conversation_ref_on_user;
}

+(NSString *)conversationPathForUser:(NSString *)user_id conversationId:(NSString *)conversationId {
    // path: apps/{tenant}/users/{userdId}/conversations/{conversationId}
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *conversation_path = [[NSString alloc] initWithFormat:@"apps/%@/users/%@/conversations/%@",tenant, user_id, conversationId];
    return conversation_path;
}

//+(Firebase *)conversationMessagesRef:(NSString *)conversationId settings:(NSDictionary *)settings {
+(FIRDatabaseReference *)conversationMessagesRef:(NSString *)recipient_id {
    // path: apps/{tenant}/messages/{conversationId}
    ChatManager *chat = [ChatManager getInstance];
    NSString *appid = chat.tenant;
    NSString *me = chat.loggedUser.userId;
    NSString *firebase_conversation_messages_ref = [[NSString alloc] initWithFormat:@"apps/%@/users/%@/messages/%@", appid, me, recipient_id];
//    NSLog(@"##### firebase_conversation_messages_ref: %@", firebase_conversation_messages_ref);
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *messagesRef = [rootRef child:firebase_conversation_messages_ref];
    return messagesRef;
}

+(NSString *)sanitizedNode:(NSString *)node_name {
    // Firebase not accepted characters for node names must be a non-empty string and not contain:
    // . # $ [ ]
    NSString* _node_name;
    _node_name = [node_name stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    _node_name = [_node_name stringByReplacingOccurrencesOfString:@"#" withString:@"_"];
    _node_name = [_node_name stringByReplacingOccurrencesOfString:@"$" withString:@"_"];
    _node_name = [_node_name stringByReplacingOccurrencesOfString:@"[" withString:@"_"];
    _node_name = [_node_name stringByReplacingOccurrencesOfString:@"]" withString:@"_"];
    // "-", chat21 tenant - username sparator
    _node_name = [_node_name stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    
    return _node_name;
}

+(NSString *)sanitizedUserId:(NSString *)userId {
    return [ChatUtil sanitizedNode:userId];
}

//+(NSString *)buildConversationsReferenceWithTenant:(NSString *)tenant username:(NSString *)user_id baseFirebaseRef:(NSString *)baseFirebaseRef {
//    NSString *tenant_user_sender = [ChatUtil usernameOnTenant:tenant username:user_id];
//    NSLog(@"tenant-user-sender-id: %@", tenant_user_sender);
//    
//    NSString *firebase_conversations_ref = [baseFirebaseRef stringByAppendingFormat:@"/tenantUsers/%@/conversations", tenant_user_sender];
//    NSLog(@"buildConversationsReferenceWithTenant > firebase_conversations_ref: %@", firebase_conversations_ref);
//    return firebase_conversations_ref;
//}

+(NSString *)conversationsPathForUserId:(NSString *)user_id {
    // path: apps/{tenant}/users/{userId}/conversations
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *conversations_path = [[NSString alloc] initWithFormat:@"/apps/%@/users/%@/conversations", tenant, user_id];
    return conversations_path;
}

+(NSString *)archivedConversationsPathForUserId:(NSString *)user_id {
    // path: apps/{tenant}/users/{userId}/archived_conversations
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *conversations_path = [[NSString alloc] initWithFormat:@"/apps/%@/users/%@/archived_conversations", tenant, user_id];
    return conversations_path;
}

// +(FIRDatabaseReference *)groupsRefWithBase:(NSString *)firebasePath {
//     FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//     NSString *groups_path = [ChatUtil groupsPath];
//     FIRDatabaseReference *firebase_groups_ref = [rootRef child:groups_path];
//     return firebase_groups_ref;
// }

+(NSString *)mainGroupsPath {
    NSString *tenant = [ChatManager getInstance].tenant;
//    NSString *userid = [ChatManager getSharedInstance].loggedUser.userId;
    //NSString *path = [[NSString alloc] initWithFormat:@"/apps/%@/users/%@/groups", tenant, userid];
    NSString *path = [[NSString alloc] initWithFormat:@"/apps/%@/groups", tenant];
    return path;
}

+(NSString *)groupsPath {
    ChatManager *chat = [ChatManager getInstance];
    NSString *tenant = chat.tenant;
    NSString *userid = chat.loggedUser.userId;
    NSString *path = [[NSString alloc] initWithFormat:@"/apps/%@/users/%@/groups", tenant, userid];
    return path;
}

+(NSString *)contactsPath {
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *contacts_path = [[NSString alloc] initWithFormat:@"/apps/%@/contacts", tenant];
    return contacts_path;
}

+(NSString *)contactPathOfUser:(NSString *)userid {
    NSString *contacts_path = [ChatUtil contactsPath];
    NSString *contact_path = [[NSString alloc] initWithFormat:@"%@/%@", contacts_path, userid];
    return contact_path;
}

//+(void)moveToConversationViewWithUser:(ChatUser *)user orGroup:(NSString *)groupid sendMessage:(NSString *)message attributes:(NSDictionary *)attributes {
//    int chat_tab_index = [HelloApplicationContext tabIndexByName:@"ChatController"];
//    NSLog(@"processRemoteNotification: messages_tab_index %d", chat_tab_index);
//    // move to the converstations tab
//    if (chat_tab_index >= 0) {
//        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
//        UITabBarController *tabController = (UITabBarController *)window.rootViewController;
//        NSLog(@"Current tab bar controller selectedIndex: %lu", (unsigned long)tabController.selectedIndex);
//        NSArray *controllers = [tabController viewControllers];
//        UIViewController *currentVc = [controllers objectAtIndex:tabController.selectedIndex];
//        [currentVc dismissViewControllerAnimated:NO completion:nil];
//        ChatRootNC *nc = [controllers objectAtIndex:chat_tab_index];
//        NSLog(@"openConversationWithRecipient:%@ orGroup: %@ sendText:%@", user.userId, groupid, message);
//        tabController.selectedIndex = chat_tab_index;
//        [nc openConversationWithUser:user orGroup:groupid sendMessage:message attributes:attributes];
//    } else {
//        NSLog(@"No Chat Tab configured");
//    }
//}

// at creation time from array (memory, UI) to dictionary (firebase)
+(NSMutableDictionary *)groupMembersAsDictionary:(NSArray *)membersArray {
    NSMutableDictionary *membersDictionary = [[NSMutableDictionary alloc] init];
    for (NSString *memberId in membersArray) {
        [membersDictionary setObject:memberId forKey:memberId];
    }
    return membersDictionary;
}

// at download time from dictionary (firebase) to array (memory)
+(NSMutableArray *)groupMembersAsArray:(NSDictionary *)membersDictionary {
    NSMutableArray *membersArray = [[NSMutableArray alloc] init];
    for(id key in membersDictionary) {
        id value = [membersDictionary objectForKey:key];
        [membersArray addObject:value];
    }
    return membersArray;
}

+(NSString *)groupMembersAsStringForUI:(NSDictionary *)membersDictionary {
    if (membersDictionary.count == 0) {
        return @"";
    }
    NSArray *keys = [membersDictionary allKeys];
    NSString *members_string = [keys objectAtIndex:0];
    for (int i = 1; i < keys.count; i++) {
        NSString *member = (NSString *)keys[i];
        NSString *m_to_add = [[NSString alloc] initWithFormat:@", %@", member];
        members_string = [members_string stringByAppendingString:m_to_add];
    }
    return members_string;
}

+(NSString *)groupMembersFullnamesAsStringForUI:(NSArray<ChatUser *> *)members {
    ChatUser *last_contact = [members lastObject];
    NSString *members_string = @"";
    NSString *partial;
    for (ChatUser *contact in members) {
        NSString *fullname = [contact.fullname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *last_first_names = [fullname componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *names = [last_first_names filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSString *name = (names.count > 0 ? names[0] : fullname);
        if (![contact.userId isEqualToString:last_contact.userId]) {
            partial = [[NSString alloc] initWithFormat:@"%@,", name];
        }
        else {
            partial = [[NSString alloc] initWithFormat:@"%@", name];
        }
        members_string = [members_string stringByAppendingString:partial];
    }
    return members_string;
}

+(NSString *)randomString:(NSInteger)length {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0U; i < 20; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

+(NSString *)userPath:(NSString *)userId {
    // path: apps/{tenant}/users/{userId}
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *user_path = [[NSString alloc] initWithFormat:@"/apps/%@/users/%@", tenant, userId];
    return user_path;
}

// ****** GROUP IMAGES ******

+(NSString *)groupImagesRelativePath {
//    HelloAppDelegate *appDelegate = (HelloAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSDictionary *plistDictionary = appDelegate.applicationContext.plistDictionary;
//    NSDictionary *settingsDictionary = [plistDictionary objectForKey:@"Images"];
//    NSString *imagesPath = [settingsDictionary objectForKey:@"groupImagesPath"];
//    return imagesPath;
    return nil;
}

// smart21
+(NSString *)groupImageDownloadUrl {
//    HelloAppDelegate *appDelegate = (HelloAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSDictionary *plistDictionary = appDelegate.applicationContext.plistDictionary;
//    NSDictionary *settingsDictionary = [plistDictionary objectForKey:@"Images"];
//    NSString *serviceURL = [settingsDictionary objectForKey:@"smart21ServiceDownload"];
//
//    NSString *imagesPath = [ChatUtil groupImagesRelativePath];
//    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@", serviceURL, imagesPath];
//    return url;
    return nil;
}

+(NSString *)groupImageDeleteUrl {
    
//    HelloAppDelegate *appDelegate = (HelloAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSDictionary *plistDictionary = appDelegate.applicationContext.plistDictionary;
//    NSDictionary *settingsDictionary = [plistDictionary objectForKey:@"Images"];
//    NSString *serviceURL = [settingsDictionary objectForKey:@"smart21ServiceDelete"];
//
//    NSString *imagesPath = [ChatUtil groupImagesRelativePath];
//    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@", serviceURL, imagesPath];
//
//    return url;
    return nil;
}

+(NSString *)groupImageUrlById:(NSString *)imageID {
//    NSString *name = [NSString stringWithFormat:@"%@.png", imageID];
    NSString *name = [ChatUtil imageIDFilename:imageID];
    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@", [ChatUtil groupImageDownloadUrl], name];
    return url;
}

+(NSString *)imageIDFilename:(NSString *)imageID {
    NSString *name = [NSString stringWithFormat:@"%@.jpg", imageID];
    return name;
}

// ****** END GROUP IMAGES *****

// ** STRINGS **

+(NSString *)timeFromNowToStringFormattedForConversation:(NSDate *)date {
    // TEST
    //    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //    [df setDateFormat:@"dd-MM-yyyy HH:mm"];
    //    NSString *ds = @"7-4-2016 14:50";
    //    NSDate *date = [df dateFromString: ds];
    
    /*
     a few seconds ago
     about a minute ago
     15 minutes ago
     about one hour ago
     2 hours ago
     23 hours ago
     Yesterday at 5:07pm TODO
     October 11
     */
    NSString *timeMessagePart;
    NSString *unitMessagePart;
    NSDate *now = [[NSDate alloc] init];
    //    NSLog(@"NOW: %@", now);
    //    NSLog(@"DATE: %@", date);
    double nowInSeconds = [now timeIntervalSince1970];
    //    NSLog(@"NOW IN SECONDS %f", nowInSeconds);
    double startDateInSeconds = [date timeIntervalSince1970];
    //    NSLog(@"START DATE IN SECONDS %f", startDateInSeconds);
    double secondsElapsed = nowInSeconds - startDateInSeconds;
    //    NSLog(@"SECONDS ELAPSED %f", secondsElapsed);
    if (secondsElapsed < 60) {
        NSLog(@"<60");
        timeMessagePart = [ChatLocal translate:@"FewSecondsAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 60 && secondsElapsed <120) {
        //        NSLog(@"<120");
        timeMessagePart = [ChatLocal translate:@"AboutAMinuteAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 120 && secondsElapsed <3600) {
        //        NSLog(@"<360");
        int minutes = secondsElapsed / 60.0;
        timeMessagePart = [[NSString alloc] initWithFormat:@"%d ", minutes];
        unitMessagePart = [ChatLocal translate:@"MinutesAgoLKey"];
    }
    else if (secondsElapsed >=3600 && secondsElapsed < 5400) {
        //        NSLog(@"<5400");
        timeMessagePart = [ChatLocal translate:@"AboutAnHourAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 5400 && secondsElapsed <= 86400) { // HH:mm
        //        NSLog(@"<86400");
        if ([ChatUtil isYesterday:date]) {
            //            NSLog(@"Yesterday in < 1 day");
            timeMessagePart = [ChatLocal translate:@"yesterday"];
            unitMessagePart = @"";
        } else {
            //            NSLog(@"Not Yesterday. time in this day");
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"HH:mm"];
            timeMessagePart = [dateFormat stringFromDate:date];
            unitMessagePart = @"";
        }
    }
    else if (secondsElapsed > 86400 && secondsElapsed <= 518400) { // 518.400 = 6 days. Format = Thrusday, Monday ...
        if ([ChatUtil isYesterday:date]) {
            //            NSLog(@"Yesterday");
            timeMessagePart = [ChatLocal translate:@"yesterday"];
            unitMessagePart = @"";
        } else {
            //            NSLog(@"Thrusday, monday...");
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"EEEE"];
            timeMessagePart = [dateFormat stringFromDate:date];
            unitMessagePart = @"";
        }
    }
    else { // 6/4/2015
        //        NSLog(@"6/4/2015...");
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // http://mobiledevelopertips.com/cocoa/date-formatters-examples-take-2.html
        [dateFormat setDateFormat:[ChatLocal translate:@"ShortDateFormat"]];
        timeMessagePart = [dateFormat stringFromDate:date];
        unitMessagePart = @"";
    }
    NSString *timeString = [[NSString alloc] initWithFormat:@"%@%@", timeMessagePart, unitMessagePart];
    //    NSLog(@"TIMESTRING %@", timeString);
    return timeString;
}

+(BOOL)isYesterday:(NSDate *)date {
    //    NSDate *now = [NSDate date];
    //    // All intervals taken from Google
    //    NSDate *yesterday = [now dateByAddingTimeInterval: -86400.0];
    //    NSLog(@"yesterday %@", yesterday);
    //    return yesterday ? YES : NO;
    
    // ios 8 only
    NSCalendar* calendar = [NSCalendar currentCalendar];
    return [calendar isDateInYesterday:date];
}

// *** Images ***

+(UIImage *)circleImage:(UIImage *)image {
    //    NSLog(@"ORIGINAL SIZE: W: %f H: %f", image.size.width, image.size.height);
    UIImage* circle_image;
    float min_side = image.size.height;
    if (image.size.width < min_side) {
        min_side = image.size.width;
    }
    float radius = min_side / 2.0;
    
    CGRect rect = CGRectMake(0, 0, radius, radius);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    //    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:radius] addClip];
    // Draw your image
    [image drawInRect:rect];
    
    // Get the image, here setting the UIImageView image
    circle_image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Lets forget about that we were drawing
    UIGraphicsEndImageContext();
    return circle_image;
    
    
    //    UIGraphicsBeginImageContext(self.frame.size);
    //    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //    CGFloat height = self.bounds.size.height;
    //    CGContextTranslateCTM(ctx, 0.0, height);
    //    CGContextScaleCTM(ctx, 1.0, -1.0);
    //    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, 50, 0, 2*M_PI, 0);
    //    CGContextClosePath(ctx);
    //    CGContextSaveGState(ctx);
    //    CGContextClip(ctx);
    //    CGContextDrawImage(ctx, CGRectMake(0,0,self.frame.size.width, self.frame.size.height), image.CGImage);
    //    CGContextRestoreGState(ctx);
    //    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    //    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

+(NSString *)absoluteFolderPath:(NSString *)folderName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:folderName];
    return path;
}

// **** PROFILE IMAGE URL ****

+(NSString *)filePathOfProfile:(NSString *)profileId fileName:(NSString *)fileName {
    return [[NSString alloc] initWithFormat:@"profiles/%@/%@", profileId, fileName];
}

+(NSString *)profileImagePathOf:(NSString *)profileId {
    return [ChatUtil filePathOfProfile:profileId fileName:@"photo.jpg"];
}

//+(NSString *)profileThumbImagePathOf:(NSString *)profileId {
//    return [ChatUtil filePathOfProfile:profileId fileName:@"thumb_photo.jpg"];
//}

+(NSString *)profileImageURLOf:(NSString *)profileId {
    // http://base-url/profile/USER-ID/photo.jpg
    return [ChatUtil fileURLOfProfile:profileId fileName:@"photo.jpg"];
}

+(NSString *)profileThumbImageURLOf:(NSString *)profileId {
    // http://base-url/profile/USER-ID/thumb_photo.jpg
    return [ChatUtil fileURLOfProfile:profileId fileName:@"thumb_photo.jpg"];
}

+(NSString *)fileURLOfProfile:(NSString *)profileId fileName:(NSString *)fileName {
    NSString *profile_base_url = [ChatUtil profileBaseURL:profileId];
    NSString *file_url = [[NSString alloc] initWithFormat:@"%@%%2F%@?alt=media", profile_base_url, fileName];
    NSLog(@"profile file url: %@", file_url);
    return file_url;
//    NSLog(@"%@", [ChatUtil profileBaseURL:profileId]);
//    NSString *image_path = [ChatUtil profileImagePathOf:profileId]; //[[NSString alloc] initWithFormat:@"profiles/%@/%@", profileId, imageName];
//    NSDictionary *google_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"]];
//    NSDictionary *chat_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
//    NSString *file_path_url_escaped = [image_path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//    NSString *bucket = [google_info_dict objectForKey:@"STORAGE_BUCKET"];
//    NSString *profile_image_base_url = [chat_info_dict objectForKey:@"profile-image-base-url"];
//    NSString *base_url = [[NSString alloc] initWithFormat:profile_image_base_url, bucket ];
//    NSString *image_url = [[NSString alloc] initWithFormat:@"%@/%@?alt=media", base_url, file_path_url_escaped];
//    NSLog(@"profile image url: %@", image_url);
//    return image_url;
}

+(NSString *)profileBaseURL:(NSString *)profileId {
    // RETURNS:
    // https://firebasestorage.googleapis.com/v0/b/chat-v2-dev.appspot.com/o/profiles/PROFILE-ID
    NSDictionary *google_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"]];
    NSDictionary *chat_info_dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Chat-Info" ofType:@"plist"]];
    NSString *bucket = [google_info_dict objectForKey:@"STORAGE_BUCKET"];
    NSString *profile_image_base_url = [chat_info_dict objectForKey:@"profile-image-base-url"];
    NSString *base_url = [[NSString alloc] initWithFormat:profile_image_base_url, bucket ];
    NSString *profile_base_url = [[NSString alloc] initWithFormat:@"%@/profiles%%2F%@", base_url, profileId];
    NSLog(@"profile_base_url: %@", profile_base_url);
    return profile_base_url;
}

+(void)updateProfileInCache:(ChatDiskImageCache *)imageCache profile:(NSString *)profileId image:(UIImage *)image {
    NSString *imageURL = [ChatUtil profileImageURLOf:profileId];
    NSLog(@"imageURL %@", imageURL);
    NSString *thumbImageURL = [ChatUtil profileThumbImageURLOf:profileId];
    NSLog(@"thumbImageURL %@", thumbImageURL);
    
    NSString *imageKey = [imageCache urlAsKey:[NSURL URLWithString:imageURL]];
    NSLog(@"imageKey %@", imageKey);
    [imageCache addImageToCache:image withKey:imageKey];
    
    // adds also a local thumb in cache.
    NSString *thumbImageKey = [imageCache urlAsKey:[NSURL URLWithString:thumbImageURL]];
    NSLog(@"thumbImageKey %@", thumbImageKey);
    [imageCache addImageToCache:image withKey:thumbImageKey];
    [imageCache removeCachedImage:thumbImageKey sized:120];
}

//+(NSString *)profileImageURLOf:(NSString *)profileId {
//    return [ChatUtil fileURLOfProfile:profileId fileName:@"photo.jpg"];
//}
//
//+(NSString *)profileThumbImageURLOf:(NSString *)profileId {
//    return [ChatUtil fileURLOfProfile:profileId fileName:@"thumb_photo.jpg"];
//}

// **** PROFILE IMAGE URL - END ****

@end
