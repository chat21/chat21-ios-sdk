//
//  ChatUtil.h
//  Soleto
//
//  Created by Andrea Sponziello on 02/12/14.
//
//

#import <Foundation/Foundation.h>

@class Firebase;
@class ChatNotificationView;
@class ChatUser;

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
+(NSString *)groupImageUrlById:(NSString *)imageID;
+(NSString *)imageIDFilename:(NSString *)imageID;
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

+(NSString *)filePathOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileImagePathOf:(NSString *)profileId;
//+(NSString *)profileThumbImagePathOf:(NSString *)profileId;

+(NSString *)profileImageURLOf:(NSString *)profileId;
+(NSString *)profileThumbImageURLOf:(NSString *)profileId;
+(NSString *)fileURLOfProfile:(NSString *)profileId fileName:(NSString *)fileName;
+(NSString *)profileBaseURL:(NSString *)profileId;

@end
