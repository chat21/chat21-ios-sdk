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

@interface CellConfigurator : NSObject

+(UITableViewCell *)configureConversationCell:(ChatConversation *)conversation tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath imageCache:(ChatImageCache *)imageCache;
+(void)changeReadStatus:(ChatConversation *)conversation forCell:(UITableViewCell *)cell;
+(void)setImageForCell:(UITableViewCell *)cell imageURL:(NSString *)imageURL imageCache:(ChatImageCache *)imageCache;
@end

