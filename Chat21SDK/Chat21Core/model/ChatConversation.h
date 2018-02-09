//
//  ChatConversation.h
//  Soleto
//
//  Created by Andrea Sponziello on 22/11/14.
//
//

#import <Foundation/Foundation.h>

static int const CONV_STATUS_FAILED = 0;
static int const CONV_STATUS_JUST_CREATED = 1;
static int const CONV_STATUS_LAST_MESSAGE = 2;

static NSString* const CONV_LAST_MESSAGE_TEXT_KEY = @"last_message_text";
static NSString* const CONV_RECIPIENT_KEY = @"recipient";
static NSString* const CONV_SENDER_KEY = @"sender";
static NSString* const CONV_SENDER_FULLNAME_KEY = @"sender_fullname";
static NSString* const CONV_RECIPIENT_FULLNAME_KEY = @"recipient_fullname";
static NSString* const CONV_TIMESTAMP_KEY = @"timestamp";
static NSString* const CONV_IS_NEW_KEY = @"is_new";
static NSString* const CONV_CONVERS_WITH_KEY = @"convers_with";
//static NSString* const CONV_CONVERS_WITH_FULLNAME_KEY = @"convers_with_fullname";
//static NSString* const CONV_GROUP_ID_KEY = @"group_id";
//static NSString* const CONV_GROUP_NAME_KEY = @"group_name";
static NSString* const CONV_CHANNEL_TYPE_KEY = @"channel_type";
static NSString* const CONV_STATUS_KEY = @"status";
static NSString* const CONV_ATTRIBUTES_KEY = @"attributes";

@import Firebase;
@class ChatUser;

//@class Firebase;
//@class FDataSnapshot;

@interface ChatConversation : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) FIRDatabaseReference *ref;
@property (nonatomic, strong) NSString *conversationId;
@property (nonatomic, strong) NSString *user; // used to query conversations on local DB
@property (nonatomic, strong) NSString *last_message_text;
@property (nonatomic, assign) BOOL is_new;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *sender;
@property (nonatomic, strong) NSString *senderFullname;
@property (nonatomic, strong) NSString *recipient;
@property (nonatomic, strong) NSString *recipientFullname;
@property (nonatomic, strong) NSString *conversWith;
@property (nonatomic, strong) NSString *conversWith_fullname;
@property (nonatomic, strong) NSString *channel_type;
@property (nonatomic, assign) int status;
@property (nonatomic, strong) NSDictionary *attributes; // firebase

@property (nonatomic, assign) BOOL isDirect;

// group conversation properties
//@property (nonatomic, strong) NSString *groupId; // used to recover group information on demand
//@property (nonatomic, strong) NSString *groupName; // replaces "conversWith" caption in the cell

-(NSString *)dateFormattedForListView;
//+(ChatConversation *)conversationFromSnapshotFactory:(FDataSnapshot *)snapshot;

-(NSString *)textForLastMessage:(NSString *)me;

//-(NSMutableDictionary *)asDictionary;

+(ChatConversation *)conversationFromSnapshotFactory:(FIRDataSnapshot *)snapshot me:(ChatUser *)me;


@end
