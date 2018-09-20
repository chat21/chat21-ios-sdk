//
//  ChatSelectGroupMembersCellConfigurator.h
//  chat21
//
//  Created by Andrea Sponziello on 11/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ChatSelectGroupMembersLocal;
@class ChatDiskImageCache;

static int SELECT_GROUP_MEMBER_LIST_CELL_SIZE = 80;

@interface ChatSelectGroupMembersCellConfigurator : NSObject

@property(strong, nonatomic) ChatSelectGroupMembersLocal *vc;
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) ChatDiskImageCache *imageCache;
@property(strong, nonatomic) NSMutableDictionary<NSString*, NSURLSessionDataTask*> *tasks;

-(id)initWith:(ChatSelectGroupMembersLocal *)vc;
-(UITableViewCell *)configureCellAtIndexPath:(NSIndexPath *)indexPath;
-(void)teminatePendingTasks;

@end
