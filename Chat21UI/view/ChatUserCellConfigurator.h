//
//  ChatUserCellConfigurator.h
//  chat21
//
//  Created by Andrea Sponziello on 10/09/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ChatImageCache;
@class ChatDiskImageCache;
@class ChatUser;
@class ChatGroup;
@class ChatSelectUserLocalVC;

@interface ChatUserCellConfigurator : NSObject

@property(strong, nonatomic) ChatSelectUserLocalVC *vc;
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) ChatDiskImageCache *imageCache;
@property (strong, nonatomic) ChatGroup *group;

-(id)initWith:(ChatSelectUserLocalVC *)vc;
-(UITableViewCell *)configureCellAtIndexPath:(NSIndexPath *)indexPath;

@end
