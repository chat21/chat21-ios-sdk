//
//  ChatUtil.h
//  Soleto
//
//  Created by Andrea Sponziello on 02/12/14.
//
//

#import <Foundation/Foundation.h>

@import UIKit;
@class Firebase;
@class ChatNotificationView;
@class ChatUser;
@class ChatDiskImageCache;

@import Firebase;

@interface ChatUtil : NSObject

+(FIRDatabaseReference *)conversationRefForUser:(NSString *)userId conversationId:(NSString *)conversationId;
+(FIRDatabaseReference *)conversationMessagesRef:(NSString *)recipient_id;

// firebase paths
+(NSString *)conversationPathForUser:(NSString *)user_id conversationId:(NSString *)conversationId;
+(NSString *)conversationsPathForUserId:(NSString *)user_id;
+(NSString *)archivedConversationsPathForUserId:(NSString *)user_id;
+(NSString *)contactsPath;
+(NSString *)contactPathOfUser:(NSString *)userid;
+(NSString *)groupsPath;
+(NSString *)mainGroupsPath;

+(NSMutableDictionary *)groupMembersAsDictionary:(NSArray *)membersArray;
+(NSMutableArray *)groupMembersAsArray:(NSDictionary *)membersDictionary;
+(NSString *)groupMembersAsStringForUI:(NSDictionary *)membersDictionary;
+(NSString *)groupMembersFullnamesAsStringForUI:(NSArray<ChatUser *> *)members;
+(NSString *)randomString:(NSInteger)length;

+(NSString *)groupImagesRelativePath;
+(NSString *)groupImageDownloadUrl;
+(NSString *)groupImageDeleteUrl;
//+(NSString *)groupImageUrlById:(NSString *)imageID;
//+(NSString *)imageIDFilename:(NSString *)imageID;
+(NSString *)userPath:(NSString *)userId;
+(NSString *)sanitizedNode:(NSString *)node_name;
+(NSString *)sanitizedUserId:(NSString *)userId;

// *** Strings ***

+(NSString *)timeFromNowToStringFormattedForConversation:(NSDate *)date;
+(BOOL)isYesterday:(NSDate *)date;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

+(NSString *)absoluteFolderPath:(NSString *)folderName;

// *** Images ***
+(UIImage *)circleImage:(UIImage *)image;

//+(void)updateProfileInCache:(ChatDiskImageCache *)imageCache profile:(NSString *)profileId image:(UIImage *)image;

@end
