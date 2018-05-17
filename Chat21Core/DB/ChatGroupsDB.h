//
//  ChatGroupsDB.h
//  bppmobile
//
//  Created by Andrea Sponziello on 26/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class ChatGroup;

@interface ChatGroupsDB : NSObject
{
    NSString *databasePath;
}

@property (assign, nonatomic) BOOL logQuery;

+(ChatGroupsDB*)getSharedInstance;
-(BOOL)createDBWithName:(NSString *)name;

// groups
-(void)insertOrUpdateGroupSyncronized:(ChatGroup *)group completion:(void(^)()) callback;
//-(void)insertGroupOnlyIfNotExistsSyncronized:(ChatGroup *)group completion:(void(^)()) callback; // only used by group-created-by-push-notification
-(NSMutableArray *)getAllGroupsForUser:(NSString *)user;
-(void)getGroupByIdSyncronized:(NSString *)groupId completion:(void(^)(ChatGroup *)) callback;
-(void)removeGroupSyncronized:(NSString *)groupId completion:(void(^)(BOOL error)) callback;

@end
