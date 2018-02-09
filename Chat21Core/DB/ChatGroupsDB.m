//
//  ChatGroupsDB.m
//  bppmobile
//
//  Created by Andrea Sponziello on 26/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatGroupsDB.h"
#import "ChatGroup.h"

static ChatGroupsDB *sharedInstance = nil;
//static sqlite3 *database = nil;
//static sqlite3_stmt *statement = nil;

@interface ChatGroupsDB () {
    dispatch_queue_t serialDatabaseQueue;
    sqlite3 *database;
    sqlite3_stmt *statement;
}
@end

@implementation ChatGroupsDB

+(ChatGroupsDB *)getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        serialDatabaseQueue = dispatch_queue_create("db.groups.sqllite", DISPATCH_QUEUE_SERIAL);
        self.logQuery = YES;
        database = nil;
        statement = nil;
    }
    return self;
}

// name only [a-zA-Z0-9_]
-(BOOL)createDBWithName:(NSString *)name {
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    NSString *db_name = nil;
    if (name) {
        db_name = [[NSString alloc] initWithFormat:@"%@_groups.db", name];
    }
    databasePath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent: db_name]];
    NSLog(@"Using groups database: %@", databasePath);
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    
    // **** TESTING ONLY ****
    // if you add another table or change an existing one you must (for the moment) drop the DB
//    [self drop_database];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) {
        NSLog(@"Database %@ not exists. Creating...", databasePath);
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
            char *errMsg;
            
            if (self.logQuery) {NSLog(@"**** CREATING TABLE GROUPS...");}
            
            
            const char *sql_stmt_groups =
            "create table if not exists groups (groupId text primary key, user text, groupName text, owner text, members text, createdOn real)";
            if (sqlite3_exec(database, sql_stmt_groups, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create table groups");
            }
            else {
                NSLog(@"Table groups successfully created.");
            }
            
            sqlite3_close(database);
            return  isSuccess;
        }
        else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
    } else {
        NSLog(@"Database %@ already exists.", databasePath);
    }
    return isSuccess;
}

// only for test
-(void)drop_database {
    NSLog(@"**** YOU DROPPED DB: %@", databasePath);
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: databasePath ] == YES) {
        NSLog(@"**** DROP DATABASE %@", databasePath);
        NSLog(@"**** DATABASE DROPPED.");
        NSError *error;
        [filemgr removeItemAtPath:databasePath error:&error];
        if (error){
            NSLog(@"%@", error);
        }
    }
}


-(void)insertOrUpdateGroupSyncronized:(ChatGroup *)group completion:(void(^)()) callback {
    dispatch_async(serialDatabaseQueue, ^{
        //    NSLog(@"....GROUP NAME: %@", group.name);
//        [self getGroupByIdSyncronized:group.groupId completion:^(ChatGroup *exists) {
//            if (exists) {
//                NSLog(@"GROUP %@/%@ EXISTS. UPDATING...", group.groupId, group.name);
//                [self updateGroup:group];
//            }
//            else {
//                NSLog(@"GROUP %@/%@ IS NEW. INSERTING GROUP...", group.groupId, group.name);
//                [self insertGroup:group];
//            }
//        }];
        ChatGroup *exists = [self getGroupById:group.groupId];
        if (exists) {
            NSLog(@"GROUP %@/%@ EXISTS. UPDATING...", group.groupId, group.name);
            [self updateGroup:group];
            callback();
        }
        else {
            NSLog(@"GROUP %@/%@ IS NEW. INSERTING GROUP...", group.groupId, group.name);
            [self insertGroup:group];
            callback();
        }
    });
}

