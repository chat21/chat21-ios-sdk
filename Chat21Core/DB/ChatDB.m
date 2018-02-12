//
//  ChatDB.m
//  Soleto
//
//  Created by Andrea Sponziello on 05/12/14.
//
//

#import "ChatDB.h"
#import "ChatMessage.h"
#import "ChatConversation.h"
#import "ChatGroup.h"
#import "ChatUser.h"

static ChatDB *sharedInstance = nil;
//static sqlite3 *database = nil;
//static sqlite3_stmt *statement = nil;

@interface ChatDB () {
    sqlite3 *database;
    sqlite3_stmt *statement;
}
@end

@implementation ChatDB

+(ChatDB*)getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
        sharedInstance.logQuery = NO;
    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        self.logQuery = YES;
        database = nil;
        statement = nil;
    }
    return self;
}

// name only [a-zA-Z0-9_]
-(BOOL)createDBWithName:(NSString *)name {
    NSString *docsDir;
//    NSArray *dirPaths;
    // Get the documents directory
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    docsDir = dirPaths[0];
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    docsDir = [dirPaths lastObject];
    NSURL *urlPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    docsDir = urlPath.path;
    // Build the path to the database file
    NSString *db_name = nil;
    if (name) {
        db_name = [[NSString alloc] initWithFormat:@"%@_chat.db", name];
    }
    databasePath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent: db_name]];
    NSLog(@"Using chat database: %@", databasePath);
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    // **** TESTING ONLY ****
    // if you add another table or change an existing one you must (for the moment) drop the DB
//    [self drop_database];
    
//    if ([filemgr fileExistsAtPath: databasePath ] == NO) {
//        NSLog(@"Database %@ not exists. Creating...", databasePath);
//        const char *dbpath = [databasePath UTF8String];
    const char *dbpath = [databasePath UTF8String];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) {
        if (self.logQuery) {NSLog(@"Database %@ not exists. Creating...", databasePath);}
        int result;
        result = sqlite3_open_v2(dbpath, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL);
        if (result == SQLITE_OK) {
            char *errMsg;
            if (self.logQuery) {NSLog(@"**** CREATING TABLE MESSAGES...");}
            const char *sql_stmt_messages =
            "create table if not exists messages (messageId text primary key, conversationId text, text_body text, sender text, sender_fullname text, recipient text, status integer, timestamp real, type text, channel_type text, attributes text)";
            if (sqlite3_exec(database, sql_stmt_messages, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                if (self.logQuery) {NSLog(@"Failed to create table messages");}
            }
            else {
                if (self.logQuery) {NSLog(@"Table messages successfully created.");}
            }
            if (self.logQuery) {NSLog(@"**** CREATING TABLE CONVERSATIONS...");}
            const char *sql_stmt_conversations =
//            "create table if not exists conversations (conversationId text primary key, user text, sender text, sender_fullname, recipient text, last_message_text text, convers_with text, convers_with_fullname text, group_id text, group_name text, is_new integer, timestamp real, status integer, type text, channel_type text)";
            "create table if not exists conversations (conversationId text primary key, user text, sender text, sender_fullname, recipient text, recipient_fullname text, last_message_text text, convers_with text, convers_with_fullname text, is_new integer, timestamp real, status integer, channel_type text)";
            if (sqlite3_exec(database, sql_stmt_conversations, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                if (self.logQuery) {NSLog(@"Failed to create table conversations");}
            }
            else {
                if (self.logQuery) {NSLog(@"Table conversations successfully created.");}
            }
            sqlite3_close(database);
            return  isSuccess;
        }
        else {
            isSuccess = NO;
            if (self.logQuery) {NSLog(@"Failed to open/create database");}
        }
    } else {
        if (self.logQuery) {NSLog(@"Database %@ already exists. Opening.", databasePath);}
        if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
            return  isSuccess;
        }
        else {
            isSuccess = NO;
            if (self.logQuery) {NSLog(@"Failed to open database.");}
        }
    }
    return isSuccess;
}

