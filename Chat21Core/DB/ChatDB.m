//
//  ChatDB.m
//
//  Created by Andrea Sponziello on 05/12/14.
//
//

#import "ChatDB.h"
#import "ChatMessage.h"
#import "ChatConversation.h"
#import "ChatGroup.h"
#import "ChatUser.h"
#import "ChatMessageMetadata.h"

static ChatDB *sharedInstance = nil;
//static sqlite3 *database = nil;
//static sqlite3_stmt *statement = nil;

@interface ChatDB () {
    dispatch_queue_t serialDatabaseQueue;
    sqlite3 *database;
    sqlite3_stmt *statement;
}
@end

@implementation ChatDB

+(ChatDB*)getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
        sharedInstance.logQuery = YES;
    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        serialDatabaseQueue = dispatch_queue_create("db_messages_conversations.sqllite", DISPATCH_QUEUE_SERIAL);
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
    const char *dbpath = [databasePath UTF8String];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) {
        if (self.logQuery) {NSLog(@"Database %@ not exists. Creating...", databasePath);}
        int result;
        result = sqlite3_open_v2(dbpath, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL);
        if (result == SQLITE_OK) {
            char *errMsg;
            if (self.logQuery) {NSLog(@"**** CREATING TABLE MESSAGES...");}
            // added > media:BOOL, document:BOOL, link:BOOL
            const char *sql_stmt_messages =
            "create table if not exists messages (messageId text primary key, conversationId text, text_body text, sender text, recipient text, status integer, timestamp real, type text, channel_type text, snapshot text, media integer, document integer, link integer)";
            if (sqlite3_exec(database, sql_stmt_messages, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                if (self.logQuery) {NSLog(@"Failed to create table messages");}
            }
            else {
                if (self.logQuery) {NSLog(@"Table messages successfully created.");}
            }
            if (self.logQuery) {NSLog(@"**** CREATING TABLE CONVERSATIONS...");}
            const char *sql_stmt_conversations =
            "create table if not exists conversations (conversationId text primary key, user text, sender text, sender_fullname, recipient text, recipient_fullname text, last_message_text text, convers_with text, convers_with_fullname text, is_new integer, timestamp real, status integer, channel_type text, snapshot text)";
            if (sqlite3_exec(database, sql_stmt_conversations, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                if (self.logQuery) {NSLog(@"Failed to create table conversations");}
            }
            else {
                if (self.logQuery) {NSLog(@"Table conversations successfully created.");}
                [self upgradeSchema:dbpath];
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
            [self upgradeSchema:dbpath];
            return  isSuccess;
        }
        else {
            isSuccess = NO;
            if (self.logQuery) {NSLog(@"Failed to open database.");}
        }
    }
    return isSuccess;
}

-(void)upgradeSchema:(const char *)dbpath {
    // version schema
    // or test if the column exists
    // https://stackoverflow.com/questions/3604310/alter-table-add-column-if-not-exists-in-sqlite
    if (self.logQuery) {NSLog(@"Upgrading schema");}
    int result;
    result = sqlite3_open_v2(dbpath, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL);
    if (result == SQLITE_OK) {
        if (self.logQuery) {NSLog(@"**** UPGRADING TABLE conversations...");}
        
        if (self.logQuery) {NSLog(@"alter table conversations add column archived integer");}
        char *errMsg;
        const char *sql_stmt_alter =
        "alter table conversations add column archived integer";
        if (sqlite3_exec(database, sql_stmt_alter, NULL, NULL, &errMsg) != SQLITE_OK) {
            if (self.logQuery) {NSLog(@"Failed to alter table conversations (adding column 'archived integer')");}
        }
        else {
            if (self.logQuery) {NSLog(@"Table conversations successfully altered (added 'archived integer').");}
        }
        
        if (self.logQuery) {NSLog(@"alter table conversations add column snapshot text");}
        sql_stmt_alter =
        "alter table conversations add column snapshot text";
        if (sqlite3_exec(database, sql_stmt_alter, NULL, NULL, &errMsg) != SQLITE_OK) {
            if (self.logQuery) {NSLog(@"Failed to alter table conversations (adding column 'snapshot text')");}
        }
        else {
            if (self.logQuery) {NSLog(@"Table conversations successfully altered (added 'snapshot text').");}
        }
        
        sqlite3_close(database);
    }
    else {
        if (self.logQuery) {NSLog(@"Failed to alter table messages.");}
    }
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

-(void)insertMessageIfNotExistsSyncronized:(ChatMessage *)message completion:(void(^)(void)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        if (!message.conversationId) {
            if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT A CONVERSATION ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
            callback();
        }
        else if (!message.messageId) {
            if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT THE ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
            callback();
        }
        [self getMessageByIdSyncronized:message.messageId completion:^(ChatMessage *message_is_present) {
            if (message_is_present) {
                if (self.logQuery) {NSLog(@"Present. Not inserting.");}
                callback();
            }
            else {
                [self insertMessage:message];
                callback();
            }
        }];
    });
}

//-(void)insertMessageIfNotExists:(ChatMessage *)message {
//    if (!message.conversationId) {
//        if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT A CONVERSATION ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
//        return;
//    }
//    else if (!message.messageId) {
//        if (self.logQuery) {NSLog(@"ERROR: CAN'T INSERT A MESSAGE WITHOUT THE ID. MESSAGE ID: %@ MESSAGE TEXT: %@ MESSAGE CONVID: %@", message.messageId, message.text, message.conversationId);}
//        return;
//    }
//    ChatMessage *message_is_present = [self getMessageById:message.messageId];
//    if (message_is_present) {
//        if (self.logQuery) {NSLog(@"Present. Not inserting.");}
//        return;
//    }
//    [self insertMessage:message];
//    return;
//}

-(BOOL)insertMessage:(ChatMessage *)message {
    const char *dbpath = [databasePath UTF8String];
    double timestamp = (double)[message.date timeIntervalSince1970]; // NSTimeInterval is a (double)
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into messages (messageId, conversationId, sender, recipient, text_body, status, timestamp, type, channel_type, snapshot, media, document, link) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", insertSQL);}
        sqlite3_prepare(database, [insertSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [message.messageId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [message.conversationId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [message.sender UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [message.recipient UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 5, [message.text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 6, message.status);
        sqlite3_bind_double(statement, 7, timestamp);
        sqlite3_bind_text(statement, 8, [message.mtype UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 9, [message.channel_type UTF8String], -1, SQLITE_TRANSIENT);
        NSString *snapshotAsJSONString = message.snapshotAsJSONString;
        sqlite3_bind_text(statement, 10, [snapshotAsJSONString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 11, message.media);
        sqlite3_bind_int(statement, 12, message.document);
        sqlite3_bind_int(statement, 13, message.link);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return YES;
        }
        else {
            if (self.logQuery) {NSLog(@"Insert message, database error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));}
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return NO;
        }
    }
    sqlite3_close(database);
    return NO;
}

-(void)updateMessageSynchronized:(NSString *)messageId withStatus:(int)status completion:(void(^)(void)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        [self updateMessage:messageId withStatus:status];
        if (callback != nil) {
            callback();
        }
    });
}

-(void)updateMessage:(NSString *)messageId withStatus:(int)status {
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE messages SET status = %d WHERE messageId = \"%@\"", status, messageId];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", updateSQL);}
        const char *update_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(database, update_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return;
        }
        else {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return;
        }
    }
    sqlite3_close(database);
    return;
}

-(BOOL)updateMessage:(NSString *)messageId status:(int)status text:(NSString *)text snapshotAsJSONString:(NSString *)snapshotAsJSONString {
    const char *dbpath = [databasePath UTF8String];
    if (self.logQuery) {NSLog(@"snapshot: %@", snapshotAsJSONString);}
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *updateSQL = @"UPDATE messages SET status = ?, snapshot = ?, text_body = ? WHERE messageId = ?";
        if (self.logQuery) {NSLog(@"**** QUERY:%@", updateSQL);}
        sqlite3_prepare(database, [updateSQL UTF8String], -1, &statement, NULL);
        sqlite3_bind_int(statement, 1, status);
        sqlite3_bind_text(statement, 2, [snapshotAsJSONString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [messageId UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return YES;
        }
        else {
            if (self.logQuery) {NSLog(@"Update message status/imageURL, database error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));}
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return NO;
        }
    }
    sqlite3_close(database);
    return NO;
}

static NSString *SELECT_FROM_MESSAGES_STATEMENT = @"select messageId, conversationId, sender, recipient, text_body, status, timestamp, type, channel_type, snapshot from messages ";

-(NSArray*)getAllMessages {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ order by timestamp desc limit 200", SELECT_FROM_MESSAGES_STATEMENT];
        if (self.logQuery) {NSLog(@"querySQL: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatMessage *message = [self messageFromStatement:statement];
                [messages addObject:message];
            }
            sqlite3_finalize(statement);
            sqlite3_close(database);
        } else {
            NSLog(@"**** getAllMessages. PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
    }
    sqlite3_close(database);
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
            sqlite3_finalize(statement);
            sqlite3_close(database);
        } else {
            NSLog(@"getAllMessagesForConversation. **** PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
    }
    sqlite3_close(database);
    return messages;
}

-(NSArray*)getAllMessagesForConversation:(NSString *)conversationId {
    NSArray *messages = [[ChatDB getSharedInstance] getAllMessagesForConversation:conversationId start:0 count:-1];
    return messages;
}

-(void)getMessageByIdSyncronized:(NSString *)messageId completion:(void(^)(ChatMessage *)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        ChatMessage *message = [self getMessageById:messageId];
        if (callback != nil) {
            callback(message);
        }
    });
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
            sqlite3_finalize(statement);
            sqlite3_close(database);
        } else {
            NSLog(@"**** getMessageById. PROBLEMS WHILE QUERYING MESSAGES...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
    }
    sqlite3_close(database);
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
    
    // group's messages have no recipient
    NSString *recipient = nil;
    const char *recipient_chars = (const char *) sqlite3_column_text(statement, 3);
    if (recipient_chars != NULL) {
        recipient = [[NSString alloc] initWithUTF8String:recipient_chars];
    }
    
    NSString *text = nil;
    const char *text_chars = (const char *) sqlite3_column_text(statement, 4);
    if (text_chars != NULL) {
        text = [[NSString alloc] initWithUTF8String:text_chars];
    }
    
    int status = sqlite3_column_int(statement, 5);
    
    double timestamp = sqlite3_column_double(statement, 6);
    
    NSString *type = nil;
    const char *type_chars = (const char *) sqlite3_column_text(statement, 7);
    if (type_chars != NULL) {
        type = [[NSString alloc] initWithUTF8String:type_chars];
    }
    
    NSString *channel_type = nil;
    const char *channel_type_chars = (const char *) sqlite3_column_text(statement, 8);
    if (channel_type_chars != NULL) {
        channel_type = [[NSString alloc] initWithUTF8String:channel_type_chars];
    }
    
    NSMutableDictionary *snapshot = nil;
    const char *snapshot_json_chars = (const char *) sqlite3_column_text(statement, 9);
    if (snapshot_json_chars != NULL) {
        NSString *snapshot_json = nil;
        snapshot_json = [[NSString alloc] initWithUTF8String:snapshot_json_chars];
        if (snapshot_json) {
            NSData *jsonData = [snapshot_json dataUsingEncoding:NSUTF8StringEncoding];
            NSError* error;
            snapshot = [NSJSONSerialization
                        JSONObjectWithData:jsonData
                        options:kNilOptions
                        error:&error];
        }
    }
    
    ChatMessage *message = [[ChatMessage alloc] init];
    message.messageId = messageId;
    message.conversationId = conversationId;
    message.sender = sender;
    message.recipient = recipient;
    message.text = text;
    message.mtype = type;
    message.channel_type = channel_type;
    message.status = status;
    message.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    message.archived = YES;
    
    message.snapshot = snapshot;
    message.subtype = snapshot[MSG_FIELD_SUBTYPE];
    message.senderFullname = snapshot[MSG_FIELD_SENDER_FULLNAME];
    message.recipientFullName = snapshot[MSG_FIELD_RECIPIENT_FULLNAME];
    message.lang = snapshot[MSG_FIELD_LANG];
    message.attributes = snapshot[MSG_FIELD_ATTRIBUTES];
    NSDictionary *metadata = snapshot[MSG_FIELD_METADATA];
    message.metadata = [ChatMessageMetadata fromDictionaryFactory:metadata];
    
    return message;
}

-(void)removeAllMessagesForConversationSynchronized:(NSString *)conversationId completion:(void(^)(void)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        [self removeAllMessagesForConversation:conversationId];
        if (callback != nil) callback();
    });
}

-(void)removeAllMessagesForConversation:(NSString *)conversationId {
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM messages WHERE conversationId = \"%@\"", conversationId];
        if (self.logQuery) {NSLog(@"**** QUERY:%@", sql);}
        const char *stmt = [sql UTF8String];
        sqlite3_prepare_v2(database, stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return;
        }
        else {
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return;
        }
    }
    sqlite3_close(database);
    return;
}

// ***********************
// **** CONVERSATIONS ****
// ***********************

-(void)insertOrUpdateConversationSyncronized:(ChatConversation *)conversation completion:(void(^)(void)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        [self getConversationByIdSynchronized:conversation.conversationId completion:^(ChatConversation *conv_exists) {
            if (conv_exists) {
                [self updateConversation:conversation];
                callback();
            }
            else {
                [self insertConversation:conversation];
                callback();
            }
        }];
    });
        
        
//        [self getMessageByIdSyncronized:message.messageId completion:^(ChatMessage *message_is_present) {
//            if (message_is_present) {
//                if (self.logQuery) {NSLog(@"Present. Not inserting.");}
//                callback();
//            }
//            else {
//                [self insertMessage:message];
//                callback();
//            }
//        }];
//    });
}

//-(BOOL)insertOrUpdateConversation:(ChatConversation *)conversation {
//    ChatConversation *conv_exists = [self getConversationById:conversation.conversationId];
//    if (conv_exists) {
//        return [self updateConversation:conversation];
//    }
//    else {
//        return [self insertConversation:conversation];
//    }
//}

-(BOOL)insertConversation:(ChatConversation *)conversation {
    const char *dbpath = [databasePath UTF8String];
    double timestamp = (double)[conversation.date timeIntervalSince1970]; // NSTimeInterval is a (double)
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into conversations (conversationId, user, sender, sender_fullname, recipient, recipient_fullname, last_message_text, convers_with, convers_with_fullname, is_new, timestamp, status, channel_type, archived, snapshot) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"];

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
        sqlite3_bind_int(statement, 14, conversation.archived);
        NSString *snapshotAsJSONString = conversation.snapshotAsJSONString;
        sqlite3_bind_text(statement, 15, [snapshotAsJSONString UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"Conversation successfully inserted.");
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return YES;
        }
        else {
            NSLog(@"Error on insertConversation.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return NO;
        }
    }
    sqlite3_close(database);
    return NO;
}

// NOTE: fields "conversationId", "user" and "convers_with" are "invariant" and never updated.
-(BOOL)updateConversation:(ChatConversation *)conversation {
//    ChatConversation *previous_conv = [self getConversationById:conversation.conversationId]; // TEST ONLY QUERY
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        double timestamp = (double)[conversation.date timeIntervalSince1970]; // NSTimeInterval is a (double)
        
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE conversations SET sender = ?, sender_fullname = ?, recipient = ?, recipient_fullname = ?, convers_with_fullname = ?, last_message_text = ?, is_new = ?, timestamp = ?, status = ?, archived = ?, snapshot = ? WHERE conversationId = ?"];
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
        sqlite3_bind_int(statement, 10, conversation.archived);
        NSString *snapshotAsJSONString = conversation.snapshotAsJSONString;
        sqlite3_bind_text(statement, 11, [snapshotAsJSONString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 12, [conversation.conversationId UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_finalize(statement);
            sqlite3_close(database);
//            [self printAllConversations:@"cQ1jxD2SBzROcpBJtMKGepbk3bw1"];
            return YES;
        }
        else {
            NSLog(@"Error while updating conversation. Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return NO;
        }
    }
    sqlite3_close(database);
    return NO;
}

static NSString *SELECT_FROM_CONVERSATIONS_STATEMENT = @"SELECT conversationId, user, sender, sender_fullname, recipient, recipient_fullname, last_message_text, convers_with, convers_with_fullname, channel_type, is_new, timestamp, status, archived, snapshot FROM conversations ";

- (NSArray*)getAllConversations {
    NSMutableArray *convs = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ order by timestamp desc", SELECT_FROM_CONVERSATIONS_STATEMENT]; // limit 40?
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatConversation *conv = [self conversationFromStatement:statement];
                [convs addObject:conv];
            }
            sqlite3_finalize(statement);
            sqlite3_close(database);
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
    }
    sqlite3_close(database);
    return convs;
}

- (NSArray*)getAllConversationsForUser:(NSString *)user archived:(BOOL)archived limit:(int)limit {
    NSMutableArray *convs = [[NSMutableArray alloc] init];
    NSString *limit_query = limit == 0 ? @"" : [[NSString alloc] initWithFormat:@" limit %d", limit];
    int _archived = (int)archived;
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ WHERE user = \"%@\" and archived = %d order by timestamp desc%@", SELECT_FROM_CONVERSATIONS_STATEMENT, user, _archived, limit_query];
        if (self.logQuery) {NSLog(@"getAllConversationsForUser.QUERY: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatConversation *conv = [self conversationFromStatement:statement];
                [convs addObject:conv];
            }
            sqlite3_finalize(statement);
            sqlite3_close(database);
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
        }
    }
    sqlite3_close(database);
