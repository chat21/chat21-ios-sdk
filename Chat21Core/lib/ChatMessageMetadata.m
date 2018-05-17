//
//  ChatMessageMetadata.m
//  chat21
//
//  Created by Andrea Sponziello on 10/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatMessageMetadata.h"
#import "ChatMessage.h"

@implementation ChatMessageMetadata

-(NSDictionary *)asDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.src) {
        [dict setObject:self.src forKey:MSG_METADATA_ATTACHMENT_SRC];
    }
    if (self.width) {
        [dict setObject:@(self.width) forKey:MSG_METADATA_IMAGE_WIDTH];
    }
    if (self.height) {
        [dict setObject:@(self.height) forKey:MSG_METADATA_IMAGE_HEIGHT];
    }
    return dict;
}

+(ChatMessageMetadata *)fromDictionaryFactory:(NSDictionary *)metadata {
    if (!metadata) {
        return nil;
    } else if (![metadata isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
//    NSLog(@"metadata: %@", metadata);
    ChatMessageMetadata *metadata_obj = [[ChatMessageMetadata alloc] init];
    NSString *src = metadata[MSG_METADATA_ATTACHMENT_SRC];
    metadata_obj.src = src;
    if (metadata[MSG_METADATA_IMAGE_HEIGHT]) {
        metadata_obj.height = (NSInteger) metadata[MSG_METADATA_IMAGE_HEIGHT];
    }
    if (metadata[MSG_METADATA_IMAGE_WIDTH]) {
        metadata_obj.width = (NSInteger) metadata[MSG_METADATA_IMAGE_WIDTH];
    }
    return metadata_obj;
}

@end