// only for test
-(void)drop_database {
    if (self.logQuery) {NSLog(@"**** YOU DROPPED THE CHAT ARCHIVE: %@", databasePath);}
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: databasePath ] == YES) {
        if (self.logQuery) {NSLog(@"**** DROPPED DATABASE %@", databasePath);}
        NSError *error;
        [filemgr removeItemAtPath:databasePath error:&error];
        if (error){
            if (self.logQuery) {NSLog(@"%@", error);}
        }
    }
}

-(BOOL)insertMessageIfNotExists:(ChatMessage *)message {
    if (!message.conversationId) {
        if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT A CONVERSATION ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
        return false;
    }
    else if (!message.messageId) {
        if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT THE ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
        return false;
    }
    ChatMessage *message_is_present = [self getMessageById:message.messageId];
    if (message_is_present) {
        NSLog(@"Present. Not inserting.");
        return NO;
    }
    return [self insertMessage:message];
}

-(BOOL)insertMessage:(ChatMessage *)message {
    const char *dbpath = [databasePath UTF8String];
    double timestamp = (double)[message.date timeIntervalSince1970]; // NSTimeInterval is a (double)
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into messages (messageId, conversationId, sender, sender_fullname,  recipient, text_body, status, timestamp, type, channel_type, attributes) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", insertSQL);}
        sqlite3_prepare(database, [insertSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [message.messageId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [message.conversationId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [message.sender UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [message.senderFullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 5, [message.recipient UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 6, [message.text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 7, message.status);
        sqlite3_bind_double(statement, 8, timestamp);
        sqlite3_bind_text(statement, 9, [message.mtype UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 10, [message.channel_type UTF8String], -1, SQLITE_TRANSIENT);
        // convert attributes dictionary to JSON
        NSString * jsonAttributesAsString = nil;
        if (message.attributes) {
            NSError * err;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:message.attributes options:0 error:&err];
            jsonAttributesAsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        sqlite3_bind_text(statement, 11, [jsonAttributesAsString UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            if (self.logQuery) {NSLog(@"Insert message, database error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));}
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

-(BOOL)updateMessage:(NSString *)messageId withStatus:(int)status {
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE messages SET status = %d WHERE messageId = \"%@\"", status, messageId];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", updateSQL);}
        const char *update_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(database, update_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

static NSString *SELECT_FROM_MESSAGES_STATEMENT = @"select messageId, conversationId, sender, sender_fullname, recipient, text_body, status, timestamp, type, channel_type, attributes from messages ";

-(NSArray*)getAllMessages {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ order by timestamp desc limit 40", SELECT_FROM_MESSAGES_STATEMENT];
        if (self.logQuery) {NSLog(@"querySQL: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatMessage *message = [self messageFromStatement:statement];
                [messages addObject:message];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** getAllMessages. PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return messages;
}

-(NSArray*)getAllMessagesForConversation:(NSString *)conversationId start:(int)start count:(int)count {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ WHERE conversationId = \"%@\" order by timestamp desc limit %d,%d", SELECT_FROM_MESSAGES_STATEMENT, conversationId, start, count];
        if (self.logQuery) {NSLog(@"querySQL: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatMessage *message = [self messageFromStatement:statement];
                [messages addObject:message];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"getAllMessagesForConversation. **** PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return messages;
}

-(NSArray*)getAllMessagesForConversation:(NSString *)conversationId {
    NSArray *messages = [[ChatDB getSharedInstance] getAllMessagesForConversation:conversationId start:0 count:-1];
    return messages;
}

-(ChatMessage *)getMessageById:(NSString *)messageId {
    ChatMessage *message = nil;
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:@"%@ where messageId = \"%@\"",SELECT_FROM_MESSAGES_STATEMENT, messageId];
        if (self.logQuery) {NSLog(@"querySQL: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) { 
            while (sqlite3_step(statement) == SQLITE_ROW) {
                message = [self messageFromStatement:statement];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** getMessageById. PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return message;
}

-(ChatMessage *)messageFromStatement:(sqlite3_stmt *)statement {
    
    //NSString *messageId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
    const char* _messageId = (const char *) sqlite3_column_text(statement, 0);
    NSString *messageId = nil;
    if (_messageId) {
        messageId = [[NSString alloc] initWithUTF8String:_messageId];
    }
    
    //NSString *conversationId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
    const char* _conversationId = (const char *) sqlite3_column_text(statement, 1);
    NSString *conversationId = nil;
    if (_conversationId) {
        conversationId = [[NSString alloc] initWithUTF8String:_conversationId];
    }
    
    //NSString *sender = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
    const char* _sender = (const char *) sqlite3_column_text(statement, 2);
    NSString *sender = nil;
    if (_sender) {
        sender = [[NSString alloc] initWithUTF8String:_sender];
    }
    
    //NSString *senderFullname = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
    const char* _senderFullname = (const char *) sqlite3_column_text(statement, 3);
    NSString *senderFullname = nil;
    if (_senderFullname) {
        senderFullname = [[NSString alloc] initWithUTF8String:_senderFullname];
    }
    
    
    // group's messages have no recipient
    NSString *recipient = nil;
    const char *recipient_chars = (const char *) sqlite3_column_text(statement, 4);
    if (recipient_chars != NULL) {
        recipient = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
    }
    NSString *text = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
    int status = sqlite3_column_int(statement, 6);
    double timestamp = sqlite3_column_double(statement, 7);
    
    NSString *type = nil;
    const char *type_chars = (const char *) sqlite3_column_text(statement, 8);
    if (type_chars != NULL) {
        type = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
    }
    
    NSString *channel_type = nil;
    const char *channel_type_chars = (const char *) sqlite3_column_text(statement, 9);
    if (channel_type_chars != NULL) {
        channel_type = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 9)];
    }
    
    NSString *attributes_json = nil;
    const char *attributes_json_chars = (const char *) sqlite3_column_text(statement, 10);
    if (attributes_json_chars != NULL) {
        attributes_json = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 10)];
    }
    //NSString *attributes_json = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 9)];
    NSMutableDictionary *attributes = nil;
    NSLog(@"attributes_json: %@", attributes_json);
    if (attributes_json) {
        NSData *jsonData = [attributes_json dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error;
        attributes = [NSJSONSerialization
                                 JSONObjectWithData:jsonData
                                 options:kNilOptions
                                 error:&error];
    }
//    NSLog(@"MESSAGE DECODED:\nmessageId:%@\nconversationid:%@\nsender:%@\nrecipient:%@\ntext:%@\nstatus:%d\ntimestamp:%f\ntype:%@\nchannel_type:%@", messageId, conversationId, sender, recipient, text, status, timestamp, type, channel_type);
    ChatMessage *message = [[ChatMessage alloc] init];
    message.messageId = messageId;
    message.conversationId = conversationId;
    message.sender = sender;
    message.senderFullname = senderFullname;
    message.recipient = recipient;
    message.text = text;
    message.mtype = type;
    message.channel_type = channel_type;
    message.attributes = attributes;
    message.status = status;
    message.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    message.archived = YES;
    return message;
}

-(BOOL)removeAllMessagesForConversation:(NSString *)conversationId {
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM messages WHERE conversationId = \"%@\"", conversationId];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", sql);}
        const char *stmt = [sql UTF8String];
        sqlite3_prepare_v2(database, stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}





// CONVERSATIONS


-(BOOL)insertOrUpdateConversation:(ChatConversation *)conversation {
//    NSLog(@"insertOrUpdateConversation: %@ user: %@", conversation.conversationId, conversation.user);
    ChatConversation *conv_exists = [self getConversationById:conversation.conversationId];
    if (conv_exists) {
        //NSLog(@"CONVERSATION %@ EXISTS. UPDATING CONVERSATION... is_new: %d",conversation.conversationId, conversation.is_new);
        return [self updateConversation:conversation];
    }
    else {
//        NSLog(@"CONVERSATION IS NEW. INSERTING CONVERSATION...");
        return [self insertConversation:conversation];
    }
}

-(BOOL)insertConversation:(ChatConversation *)conversation {
        NSLog(@"**** insert query...");
    const char *dbpath = [databasePath UTF8String];
    double timestamp = (double)[conversation.date timeIntervalSince1970]; // NSTimeInterval is a (double)
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        
//        NSLog(@">>>> Conversation groupID %@ and groupNAME %@", conversation.groupId, conversation.groupName);
        // conversationId
        // user
        // sender
        // sender_fullname
        // recipient
        // recipient_fullname
        // last_message_text
        // convers_with
        // convers_with_fullname
        // is_new
        // timestamp
        // status
        // channel_type
        NSString *insertSQL = [NSString stringWithFormat:@"insert into conversations (conversationId, user, sender, sender_fullname, recipient, recipient_fullname, last_message_text, convers_with, convers_with_fullname, is_new, timestamp, status, channel_type) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];
        
        if (self.logQuery) {NSLog(@"**** QUERY:%@", insertSQL);}
        
        sqlite3_prepare(database, [insertSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [conversation.conversationId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [conversation.user UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [conversation.sender UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [conversation.senderFullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 5, [conversation.recipient UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 6, [conversation.recipientFullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 7, [conversation.last_message_text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 8, [conversation.conversWith UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 9, [conversation.conversWith_fullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 10, conversation.is_new);
        sqlite3_bind_double(statement, 11, timestamp);
        sqlite3_bind_int(statement, 12, conversation.status);
        sqlite3_bind_text(statement, 13, [conversation.channel_type UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"QUERY INSERT OK.");
            NSLog(@"Conversation successfully inserted.");
            ChatConversation *conv = [self getConversationById:conversation.conversationId];
            NSLog(@"**** AFTER: CONV SENDER: %@", conv.sender);
            sqlite3_reset(statement);
            return YES;
        }
        else {
            NSLog(@"Error on insertConversation.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

// NOTE: fields "conversationId", "user" and "convers_with" are "invariant" and not updated.
-(BOOL)updateConversation:(ChatConversation *)conversation {
//    ChatConversation *previous_conv = [self getConversationById:conversation.conversationId]; // TEST ONLY QUERY
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        double timestamp = (double)[conversation.date timeIntervalSince1970]; // NSTimeInterval is a (double)
        
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE conversations SET sender = ?, sender_fullname = ?, recipient = ?, recipient_fullname = ?, convers_with_fullname = ?, last_message_text = ?, is_new = ?, timestamp = ?, status = ? WHERE conversationId = ?"];
        if (self.logQuery) {NSLog(@"QUERY:%@", updateSQL);}
        
        sqlite3_prepare(database, [updateSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [conversation.sender UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [conversation.senderFullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [conversation.recipient UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [conversation.recipientFullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 5, [conversation.conversWith_fullname UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 6, [conversation.last_message_text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 7, conversation.is_new);
        sqlite3_bind_double(statement, 8, timestamp);
        sqlite3_bind_int(statement, 9, conversation.status);
        sqlite3_bind_text(statement, 10, [conversation.conversationId UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            NSLog(@"Error while updating conversation. Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

static NSString *SELECT_FROM_STATEMENT = @"SELECT conversationId, user, sender, sender_fullname, recipient, recipient_fullname, last_message_text, convers_with, convers_with_fullname, channel_type, is_new, timestamp, status FROM conversations ";

- (NSArray*)getAllConversations {
    NSMutableArray *convs = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ order by timestamp desc", SELECT_FROM_STATEMENT]; // limit 40?
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatConversation *conv = [self conversationFromStatement:statement];
                [convs addObject:conv];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return convs;
}

- (NSArray*)getAllConversationsForUser:(NSString *)user {
    NSMutableArray *convs = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ WHERE user = \"%@\" order by timestamp desc", SELECT_FROM_STATEMENT, user];
        if (self.logQuery) {NSLog(@"QUERY: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatConversation *conv = [self conversationFromStatement:statement];
//                NSLog(@"convesend %@", conv.sender);
                [convs addObject:conv];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return convs;
}

- (ChatConversation *)getConversationById:(NSString *)conversationId {
    ChatConversation *conv = nil;
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"%@ where conversationId = \"%@\"",SELECT_FROM_STATEMENT, conversationId];
        if (self.logQuery) {NSLog(@"*** QUERY: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                conv = [self conversationFromStatement:statement];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return conv;
}

-(BOOL)removeConversation:(NSString *)conversationId {
    //    NSLog(@"**** remove query...");
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM conversations WHERE conversationId = \"%@\"", conversationId];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", sql);}
        const char *stmt = [sql UTF8String];
        sqlite3_prepare_v2(database, stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            NSLog(@"Error on removeConversation.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}


-(ChatConversation *)conversationFromStatement:(sqlite3_stmt *)statement {
    const char* _conversationId = (const char *) sqlite3_column_text(statement, 0);
    NSString *conversationId = nil;
    if (_conversationId) {
        conversationId = [[NSString alloc] initWithUTF8String:_conversationId];
    }
    
    const char* _user = (const char *) sqlite3_column_text(statement, 1);
    NSString *user = nil;
    if (_user) {
        user = [[NSString alloc] initWithUTF8String:_user];
    }
    
    const char* _sender = (const char *) sqlite3_column_text(statement, 2);
//    NSLog(@">>>>>>>>>>> sender = %s", _sender);
    NSString *sender = nil;
    if (_sender) {
        sender = [[NSString alloc] initWithUTF8String:_sender];
    }
    
    const char* _senderFullname = (const char *) sqlite3_column_text(statement, 3);
    //    NSLog(@">>>>>>>>>>> senderFullname = %s", _senderFullname);
    NSString *senderFullname = nil;
    if (_senderFullname) {
        senderFullname = [[NSString alloc] initWithUTF8String:_senderFullname];
    }
    
    const char* _recipient = (const char *) sqlite3_column_text(statement, 4);
    NSString *recipient = nil;
    if (_recipient) {
        recipient = [[NSString alloc] initWithUTF8String:_recipient];
    }
    
    const char* _recipient_fullname = (const char *) sqlite3_column_text(statement, 5);
    NSString *recipient_fullname = nil;
    if (_recipient_fullname) {
        recipient_fullname = [[NSString alloc] initWithUTF8String:_recipient_fullname];
    }
    
    const char* _last_message_text = (const char *) sqlite3_column_text(statement, 6);
//    NSLog(@">>>>>>>>>>> last_message_text = %s", _last_message_text);
    NSString *last_message_text = nil;
    if (_last_message_text) {
        last_message_text = [[NSString alloc] initWithUTF8String:_last_message_text];
    }
    
    const char* _convers_with = (const char *) sqlite3_column_text(statement, 7);
//    NSLog(@">>>>>>>>>>> convers_with = %s", _convers_with);
    NSString *convers_with = nil;
    if (_convers_with) {
        convers_with = [[NSString alloc] initWithUTF8String:_convers_with];
    }
    
    const char* _convers_with_fullname = (const char *) sqlite3_column_text(statement, 8);
//    NSLog(@">>>>>>>>>>> _convers_with_fullname = %s", _convers_with_fullname);
    NSString *convers_with_fullname = nil;
    if (_convers_with_fullname) {
        convers_with_fullname = [[NSString alloc] initWithUTF8String:_convers_with_fullname];
    }
    
    const char* _channel_type = (const char *) sqlite3_column_text(statement, 9);
    NSString *channel_type = nil;
    if (_channel_type) {
        channel_type = [[NSString alloc] initWithUTF8String:_channel_type];
    }
    
    BOOL is_new = sqlite3_column_int(statement, 10);
    double timestamp = sqlite3_column_double(statement, 11);
    int status = sqlite3_column_int(statement, 12);
    
    ChatConversation *conv = [[ChatConversation alloc] init];
    conv.conversationId = conversationId;
    conv.user = user;
    conv.sender = sender;
    conv.senderFullname = senderFullname;
    conv.recipient = recipient;
    conv.recipientFullname = recipient_fullname;
    conv.last_message_text = last_message_text;
    conv.conversWith = convers_with;
    conv.conversWith_fullname = convers_with_fullname;
    conv.channel_type = channel_type;
    conv.is_new = is_new;
    conv.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    conv.status = status;
    
    return conv;
}

// CONVERSATIONS END

@end
