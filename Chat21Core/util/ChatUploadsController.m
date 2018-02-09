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
    NSLog(@"Added controller. Total %ld", self.currentUploads.count);
}

-(void)didFinishConnection:(ChatUpload *)dc withError:(NSError *)error {
    NSLog(@"Connection for %@ finished. Finding and removing...", dc);
    NSLog(@"Total controllers: %ld", self.currentUploads.count);
    [self removeDataController:dc];
    
//    ChatUpload *controller = nil;
//    for (id obj in self.currentUploads) {
//        if (obj == dc) {
//            controller = (SHPDataController *)obj;
//            break;
//        }
//    }
//    if (controller) {
//        //        NSLog(@"Found controller %@, BUT NOT removing from controllers (FOR HISTORY).", controller);
//        NSLog(@"Found controller %@, now removing from controllers.", controller);
//        //        [self.controllers removeObject:controller];
//        [self removeDataController:controller];
//    } else {
//        NSLog(@"Controller not found.");
//    }
    
//    // on completion play a sound
//    // help: https://github.com/TUNER88/iOSSystemSoundsLibrary
//    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/Modern/sms_alert_bamboo.caf"];
//    SystemSoundID soundID;
//    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL,&soundID);
//    AudioServicesPlaySystemSound(soundID);
}

-(void)removeDataController:(ChatUpload *)dc {
    [dc cancel];
    [self.currentUploads removeObjectForKey:dc.uploadId];
    NSLog(@"Controller was removed. Total %ld", self.currentUploads.count);
}

@end
