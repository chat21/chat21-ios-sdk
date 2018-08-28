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
        self.maxSize = 50;
    }
    return self;
}

+(ChatImageCache *)getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

-(void)addImage:(UIImage *)image withKey:(NSString *)key {
    [self removeOldestImage];
    ChatImageWrapper *wrapper = [[ChatImageWrapper alloc] init];
    wrapper.image = image;
    wrapper.lastReadTime = [[NSDate alloc] init];
    wrapper.createdTime = wrapper.lastReadTime;
    wrapper.key = key;
    [self.imageCache setObject:wrapper forKey:key];
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
        [self.imageCache removeObjectForKey:wrapperToRemove.key];
        [self deleteImage:wrapperToRemove.key];
    }
}

-(ChatImageWrapper *)getImage:(NSString *)key {
    ChatImageWrapper *wrapper = nil;
    // hit memory first
    wrapper = (ChatImageWrapper *)[self.imageCache objectForKey:key];
    if (wrapper) {
        wrapper.lastReadTime = [[NSDate alloc] init];
        // then hit disk
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
    [self.imageCache removeAllObjects];
}

-(void)deleteImage:(NSString*)imageKey {
    [self.imageCache removeObjectForKey:imageKey];
}

+(NSString *)filePathInApp:(NSString *)path {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:path];
    return file;
}

@end
