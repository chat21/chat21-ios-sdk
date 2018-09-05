//
//  ChatDiskImageCache.m
//  chat21
//
//  Created by Andrea Sponziello on 27/08/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatDiskImageCache.h"
#import <Foundation/Foundation.h>
#import "ChatImageUtil.h"
#import "ChatUtil.h"

static ChatDiskImageCache *sharedInstance = nil;

@implementation ChatDiskImageCache

-(id)init
{
    if (self = [super init])
    {
        self.imageCache = [[NSMutableDictionary alloc] init];
        self.cacheFolder = @"profileImageCache";
        self.maxSize = 50;
        self.tasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(ChatDiskImageCache *)getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

-(void)addImageToCache:(UIImage *)image withKey:(NSString *)key {
    [self.imageCache setObject:image forKey:key];
    [ChatImageUtil saveImageAsJPEG:image withName:key inFolder:self.cacheFolder];
}

-(void)deleteImageFromCacheWithKey:(NSString *)key {
    [self.imageCache removeObjectForKey:key];
    [ChatDiskImageCache deleteFileWithName:key inFolder:self.cacheFolder];
}

-(void)deleteFilesFromCacheStartingWith:(NSString *)partial_key {
    NSString *folder_path = [ChatUtil absoluteFolderPath:self.cacheFolder]; // cache folder path
    NSLog(@"deleting files at folder path: %@ starting with: %@", folder_path, partial_key);
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *directoryList = [filemgr contentsOfDirectoryAtPath:folder_path error:nil];
    for (NSString *filename in directoryList) {
        if ([filename hasPrefix:partial_key]) {
            NSLog(@"Inizia con partial_key: %@", filename);
            NSString *file_path = [folder_path stringByAppendingPathComponent:filename];
            NSLog(@"file_path to delete: %@", file_path);
            NSError *error;
            [filemgr removeItemAtPath:file_path error:&error];
            if (error) {
                NSLog(@"Error removing file in cache path? (%@) - %@",file_path, error);
            }
        }
    }
//        NSArray *directoryList2 = [filemgr contentsOfDirectoryAtPath:folder_path error:nil];
//        for (id file in directoryList2) {
//            NSLog(@"Image: %@", file);
//        }
//        NSLog(@"End list.");
}

-(UIImage *)getCachedImage:(NSString *)key {
    return [self getCachedImage:key sized:0 circle:NO];
}

-(UIImage *)getCachedImage:(NSString *)key sized:(long)size circle:(BOOL)circle {
    NSString *sized_key = key;
    if (size != 0) {
        sized_key = [NSString stringWithFormat:@"%@_sized_%ld", key, size];
    }
    // hit memory first
    UIImage *image = (UIImage *)[self.imageCache objectForKey:sized_key];
    if (!image) {
        image = [ChatDiskImageCache loadImage:sized_key inFolder:self.cacheFolder];
        if (!image && size != 0) {
            // a resized image was requested, not the original one, then...
            // get the original one
            image = [ChatDiskImageCache loadImage:key inFolder:self.cacheFolder];
            if (image) {
                // we have the original.
                // resize...
                UIImage *resized_image = [ChatImageUtil scaleImage:image toSize:CGSizeMake(size, size)];
                if (circle) {
                    resized_image = [ChatImageUtil circleImage:resized_image];
                }
                [self addImageToCache:resized_image withKey:sized_key];
            }
        }
    }
    return image;
}

+(UIImage *)loadImage:(NSString *)fileName inFolder:(NSString *)folderName {
    NSString *folder_path = [ChatUtil absoluteFolderPath:folderName]; // cache folder path
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:folder_path error:nil];
//    for (id file in directoryList) {
//        NSLog(@"Image: %@", file);
//    }
//    NSLog(@"End list.");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *image_path = [folder_path stringByAppendingPathComponent:fileName];
//    NSLog(@"image path to load: %@", image_path);
    BOOL fileExist = [fileManager fileExistsAtPath:image_path];
    UIImage *image;
    if (fileExist) {
//        [fileManager removeItemAtPath:image_path error:NULL];
        image = [UIImage imageWithContentsOfFile:image_path];
    }
    return image;
}

+(void)deleteFileWithName:(NSString*)fileName inFolder:(NSString *)folderName {
    NSString *folder_path = [ChatUtil absoluteFolderPath:folderName]; // cache folder path
    NSString *image_path = [folder_path stringByAppendingPathComponent:fileName];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSLog(@"Image path: %@", image_path);
    NSError *error;
    [filemgr removeItemAtPath:image_path error:&error];
    if (error) {
        NSLog(@"Error removing image to cache path? (%@) - %@",image_path, error);
    }
    // test
    if ([filemgr fileExistsAtPath: image_path ] == NO) {
        NSLog(@"Image deleted.");
    }
    else {
        NSLog(@"Error deleting image.");
    }
//    NSArray *directoryList = [filemgr contentsOfDirectoryAtPath:folder_path error:nil];
//    for (id file in directoryList) {
//        NSLog(@"Image: %@", file);
//    }
//    NSLog(@"End list.");
}

//+(NSString *)absoluteFolderPath:(NSString *)folderName {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *path = [documentsDirectory stringByAppendingPathComponent:folderName];
//    return path;
//}

- (NSURLSessionDataTask *)getImage:(NSString *)imageURL completionHandler:(void(^)(NSString *imageURL, UIImage *image))callback {
    return [self getImage:imageURL sized:0 circle:NO completionHandler:^(NSString *imageURL, UIImage *image) {
        callback(imageURL, image);
    }];
}

- (NSURLSessionDataTask *)getImage:(NSString *)imageURL sized:(long)size circle:(BOOL)circle completionHandler:(void(^)(NSString *imageURL, UIImage *image))callback {
    NSURL *url = [NSURL URLWithString:imageURL];
    NSString *cache_key = [self urlAsKey:url];
    UIImage *image = [self getCachedImage:cache_key];
    if (image) {
        callback(imageURL, image);
        return nil;
    }
    NSURLSessionDataTask *currentTask = [self.tasks objectForKey:imageURL];
    if (currentTask) {
        NSLog(@"Image %@ already downloading.", imageURL);
        callback(imageURL, nil);
    }
    NSURLSessionConfiguration *_config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *_session = [NSURLSession sessionWithConfiguration:_config];
    
    NSLog(@"Downloading image. URL: %@", imageURL);
    if (!url) {
        NSLog(@"ERROR - Can't download image, URL is null");
        callback(imageURL, nil);
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Image downloaded: %@", imageURL);
        [self.tasks removeObjectForKey:imageURL];
        if (error) {
            NSLog(@"%@", error);
            callback(imageURL, nil);
            return;
        }
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                [self addImageToCache:image withKey:cache_key];
                if (size != 0) {
                    image = [self getCachedImage:cache_key sized:size circle:circle];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(imageURL, image);
            });
        }
    }];
    [self.tasks setObject:task forKey:imageURL];
    [task resume];
    return task;
}

-(NSString *)urlAsKey:(NSURL *)url {
    NSArray<NSString *> *components = [url pathComponents];
    NSString *key = [[components componentsJoinedByString:@"_"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
//    NSLog(@"urlAsKey: %@ as key: %@", url, key);
    return key;
}

@end
