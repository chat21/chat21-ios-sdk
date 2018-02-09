//
//  ChatUploadsController.h
//  Chat21
//
//  Created by Andrea Sponziello on 20/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatUpload;

@interface ChatUploadsController : NSObject

@property(strong, nonatomic) NSMutableDictionary *currentUploads;

-(void)addDataController:(ChatUpload *)dc;
-(void)removeDataController:(ChatUpload *)dc;

// delegate methods
-(void)didFinishConnection:(ChatUpload *)dataController withError:(NSError *)error;

+(ChatUploadsController *)getSharedInstance;

@end
