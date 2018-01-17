//
//  ChatConversation.m
//  Soleto
//
//  Created by Andrea Sponziello on 22/11/14.
//
//

#import "ChatConversation.h"
//#import "ChatDB.h"
#import "ChatUser.h"
#import "ChatUtil.h"
#import "ChatMessage.h"

@implementation ChatConversation

-(NSString *)dateFormattedForListView {
    NSString *date = [ChatUtil timeFromNowToStringFormattedForConversation:self.date];
//    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
//    [timeFormat setDateFormat:@"HH:mm"];
//    NSString *date = [timeFormat stringFromDate:self.date];
    return date;
}

-(NSString *)textForLastMessage:(NSString *)me {
//    NSLog(@"SENDER: %@ ME: %@", self.sender, me);
    if ([self.sender isEqualToString:me]) {
        NSString *you = NSLocalizedString(@"You", nil);
        return [[NSString alloc] initWithFormat:@"%@: %@", you, self.last_message_text];
    } else {
        return self.last_message_text;
    }
}

//-(NSMutableDictionary *)asDictionary {
////    NSNumber *msg_timestamp = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];
//    
//    NSMutableDictionary *conversation_dict = [[NSMutableDictionary alloc] init];
//    // always
//    [conversation_dict setObject:self.last_message_text forKey:CONV_LAST_MESSAGE_TEXT_KEY];
//    NSString *sanitized_sender = [self.sender stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//    [conversation_dict setObject:sanitized_sender forKey:CONV_SENDER_KEY];
//    if (self.senderFullname) { // senderFullname is null for "group created message" conversation (it's like -the senderFullname is "System"-).
//        [conversation_dict setObject:self.senderFullname forKey:CONV_SENDER_FULLNAME_KEY];
//    }
//    
//    [conversation_dict setObject:[FIRServerValue timestamp] forKey:CONV_TIMESTAMP_KEY];
//    [conversation_dict setObject:[NSNumber numberWithBool:self.is_new] forKey:CONV_IS_NEW_KEY];
//    [conversation_dict setObject:[NSNumber numberWithInteger:self.status] forKey:CONV_STATUS_KEY];
//    
//    // only if one-to-one
////    if (self.recipient) {
////    if ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_DIRECT]) {
//    [conversation_dict setValue:self.recipient forKey:CONV_RECIPIENT_KEY];
//    [conversation_dict setValue:self.recipientFullname forKey:CONV_RECIPIENT_FULLNAME_KEY];
//    
////    }
//    // only if group
////    if (self.groupId) {
////        [conversation_dict setValue:self.groupId forKey:CONV_GROUP_ID_KEY];
////    }
////    if (self.groupName) {
////        [conversation_dict setValue:self.groupName forKey:CONV_GROUP_NAME_KEY];
////    }
//    return conversation_dict;
//}

+(ChatConversation *)conversationFromSnapshotFactory:(FIRDataSnapshot *)snapshot me:(ChatUser *)me {
    NSString *text = snapshot.value[CONV_LAST_MESSAGE_TEXT_KEY];
    NSString *recipient = snapshot.value[CONV_RECIPIENT_KEY];
    NSString *sender = snapshot.value[CONV_SENDER_KEY];
    NSString *senderFullname = snapshot.value[CONV_SENDER_FULLNAME_KEY];
    NSString *recipientFullname = snapshot.value[CONV_RECIPIENT_FULLNAME_KEY];
    NSString *channel_type = snapshot.value[CONV_CHANNEL_TYPE_KEY];
//    NSString *groupId = snapshot.value[CONV_GROUP_ID_KEY];
//    NSString *groupName = snapshot.value[CONV_GROUP_NAME_KEY];
    NSNumber *timestamp = snapshot.value[CONV_TIMESTAMP_KEY];
    NSNumber *is_new = snapshot.value[CONV_IS_NEW_KEY];
    NSNumber *status = snapshot.value[CONV_STATUS_KEY];
    NSMutableDictionary *attributes = snapshot.value[CONV_ATTRIBUTES_KEY];
    
    NSString *conversWith = nil;
    NSString *conversWithFullName = nil;
    if ([channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
        conversWith = recipient;
        conversWithFullName = recipientFullname;
    }
    else { // direct
        if ([me.userId isEqualToString:sender]) {
            conversWith = recipient;
            conversWithFullName = recipientFullname;
        }
        else {
            conversWith = sender;
            conversWithFullName = senderFullname;
        }
    }
    
    ChatConversation *conversation = [[ChatConversation alloc] init];
    conversation.key = snapshot.key;
    conversation.ref = snapshot.ref;
    conversation.conversationId = snapshot.key;
    conversation.last_message_text = text;
    conversation.recipient = recipient;
    conversation.recipientFullname = recipientFullname;
    conversation.sender = sender;
    conversation.senderFullname = senderFullname;
    conversation.date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue/1000];
    conversation.is_new = [is_new boolValue];
    conversation.conversWith = conversWith;
    conversation.conversWith_fullname = conversWithFullName;
    conversation.channel_type = channel_type;
//    conversation.groupId = groupId;
//    conversation.groupName = groupName;
    conversation.status = (int)[status integerValue];
    conversation.attributes = attributes;
    return conversation;
}

-(BOOL)isDirect {
//    NSLog(@"conv: %@, self.channel_type: %@",self.last_message_text, self.channel_type);
    return ([self.channel_type isEqualToString:MSG_CHANNEL_TYPE_DIRECT] || self.channel_type == nil) ? YES : NO;
}

@end
