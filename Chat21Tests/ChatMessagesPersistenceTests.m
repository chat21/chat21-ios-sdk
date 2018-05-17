//
//  ChatMessagesPersistenceTests.m
//  chat21
//
//  Created by Andrea Sponziello on 16/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ChatMessage.h"
#import "ChatDB.h"
#import "ChatMessageMetadata.h"

@interface ChatMessagesPersistenceTests : XCTestCase

@end

@implementation ChatMessagesPersistenceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(ChatMessage *)textMessage {
    ChatMessage *message = [[ChatMessage alloc] init];
    NSString * messageId = [[NSUUID UUID] UUIDString];
    message.messageId = messageId;
    message.sender = @"sender";
    message.senderFullname = @"Sender Full Name";
    message.recipient = @"recipient";
    message.recipientFullName = @"Recipient Full Name";
    message.text = @"Text message";
    NSDate *now = [[NSDate alloc] init];
    message.date = now;
    message.status = MSG_STATUS_SENDING;
    message.conversationId = message.recipient;
    message.lang = @"it";
    return message;
}

- (void)testSaveTextMessage {
    ChatMessage *message = [self textMessage];
    message.mtype = MSG_TYPE_TEXT;
    message.subtype = @"test subtype";
    message.channel_type = MSG_CHANNEL_TYPE_DIRECT;
    // save
    ChatDB *db = [ChatDB getSharedInstance];
    [db insertMessageIfNotExists:message];
    // retrive
    ChatMessage *message_from_db = [db getMessageById:message.messageId];
    XCTAssertTrue([message_from_db.messageId isEqualToString:message.messageId]);
    XCTAssertTrue([message_from_db.sender isEqualToString:message.sender]);
    XCTAssertTrue([message_from_db.senderFullname isEqualToString:message.senderFullname]);
    XCTAssertTrue([message_from_db.recipient isEqualToString:message.recipient]);
    XCTAssertTrue([message_from_db.recipientFullName isEqualToString:message.recipientFullName]);
    XCTAssertTrue([message_from_db.text isEqualToString:message.text]);
//    XCTAssertTrue([message_from_db.date timeIntervalSinceDate:message.date] == 0.000000);
    XCTAssertTrue(message_from_db.date.timeIntervalSince1970 == message.date.timeIntervalSince1970);
    XCTAssertTrue(message_from_db.status == message.status);
    XCTAssertTrue([message_from_db.conversationId isEqualToString:message.conversationId]);
    XCTAssertTrue([message_from_db.lang isEqualToString:message.lang]);
    XCTAssertTrue(message_from_db.archived == true);
    XCTAssertTrue([message_from_db.mtype isEqualToString:message.mtype]);
    XCTAssertTrue([message_from_db.subtype isEqualToString:message.subtype]);
    XCTAssertTrue([message_from_db.channel_type isEqualToString:message.channel_type]);
}

- (void)testSaveImageMessage {
    ChatMessage *message = [self textMessage];
    message.mtype = MSG_TYPE_IMAGE;
    message.subtype = @"test subtype";
    message.channel_type = MSG_CHANNEL_TYPE_DIRECT;
//    message.imageURL = @"http://testimageurl";
    message.metadata.src = @"http://testimageurl";
    message.imageFilename = @"image-test-filename.png";
    // save
    ChatDB *db = [ChatDB getSharedInstance];
    [db insertMessageIfNotExists:message];
    // retrive
    ChatMessage *message_from_db = [db getMessageById:message.messageId];
    XCTAssertTrue([message_from_db.messageId isEqualToString:message.messageId]);
    XCTAssertTrue([message_from_db.sender isEqualToString:message.sender]);
    XCTAssertTrue([message_from_db.senderFullname isEqualToString:message.senderFullname]);
    XCTAssertTrue([message_from_db.recipient isEqualToString:message.recipient]);
    XCTAssertTrue([message_from_db.recipientFullName isEqualToString:message.recipientFullName]);
    XCTAssertTrue([message_from_db.text isEqualToString:message.text]);
    XCTAssertTrue(message_from_db.date.timeIntervalSince1970 == message.date.timeIntervalSince1970);
    XCTAssertTrue(message_from_db.status == message.status);
    XCTAssertTrue([message_from_db.conversationId isEqualToString:message.conversationId]);
    XCTAssertTrue([message_from_db.lang isEqualToString:message.lang]);
    XCTAssertTrue(message_from_db.archived == true);
    XCTAssertTrue([message_from_db.mtype isEqualToString:message.mtype]);
    XCTAssertTrue([message_from_db.subtype isEqualToString:message.subtype]);
    XCTAssertTrue([message_from_db.channel_type isEqualToString:message.channel_type]);
    XCTAssertTrue([message_from_db.metadata.src isEqualToString:message.metadata.src]);
    XCTAssertTrue([message_from_db.imageFilename isEqualToString:message.imageFilename]);
}

@end
