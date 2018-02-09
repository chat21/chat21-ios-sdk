//
//  ChatUpload.h
//  Chat21
//
//  Created by Andrea Sponziello on 20/04/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatUploadsController;

@interface ChatUpload : NSObject

@property (nonatomic, strong) ChatUploadsController *uploadsController;
@property (nonatomic, assign) NSInteger currentState;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NSString *uploadDescription;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *uploadId;

// abstract
-(void)cancel;
// abstract
-(void)start;

@end