//    NSLog(@"***** CONVERSATIONS DUMP **************************");
//    for (ChatConversation *c in convs) {
//        NSLog(@"text: %@, id: %@, user: %@ date: %@",c.last_message_text, c.conversationId, c.user, c.date);
//    }
//    NSLog(@"******************************* END.");
    return convs;
}

-(void)printAllConversations:(NSString *)user {
    NSLog(@"***** CONVERSATIONS DUMP **************************");
    NSMutableArray *conversations = [[[ChatDB getSharedInstance] getAllConversationsForUser:user archived:NO limit:60] mutableCopy];
    for (ChatConversation *c in conversations) {
        NSLog(@"text: %@, id: %@, user: %@ date: %@",c.last_message_text, c.conversationId, c.user, c.date);
    }
    NSLog(@"******************************* END.");
}

- (void)getConversationByIdSynchronized:(NSString *)conversationId completion:(void(^)(ChatConversation *)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        ChatConversation *conv = [self getConversationById:conversationId];
        if (callback != nil) {
            callback(conv);
        }
    });
}

- (ChatConversation *)getConversationById:(NSString *)conversationId {
    ChatConversation *conv = nil;
    const char *dbpath = [databasePath UTF8String];
//    NSLog(@"database: %@ dbpath %s", database, dbpath);
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"%@ where conversationId = \"%@\"",SELECT_FROM_CONVERSATIONS_STATEMENT, conversationId];
        if (self.logQuery) {NSLog(@"*** QUERY: %@", querySQL);}
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                conv = [self conversationFromStatement:statement];
            }
        } else {
            NSLog(@"**** ERROR: PROBLEMS WHILE QUERYING CONVERSATIONS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    return conv;
}

- (void)removeConversationSynchronized:(NSString *)conversationId completion:(void(^)(void)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        [self removeConversation:conversationId];
        if (callback != nil) callback();
    });
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
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return YES;
        }
        else {
            NSLog(@"Error on removeConversation.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return NO;
        }
    }
    sqlite3_close(database);
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
    BOOL archived = sqlite3_column_int(statement, 13);
    
    NSMutableDictionary *snapshot = nil;
    const char *snapshot_json_chars = (const char *) sqlite3_column_text(statement, 14);
    if (snapshot_json_chars != NULL) {
        NSString *snapshot_json = nil;
        snapshot_json = [[NSString alloc] initWithUTF8String:snapshot_json_chars];
        if (snapshot_json) {
            NSData *jsonData = [snapshot_json dataUsingEncoding:NSUTF8StringEncoding];
            NSError* error;
            snapshot = [NSJSONSerialization
                        JSONObjectWithData:jsonData
                        options:kNilOptions
                        error:&error];
        }
    }
    
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
    conv.archived = archived;
    
    conv.snapshot = snapshot;
    conv.mtype = snapshot[MSG_FIELD_TYPE];
    conv.attributes = snapshot[MSG_FIELD_ATTRIBUTES];
    
    return conv;
}

// CONVERSATIONS END

@end