-(BOOL)insertGroup:(ChatGroup *)group {
    NSLog(@"**** insert query...");
    const char *dbpath = [databasePath UTF8String];
    double createdOn = (double)[group.createdOn timeIntervalSince1970]; // NSTimeInterval is a (double)
    NSString *members = [ChatGroup membersDictionary2String:group.members];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        
        NSLog(@">>>> Inserting group %@", group.name);
        NSString *insertSQL = [NSString stringWithFormat:@"insert into groups (groupId, user, groupName, owner, members, createdOn) values (?, ?, ?, ?, ?, ?)"];
        
        if (self.logQuery) {NSLog(@"**** QUERY:%@", insertSQL);}
        
        sqlite3_prepare(database, [insertSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [group.groupId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [group.user UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [group.name UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [group.owner UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 5, [members UTF8String], -1, SQLITE_TRANSIENT);
        //        sqlite3_bind_text(statement, 6, [group.iconURL UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 6, createdOn);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            return YES;
        }
        else {
            NSLog(@"Error on insertGroup.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

-(BOOL)updateGroup:(ChatGroup *)group {
    //    NSLog(@"**** updating group %@", group.groupId);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *members = [ChatGroup membersDictionary2String:group.members];
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE groups SET groupName = ?, owner = ?, members = ? WHERE groupId = ?"];
        //        NSLog(@"QUERY:%@", updateSQL);
        
        sqlite3_prepare(database, [updateSQL UTF8String], -1, &statement, NULL);
        
        sqlite3_bind_text(statement, 1, [group.name UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [group.owner UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [members UTF8String], -1, SQLITE_TRANSIENT);
        //        sqlite3_bind_text(statement, 4, [group.iconURL UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 4, [group.groupId UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_DONE) {
            sqlite3_reset(statement);
            //            NSLog(@"Group successfully updated.");
            return YES;
        }
        else {
            NSLog(@"Error while updating group.");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            sqlite3_reset(statement);
            return NO;
        }
    }
    return NO;
}

static NSString *SELECT_FROM_GROUPS_STATEMENT = @"SELECT groupId, user, groupName, owner, members, createdOn FROM groups ";

-(void)getAllGroupsSyncronizedWithCompletion:(void(^)(NSArray<ChatGroup*> *)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        NSMutableArray *groups = [[NSMutableArray alloc] init];
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
            NSString *querySQL = [NSString stringWithFormat:@"%@ order by createdOn desc", SELECT_FROM_GROUPS_STATEMENT];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    ChatGroup *group = [self groupFromStatement:statement];
                    [groups addObject:group];
                }
                sqlite3_reset(statement);
            } else {
                NSLog(@"**** PROBLEMS WHILE QUERYING GROUPS...");
                NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
            }
        }
        callback(groups);
    });
}

//-(NSArray*)getAllGroupsForUser:(NSString *)user {
-(NSMutableArray *)getAllGroupsForUser:(NSString *)user {
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"%@ WHERE user = \"%@\" order by createdOn desc", SELECT_FROM_GROUPS_STATEMENT, user];
        NSLog(@"QUERY: %@", querySQL);
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                ChatGroup *group = [self groupFromStatement:statement];
                //                NSLog(@"Adding group from DB id:%@ name:%@", group.groupId, group.name);
                [groups addObject:group];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** PROBLEMS WHILE QUERYING GROUPS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return groups;
}

-(void)getGroupByIdSyncronized:(NSString *)groupId completion:(void(^)(ChatGroup *)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        ChatGroup *group = [self getGroupById:groupId];
        callback(group);
    });
}

-(ChatGroup *)getGroupById:(NSString *)groupId {
//    dispatch_async(serialDatabaseQueue, ^{
    ChatGroup *group = nil;
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"%@ where groupId = \"%@\"",SELECT_FROM_GROUPS_STATEMENT, groupId];
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                group = [self groupFromStatement:statement];
            }
            sqlite3_reset(statement);
        } else {
            NSLog(@"**** PROBLEMS WHILE QUERYING GROUPS...");
            NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        }
    }
    return group;
//    });
}

-(void)removeGroupSyncronized:(NSString *)groupId completion:(void(^)(BOOL error)) callback {
    dispatch_async(serialDatabaseQueue, ^{
        //    NSLog(@"**** remove query...");
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM groups WHERE groupId = \"%@\"", groupId];
            //        NSLog(@"**** QUERY:%@", sql);
            const char *stmt = [sql UTF8String];
            sqlite3_prepare_v2(database, stmt,-1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_DONE) {
                sqlite3_reset(statement);
                callback(NO);
            }
            else {
                NSLog(@"Database returned error %d: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
                sqlite3_reset(statement);
                callback(YES);
            }
        }
        callback(YES);
    });
}

-(ChatGroup *)groupFromStatement:(sqlite3_stmt *)statement {
    
    // groupId, user, groupName, owner, members, iconURL, createdOn
    
    //    NSLog(@"== GROUP FROM STATEMENT ==");
    const char* _groupId = (const char *) sqlite3_column_text(statement, 0);
    //    NSLog(@">>>>>>>>>>> groupID = %s", _groupId);
    NSString *groupId = nil;
    if (_groupId) {
        groupId = [[NSString alloc] initWithUTF8String:_groupId];
    }
    
    const char* _user = (const char *) sqlite3_column_text(statement, 1);
    //    NSLog(@">>>>>>>>>>> user = %s", _user);
    NSString *user = nil;
    if (_user) {
        user = [[NSString alloc] initWithUTF8String:_user];
    }
    
    const char* _groupName = (const char *) sqlite3_column_text(statement, 2);
    //    NSLog(@">>>>>>>>>>> groupName = %s", _groupName);
    NSString *groupName = nil;
    if (_groupName) {
        groupName = [[NSString alloc] initWithUTF8String:_groupName];
    }
    
    const char* _owner = (const char *) sqlite3_column_text(statement, 3);
    //    NSLog(@">>>>>>>>>>> owner = %s", _owner);
    NSString *owner = nil;
    if (_owner) {
        owner = [[NSString alloc] initWithUTF8String:_owner];
    }
    
    const char* _members = (const char *) sqlite3_column_text(statement, 4);
    //    NSLog(@">>>>>>>>>>> members = %s", _members);
    NSString *members = nil;
    if (_members) {
        members = [[NSString alloc] initWithUTF8String:_members];
    }
    
    //    const char* _iconURL = (const char *) sqlite3_column_text(statement, 5);
    //    NSString *iconURL = nil;
    //    if (_iconURL) {
    //        iconURL = [[NSString alloc] initWithUTF8String:_iconURL];
    //    }
    
    double createdOn = sqlite3_column_double(statement, 5);
    
    ChatGroup *group = [[ChatGroup alloc] init];
    group.groupId = groupId;
    group.user = user;
    group.name = groupName;
    group.owner = owner;
    group.members = [ChatGroup membersString2Dictionary:members];
    group.createdOn = [NSDate dateWithTimeIntervalSince1970:createdOn];
    
    return group;
}

@end
