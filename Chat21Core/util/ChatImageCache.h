//
//  ChatImageCache.h
//  Salve Smart
//
//  Created by Andrea Sponziello on 04/11/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ChatImageWrapper;

@interface ChatImageCache : NSObject

@property (nonatomic, strong) NSMutableDictionary *imageCache;
@property (nonatomic, strong) NSString *cacheName;
@property (nonatomic, assign) NSInteger maxSize;

-(void)addImage:(UIImage *)image withKey:(NSString *)key;
-(ChatImageWrapper *)getImage:(NSString *)key;
-(void)deleteImage:(NSString*)imageKey;
-(void)empty;

//+(ChatImageCache *)getSharedInstance;
+(NSString *)filePathInApp:(NSString *)path;
//-(ChatImageWrapper *)restoreImageWithKey:(NSString *)imageKey;
//-(void)listAllImagesFromDisk;

+(ChatImageCache *)getSharedInstance;

@end
