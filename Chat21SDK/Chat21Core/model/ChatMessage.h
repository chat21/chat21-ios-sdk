//
//  ChatMessage.h
//  Soleto
//
//  Created by Andrea Sponziello on 17/11/14.
//
//

#import <Foundation/Foundation.h>

static int const MSG_STATUS_FAILED = -100;
static int const MSG_STATUS_SENDING = 0;
static int const MSG_STATUS_QUEUED = 50;
static int const MSG_STATUS_SENT = 100;
static int const MSG_STATUS_RECEIVED = 200; // comunico al server che ho ricevuto il messaggio
static int const MSG_STATUS_RETURN_RECEIPT = 250; // la doppia spunta
static int const MSG_STATUS_SEEN = 300;

// firebase fields
static NSString* const MSG_FIELD_CONVERSATION_ID = @"conversationId";
static NSString* const MSG_FIELD_TYPE = @"type";
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
static NSString* const MSG_TYPE_TEXT = @"text";
static NSString* const MSG_TYPE_INFO = @"info";
static NSString* const MSG_TYPE_DROPBOX = @"dropbox";
static NSString* const MSG_TYPE_ALFRESCO = @"text"; // era: alfresco
static NSString* const MSG_DROPBOX_NAME = @"dropbox_name";
static NSString* const MSG_DROPBOX_LINK = @"dropbox_link";
static NSString* const MSG_DROPBOX_SIZE = @"dropbox_size";
static NSString* const MSG_DROPBOX_ICONURL = @"dropbox_iconURL";

@import Firebase;

//@class Firebase;
@class FDataSnapshot;

@interface ChatMessage : NSObject// <JSQMessageData>

@property (nonatomic, strong) NSString *key; // firebase-key
@property (nonatomic, strong) FIRDatabaseReference *ref;
@property (nonatomic, strong) NSString *messageId; // firebase-key
@property (nonatomic, strong) NSString *text; // firebase
@property (nonatomic, strong) NSString *sender; // firebase
@property (nonatomic, strong) NSString *senderFullname; // firebase
@property (nonatomic, strong) NSString *recipient; // firebase
@property (nonatomic, strong) NSString *recipientFullName; // firebase
//@property (nonatomic, strong) NSString *recipientGroupId; // firebase
@property (nonatomic, strong) NSString *channel_type; // firebase
@property (nonatomic, strong) NSString *conversationId;
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSDate *date; // firebase (converted to timestamp)
@property (nonatomic, assign) BOOL archived;
@property (nonatomic, assign) int status; // firebase
@property (nonatomic, strong) NSString *mtype; // firebase
@property (nonatomic, strong) NSDictionary *attributes; // firebase

@property (nonatomic, assign) BOOL isDirect;

-(NSString *)dateFormattedForListView;
-(void)updateStatusOnFirebase:(int)status;
+(ChatMessage *)messageFromSnapshotFactory:(FIRDataSnapshot *)snapshot;
//+(ChatMessage *)messageFromSnapshotFactoryTEST:(FDataSnapshot *)snapshot;

@end
