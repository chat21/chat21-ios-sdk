//
//  ChatDiskImageCache.m
//  chat21
//
//  Created by Andrea Sponziello on 27/08/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatDiskImageCache.h"
#import <Foundation/Foundation.h>

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
    [ChatDiskImageCache saveImageAsJPEG:image withName:key inFolder:self.cacheFolder];
}

-(UIImage *)getCachedImage:(NSString *)key {
    //    ChatImageWrapper *wrapper = nil;
    // hit memory first
    UIImage *image = (UIImage *)[self.imageCache objectForKey:key];
    if (!image) {
        image = [ChatDiskImageCache loadImage:key inFolder:self.cacheFolder];
        // if now - file_image.createdOn > 1 day image = nil
    }
    return image;
}

+(UIImage *)loadImage:(NSString *)fileName inFolder:(NSString *)folderName {
    NSString *folder_path = [self absoluteFolderPath:folderName]; // cache folder path
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryList = [fileManager contentsOfDirectoryAtPath:folder_path error:nil];
    for (id file in directoryList) {
        NSLog(@"Image: %@", file);
    }
    NSLog(@"End list.");
    
    NSString *image_path = [folder_path stringByAppendingPathComponent:fileName];
    NSLog(@"image path to load: %@", image_path);
    
    BOOL fileExist = [fileManager fileExistsAtPath:image_path];
    UIImage *image;
    if (fileExist) {
//        [fileManager removeItemAtPath:image_path error:NULL];
        image = [UIImage imageWithContentsOfFile:image_path];
    }
    return image;
}

+(void)saveImageAsJPEG:(UIImage *)image withName:(NSString*)fileName inFolder:(NSString *)folderName {
    NSString *folder_path = [self absoluteFolderPath:folderName]; // cache folder path
    NSString *image_path = [folder_path stringByAppendingPathComponent:fileName];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if (![filemgr fileExistsAtPath:folder_path]) {
        NSError *error;
        [filemgr createDirectoryAtPath:folder_path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"error creating cache folder (%@): %@", folder_path, error);
        }
    }
    NSLog(@"Image path: %@", image_path);
    NSError *error;
    [UIImageJPEGRepresentation(image, 0.9) writeToFile:image_path options:NSDataWritingAtomic error:&error];
    NSLog(@"Error saving image to cache path? (%@) - %@",image_path, error);
    // test
    if ([filemgr fileExistsAtPath: image_path ] == NO) {
        NSLog(@"Error. Image not saved.");
    }
    else {
        NSLog(@"Image saved to cache path.");
    }
    NSArray *directoryList = [filemgr contentsOfDirectoryAtPath:folder_path error:nil];
    for (id file in directoryList) {
        NSLog(@"Image: %@", file);
    }
    NSLog(@"End list.");
}

+(NSString *)absoluteFolderPath:(NSString *)folderName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:folderName];
    NSLog(@"path: %@", path);
    return path;
}

//-(void)removeOldestImage {
//    // ATTENZIONE! perchè questo metodo abbia senso bisognerebbe
//    // rendere persistente anche il dizionario!
//
//    if ([self.imageCache count] == self.maxSize) {
//        //        NSLog(@"Removing oldest element");
//        // remove oldest element
//
//        NSMutableArray *wrappers = [[NSMutableArray alloc] init];
//        for (NSString* key in self.imageCache) {
//            ChatImageWrapper *wrapper = [self.imageCache objectForKey:key];
//            [wrappers addObject:wrapper];
//            //            NSLog(@"found: %@", wrapper);
//        }
//        // sort by lastDate
//
//        // Ascending order
//        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"lastReadTime" ascending:YES];
//        [wrappers sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
//        // first element is the oldest one
//        ChatImageWrapper *wrapperToRemove = [wrappers objectAtIndex:0];
//        wrapperToRemove.image = nil;
//        [self.imageCache removeObjectForKey:wrapperToRemove.key];
//        [self deleteImage:wrapperToRemove.key];
//    }
//}

//-(void)empty {
//    // DON'T USE THIS: "for (NSString *key in imageCache)". This returns
//    // an enumerator tha cannot be modified during iteration!
//    // EXCEPTION was: "mutated while being enumerated"
//    NSArray *keys = [self.imageCache allKeys];
//    for (NSString* key in keys) {
//        ChatImageWrapper *wrapperToRemove = [self.imageCache objectForKey:key];
//        wrapperToRemove.image = nil; // really useful? The wrapper has a strong reference to the image...
//        [self.imageCache removeObjectForKey:key]; // removeAllObjects (as next) or this? :(
//    }
//    [self.imageCache removeAllObjects];
//}

//-(void)deleteImage:(NSString*)imageKey {
//    [self.imageCache removeObjectForKey:imageKey];
//}

//+(NSString *)filePathInApp:(NSString *)path {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *file = [documentsDirectory stringByAppendingPathComponent:path];
//    return file;
//}

//-(void)getImageByURL:(NSString *)url withCompletion:(void(^)(UIImage *image))callback {
    // getKey = key
    // image = getImage:key
    // if image != nil
    //   callback(image)
    // else
    //   get remote:callback(image)
    //      addImage
    //      callback(image)
    
//}

- (void)getImage:(NSString *)imageURL completionHandler:(void(^)(NSString *imageURL, UIImage *image))callback {
    NSURL *url = [NSURL URLWithString:imageURL];
    NSString *cache_key = [self urlAsKey:url];
    UIImage *image = [self getCachedImage:cache_key];
    if (image) {
        callback(imageURL, image);
        return;
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
        return;
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
//                NSData* imageData = [NSData dataWithData:UIImageJPEGRepresentation(image, 0.8)];
//                NSString *path = [message imagePathFromMediaFolder];
//                NSLog(@"Saving image to: %@", path);
//                NSError *writeError = nil;
//                [message createMediaFolderPathIfNotExists];
//                if(![imageData writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
//                    NSLog(@"%@: Error saving image: %@", [self class], [writeError localizedDescription]);
//                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(imageURL, image);
                });
            }
        }
    }];
    [self.tasks setObject:task forKey:imageURL];
    [task resume];
}

-(NSString *)urlAsKey:(NSURL *)url {
    NSArray<NSString *> *components = [url pathComponents];
    NSString *key = [[components componentsJoinedByString:@"_"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSLog(@"urlAsKey: %@ as key: %@", url, key);
    return key;
}

@end
