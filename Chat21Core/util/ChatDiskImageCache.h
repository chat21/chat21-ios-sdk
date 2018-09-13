//
//  ChatDiskImageCache.h
//  chat21
//
//  Created by Andrea Sponziello on 27/08/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatDiskImageCache : NSObject

@property (nonatomic, strong) NSMutableDictionary *memoryObjects;
@property (nonatomic, strong) NSString *cacheFolder;
@property (nonatomic, assign) NSInteger maxSize;
@property(strong, nonatomic) NSMutableDictionary *tasks;

-(NSURLSessionDataTask *)getImage:(NSString *)imageURL completionHandler:(void(^)(NSString *imageURL, UIImage *image))callback;
- (NSURLSessionDataTask *)getImage:(NSString *)imageURL sized:(long)size circle:(BOOL)circle completionHandler:(void(^)(NSString *imageURL, UIImage *image))callback;

-(UIImage *)getCachedImage:(NSString *)key;
-(UIImage *)getCachedImage:(NSString *)key sized:(long)size circle:(BOOL)circle;
-(void)addImageToCache:(UIImage *)image withKey:(NSString *)key;
-(void)addImageToMemoryCache:(UIImage *)image withKey:(NSString *)key;
-(void)deleteImageFromCacheWithKey:(NSString *)key;
-(void)removeCachedImage:(NSString *)key sized:(long)size;
-(void)deleteFilesFromCacheStartingWith:(NSString *)partial_key;
-(void)deleteFilesFromDiskCacheOfProfile:(NSString *)profileId;
-(NSString *)urlAsKey:(NSURL *)url;
-(void)updateProfile:(NSString *)profileId image:(UIImage *)image;

+(NSString *)sizedKey:(NSString *)key size:(long) size;
//+(void)saveImageAsJPEG:(UIImage *)image withName:(NSString*)name inFolder:(NSString *)folderName;
+(UIImage *)loadImage:(NSString *)name inFolder:(NSString *)folderName;
+(ChatDiskImageCache *)getSharedInstance;


@end
