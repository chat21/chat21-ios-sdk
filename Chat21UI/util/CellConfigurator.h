//
//  CellConfigurator.h
//  Chat21
//
//  Created by Andrea Sponziello on 28/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ChatConversation;
@class ChatImageCache;
@class ChatConversationsVC;
@class ChatDiskImageCache;

@interface CellConfigurator : NSObject

@property(strong, nonatomic) NSArray<ChatConversation *> *conversations;
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) ChatDiskImageCache *imageCache;

-(id)initWithTableView:(UITableView *)tableView imageCache:(ChatDiskImageCache *)imageCache conversations:(NSArray<ChatConversation *> *)conversations;
-(UITableViewCell *)configureConversationCell:(ChatConversation *)conversation indexPath:(NSIndexPath *)indexPath;
+(void)changeReadStatus:(ChatConversation *)conversation forCell:(UITableViewCell *)cell;
+(void)archiveLabel:(UITableViewCell *)cell archived:(BOOL)archived;

@end
