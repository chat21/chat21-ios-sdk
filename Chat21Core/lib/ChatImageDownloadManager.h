//
//  ChatImageDownloadManager.h
//  chat21
//
//  Created by Andrea Sponziello on 06/05/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ChatMessage;
@class ChatImageCache;

@interface ChatImageDownloadManager : NSObject

@property(strong, nonatomic) NSMutableDictionary *tasks;

- (void)downloadImage:(ChatMessage *)message onIndexPath:(NSIndexPath *)indexPath completionHandler:(void(^)(NSIndexPath* indexPath, UIImage *image, NSError *error))callback;

@end
