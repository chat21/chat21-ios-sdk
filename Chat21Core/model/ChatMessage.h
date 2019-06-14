//
//  ChatMessage.h
//  Soleto
//
//  Created by Andrea Sponziello on 17/11/14.
//
//

#import <Foundation/Foundation.h>
@class ChatMessageMetadata;

static int const MSG_STATUS_FAILED = -100;
static int const MSG_STATUS_SENDING = 0;
static int const MSG_STATUS_UPLOADING = 5;
static int const MSG_STATUS_QUEUED = 50;
static int const MSG_STATUS_SENT = 100; // single checkmark
static int const MSG_STATUS_RECEIVED = 200; // communicates to backend that message was received
static int const MSG_STATUS_RETURN_RECEIPT = 250; // double checkmark
static int const MSG_STATUS_SEEN = 300;

// firebase fields
static NSString* const MSG_FIELD_CONVERSATION_ID = @"conversationId";
static NSString* const MSG_FIELD_TYPE = @"type";
static NSString* const MSG_FIELD_SUBTYPE = @"subtype";
static NSString* const MSG_FIELD_CHANNEL_TYPE = @"channel_type";
static NSString* const MSG_CHANNEL_TYPE_DIRECT = @"direct";
static NSString* const MSG_CHANNEL_TYPE_GROUP = @"group";
static NSString* const MSG_FIELD_TEXT = @"text";
static NSString* const MSG_FIELD_SENDER = @"sender";
static NSString* const MSG_FIELD_SENDER_FULLNAME = @"sender_fullname";
static NSString* const MSG_FIELD_RECIPIENT_FULLNAME = @"recipient_fullname";
static NSString* const MSG_FIELD_RECIPIENT = @"recipient";
static NSString* const MSG_FIELD_RECIPIENT_GROUP_ID = @"recipientGroupId";
static NSString* const MSG_FIELD_LANG = @"language";
static NSString* const MSG_FIELD_TIMESTAMP = @"timestamp";
static NSString* const MSG_FIELD_STATUS = @"status";
static NSString* const MSG_FIELD_ATTRIBUTES = @"attributes";
static NSString* const MSG_FIELD_IMAGE_URL = @"imageUrl";
static NSString* const MSG_FIELD_IMAGE_FILENAME = @"image_filename";
static NSString* const MSG_FIELD_IMAGE_WIDTH = @"imageWidth";
static NSString* const MSG_FIELD_IMAGE_HEIGHT = @"imageHeight";
static NSString* const MSG_TYPE_IMAGE= @"image";
static NSString* const MSG_TYPE_TEXT = @"text";
static NSString* const MSG_TYPE_INFO = @"info";
static NSString* const MSG_TYPE_DROPBOX = @"dropbox";
static NSString* const MSG_TYPE_ALFRESCO = @"text"; // era: alfresco
static NSString* const MSG_DROPBOX_NAME = @"dropbox_name";
static NSString* const MSG_DROPBOX_LINK = @"dropbox_link";
static NSString* const MSG_DROPBOX_SIZE = @"dropbox_size";
static NSString* const MSG_DROPBOX_ICONURL = @"dropbox_iconURL";
static NSString* const MSG_FIELD_METADATA = @"metadata";
static NSString* const MSG_METADATA_ATTACHMENT_SRC = @"src";
static NSString* const MSG_METADATA_IMAGE_WIDTH = @"width";
static NSString* const MSG_METADATA_IMAGE_HEIGHT = @"height";

@import Firebase;
#import <UIKit/UIKit.h>

//@class Firebase;
@class FDataSnapshot;

@interface ChatMessage : NSObject// <JSQMessageData>

@property (nonatomic, strong) FIRDatabaseReference *ref;

//@property (nonatomic, strong) NSString *key; // firebase-key
@property (nonatomic, strong) NSString *messageId; // firebase-key
@property (nonatomic, strong, nonnull) NSString *text; // firebase
@property (nonatomic, strong, nonnull) NSString *sender; // firebase
@property (nonatomic, strong) NSString * _Nullable senderFullname; // firebase
@property (nonatomic, strong, nonnull) NSString *recipient; // firebase
@property (nonatomic, strong) NSString * _Nullable recipientFullName; // firebase
@property (nonatomic, strong, nonnull) NSString *channel_type; // firebase
@property (nonatomic, strong) NSString * _Nullable lang; // firebase
@property (nonatomic, strong, nonnull) NSDate *date; // firebase (converted to timestamp)
@property (nonatomic, assign) int status; // firebase
@property (nonatomic, strong, nonnull) NSString *mtype; // firebase
@property (nonatomic, strong) NSString * _Nullable subtype; // firebase
@property (strong, nonatomic) NSString * _Nullable imageURL; // firebase
@property (strong, nonatomic) NSString * _Nullable imageFilename; // firebase - used to save image locally
@property (nonatomic, strong) ChatMessageMetadata * _Nullable metadata; // firebase
@property (nonatomic, strong) NSMutableDictionary * _Nullable attributes; // firebase

@property (nonatomic, strong) NSString * _Nullable conversationId; // decoded, = recipientId
@property (nonatomic, assign) BOOL archived;
@property (nonatomic, assign) BOOL media; // decode by mtype (if type == IMAGE, media = YES)
@property (nonatomic, assign) BOOL document; // decode by mtype (if type == DOCUMENT, document = YES)
@property (nonatomic, assign) BOOL link; // decode by mtype & content (if type == text && text contains a link, link = YES)
@property (nonatomic, assign) BOOL isDirect; // decoded by channel_type
@property (nonatomic, assign) BOOL typeText; // decoded by mtype
@property (nonatomic, assign) BOOL typeImage; // decoded by mtype

@property (nonatomic, strong) NSDictionary * _Nullable snapshot;
@property (nonatomic, strong) NSString * _Nullable snapshotAsJSONString;

//@property (nonatomic, strong) NSString *attributesAsJSONString;

@property (strong, nonatomic) UIImage * _Nullable image; // only for rendering


-(UIImage *_Nullable)imageFromMediaFolder;
-(NSString *_Nullable)dateFormattedForListView;
-(void)updateStatusOnFirebase:(int)status;
-(BOOL)imageExistsInMediaFolder;
-(NSString *_Nullable)imagePathFromMediaFolder;
-(UIImage *_Nullable)imagePlaceholder;
-(NSString *_Nullable)mediaFolderPath;
-(NSError *_Nullable)createMediaFolderPathIfNotExists;
+(ChatMessage *_Nullable)messageFromfirebaseSnapshotFactory:(FIRDataSnapshot *_Nullable)snapshot;
-(NSMutableDictionary *_Nullable)asFirebaseMessage;
//+(ChatMessage *)messageFromSnapshotFactoryTEST:(FDataSnapshot *)snapshot;
+(NSString *)imageTextPlaceholder:(NSString *_Nullable)imageURL;
-(void)setCorrectText:(ChatMessage *)message text:(NSString *_Nullable)text;

-(BOOL)validImageMetadata;
-(CGSize)imageSize;

-(ChatMessage *_Nonnull)clone;

@end
