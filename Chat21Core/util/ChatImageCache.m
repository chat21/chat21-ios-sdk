//
//  ChatImageCache.m
//  Salve Smart
//
//  Created by Andrea Sponziello on 04/11/15.
//  Copyright © 2015 Frontiere21. All rights reserved.
//

#import "ChatImageCache.h"
#import <Foundation/Foundation.h>
#import "ChatImageWrapper.h"

static ChatImageCache *sharedInstance = nil;

//@interface ImageWrapper: NSObject
//
//@property (nonatomic, strong) NSDate *lastReadTime;
//@property (nonatomic, strong) NSDate *creationTime;
//@property (nonatomic, strong) UIImage *image;
//@property (nonatomic, strong) NSString *key;
//
//@end
//
//@implementation ImageWrapper
//
//@synthesize lastReadTime;
//@synthesize creationTime;
//@synthesize image;
//@synthesize key;
//
////static int compareSelector(id w1, id w2, void *context) {
////    SEL methodSelector = (SEL)context;
////    NSDate d1 = [w1 performSelector:methodSelector];
////    NSDate d2 = [w2 performSelector:methodSelector];
////    return [value1 compare:value2];
////}
//
//@end


@implementation ChatImageCache

-(id)init
{
    if (self = [super init])
    {
        self.imageCache = [[NSMutableDictionary alloc] init];
        self.cacheName = @"defaultImageCache";
        self.maxSize = 200;
    }
    return self;
}

//+(ChatImageCache *)getSharedInstance {
//    if (!sharedInstance) {
//        sharedInstance = [[super alloc] init];
//    }
//    return sharedInstance;
//}

-(void)addImage:(UIImage *)image withKey:(NSString *)key {
    //    NSLog(@"ADDING NEW IMAGE...");
    //    NSLog(@"CACHE: Actual size: %d", [imageCache count]);
    //    NSLog(@"CACHE: Max size: %d", self.maxSize);
    [self removeOldestImage];
    ChatImageWrapper *wrapper = [[ChatImageWrapper alloc] init];
    wrapper.image = image;
    wrapper.lastReadTime = [[NSDate alloc] init];
    wrapper.createdTime = wrapper.lastReadTime;
    //    NSLog(@"**** CREATED IMAGE AT %@", wrapper.creationTime);
    wrapper.key = key;
    [self.imageCache setObject:wrapper forKey:key];
    [self saveImage:image withKey:key];
}

-(void)removeOldestImage {
    // ATTENZIONE! perchè questo metodo abbia senso bisognerebbe
    // rendere persistente anche il dizionario!
    
    if ([self.imageCache count] == self.maxSize) {
        //        NSLog(@"Removing oldest element");
        // remove oldest element
        
        NSMutableArray *wrappers = [[NSMutableArray alloc] init];
        for (NSString* key in self.imageCache) {
            ChatImageWrapper *wrapper = [self.imageCache objectForKey:key];
            [wrappers addObject:wrapper];
            //            NSLog(@"found: %@", wrapper);
        }
        // sort by lastDate
        
        // Ascending order
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"lastReadTime" ascending:YES];
        [wrappers sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
        // first element is the oldest one
        ChatImageWrapper *wrapperToRemove = [wrappers objectAtIndex:0];
        wrapperToRemove.image = nil;
        //        NSLog(@"CACHE: Removing object at 0 %@", wrapperToRemove.lastReadTime);
        [self.imageCache removeObjectForKey:wrapperToRemove.key];
        [self deleteImage:wrapperToRemove.key];
    }
}

//-(UIImage *)getImage:(NSString *)key {
//    UIImage *image = nil;
//    // hit memory first
//    ChatImageWrapper * wrapper = (ChatImageWrapper *)[self.imageCache objectForKey:key];
//    if (wrapper) {
//        wrapper.lastReadTime = [[NSDate alloc] init];
//        image = wrapper.image;
//    // then hit disk
//    } else {
//        image = [ChatImageCache restoreImage:key];
//    }
//    return image;
//}

-(ChatImageWrapper *)getImage:(NSString *)key {
    ChatImageWrapper *wrapper = nil;
    // hit memory first
    wrapper = (ChatImageWrapper *)[self.imageCache objectForKey:key];
    if (wrapper) {
        wrapper.lastReadTime = [[NSDate alloc] init];
        // then hit disk
    } else {
        wrapper = (ChatImageWrapper *)[self restoreImageWithKey:key];
        if (wrapper) {
            wrapper.lastReadTime = [[NSDate alloc] init];
        }
    }
    return wrapper;
}

-(void)empty {
    // DON'T USE THIS: "for (NSString *key in imageCache)". This returns
    // an enumerator tha cannot be modified during iteration!
    // EXCEPTION was: "mutated while being enumerated"
    NSArray *keys = [self.imageCache allKeys];
    for (NSString* key in keys) {
        ChatImageWrapper *wrapperToRemove = [self.imageCache objectForKey:key];
        wrapperToRemove.image = nil; // really useful? The wrapper has a strong reference to the image...
        [self.imageCache removeObjectForKey:key]; // removeAllObjects (as next) or this? :(
    }
    [self.imageCache removeAllObjects]; // useful? :(
    
    // remove all image files
    [self removeAllImagesFromDisk];
}

