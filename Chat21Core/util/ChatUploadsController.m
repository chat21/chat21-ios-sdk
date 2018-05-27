//
//  ChatUploadsController.m
//  Chat21
//
//  Created by Andrea Sponziello on 20/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import "ChatUploadsController.h"
#import "ChatUpload.h"

static ChatUploadsController *sharedInstance = nil;

@implementation ChatUploadsController

-(id)init {
    NSLog(@"Initializing ChatUploadsController...");
    self = [super init];
    if (self) {
        self.currentUploads = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(ChatUploadsController *)getSharedInstance {
    NSLog(@"Creating ChatUploadsController instance...");
    if (!sharedInstance) {
        NSLog(@"Instance created...");
        sharedInstance = [[super alloc] init];
    }
    return sharedInstance;
}

-(void)addDataController:(ChatUpload *)dc {
    dc.uploadsController = self;
    [self.currentUploads setObject:dc forKey:dc.uploadId];
    NSLog(@"Added controller. Total %lu", (unsigned long)self.currentUploads.count);
}

-(void)didFinishConnection:(ChatUpload *)dc withError:(NSError *)error {
    NSLog(@"Connection for %@ finished. Finding and removing...", dc);
    NSLog(@"Total controllers: %lu", (unsigned long)self.currentUploads.count);
    [self removeDataController:dc];
}

-(void)removeDataController:(ChatUpload *)dc {
    [dc cancel];
    [self.currentUploads removeObjectForKey:dc.uploadId];
    NSLog(@"Controller was removed. Total %lu", (unsigned long)self.currentUploads.count);
}

@end