-(void)listAllImagesFromDisk {
    //-----> LIST ALL FILES <-----//
    NSLog(@"LISTING ALL FILES FOUND.");
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    int count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSString *file_name = [directoryContent objectAtIndex:count];
        NSLog(@"File %d: %@", (count + 1), file_name);
    }
}

-(void)removeAllImagesFromDisk {
    //-----> LIST ALL FILES <-----//
    NSLog(@"LISTING ALL FILES FOUND.");
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    int count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSString *file_name = [directoryContent objectAtIndex:count];
        NSLog(@"File %d: %@", (count + 1), file_name);
        if ([file_name hasPrefix:self.cacheName]) {
            NSLog(@"Removing file: %@", file_name);
            NSString *filePath = [ChatImageCache filePathInApp:file_name];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            BOOL success = [fileManager removeItemAtPath:filePath error:&error];
            if (success) {
                NSLog(@"Successfully removed file: %@", filePath);
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
                NSLog(@"File exists? %d", fileExists);
            }
            else
            {
                NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
            }
        } else {
            NSLog(@"Not found.");
        }
    }
}

// ***** image on disk *****

-(ChatImageWrapper *)restoreImageWithKey:(NSString *)imageKey {
    //    NSLog(@"RESTORING IMAGE FOR KEY %@", imageKey);
    NSString *file_name = [self imageKeyToFilename:imageKey];
    //    NSLog(@"RESTORING IMAGE file_name: %@", file_name);
    //    NSString *labelKey = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
    NSString *filePath = [ChatImageCache filePathInApp:file_name];
    //    NSLog(@"RESTORING IMAGE path %@", filePath);
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) {
        //        NSLog(@"NO FILE TO RESTORE %@", filePath);
        return nil;
    }
    NSDictionary* attrs = [fm attributesOfItemAtPath:filePath error:nil];
    NSDate *created_on = (NSDate*)[attrs objectForKey: NSFileCreationDate];
    NSDate *modified_on = (NSDate*)[attrs objectForKey: NSFileModificationDate];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    UIImage *_image = [unarchiver decodeObjectForKey:file_name];
    [unarchiver finishDecoding];
    ChatImageWrapper *wrapper = nil;
    if (_image) {
        wrapper = [[ChatImageWrapper alloc] init];
        wrapper.createdTime = created_on;
        wrapper.modifiedTime = modified_on;
        wrapper.image = _image;
        //        NSLog(@"RESTORING IMAGE FOUND %@", wrapper.image);
    }
    return wrapper;
}


//+(UIImage *)restoreImage:(NSString *)fileName {
//    NSString *labelKey = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
//    NSString *file = [ChatImageCache filePathInApp:labelKey];
////    NSLog(@"Restoring image at path %@", file);
//    NSFileManager* fm = [NSFileManager defaultManager];
//    if (![fm fileExistsAtPath:file]) {
//        //        NSLog(@"NO LAST-DATA FILE TO RESTORE!");
//        return nil;
//    } else {
//        NSDictionary* attrs = [fm attributesOfItemAtPath:file error:nil];
//        NSDate *created_on = (NSDate*)[attrs objectForKey: NSFileCreationDate];
//        NSDate *modified_on = (NSDate*)[attrs objectForKey: NSFileModificationDate];
////        NSLog(@"Image %@ Created on: %@",fileName, [created_on description]);
////        NSLog(@"Image %@ Modified on: %@", fileName, [modified_on description]);
//    }
//    NSData *data = [NSData dataWithContentsOfFile:file];
//    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
//    UIImage *_data = [unarchiver decodeObjectForKey:labelKey];
//    //NSString *version = [unarchiver decodeObjectForKey:VERSION_KEY];
//    [unarchiver finishDecoding];
//    return _data;
//}

-(NSString *)imageKeyToFilename:(NSString *)key {
    NSString *image_file_name = [[NSString alloc] initWithFormat:@" %@_%@", self.cacheName, key];
    return [image_file_name stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
}

-(void)saveImage:(UIImage *)image withKey:(NSString*)key {
    NSString *fileName = [self imageKeyToFilename:key]; //[key stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
    //    NSLog(@"Saving image named %@...", fileName);
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:image forKey:fileName];
    [archiver finishEncoding];
    NSString *file = [ChatImageCache filePathInApp:fileName];
    [NSKeyedArchiver archiveRootObject:image toFile:file];//@"/path/to/archive"];
    NSError *err;
    NSLog(@"Image path is %@", file);
    BOOL success = [data writeToFile:file options:NSDataWritingAtomic error:&err];
    if (!success) {
        NSLog(@"Could not write image %@", [err description]);
    } else {
        NSLog(@"Image %@ saved.", file);
    }
}

-(void)deleteImage:(NSString*)imageKey {
    NSLog(@"WARNING: IMAGE NOT DELETED! deleteImage: TODO");
    NSString *fileName = [self imageKeyToFilename:imageKey];
    NSString *filePath = [ChatImageCache filePathInApp:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success) {
        NSLog(@"Successfully removed image file: %@", filePath);
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        NSLog(@"File exists? %d", fileExists);
        [self.imageCache removeObjectForKey:imageKey];
    }
    else
    {
        NSLog(@"Could not delete image file -:%@ ",[error localizedDescription]);
    }
}

+(NSString *)filePathInApp:(NSString *)path {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:path];
    return file;
}

@end

