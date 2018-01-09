//
//  ChatMessageComponents.h
//  Chat21
//
//  Created by Andrea Sponziello on 29/03/16.
//  Copyright © 2016 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessageComponents : NSObject

// array of NSTextCheckingResult. Iterate:
// for (NSTextCheckingResult *match in arrayOfAllMatches) {
//   NSString* substringForMatch = [text substringWithRange:match.range];
// }
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSArray *urlsMatches;
@property (strong, nonatomic) NSArray *chatLinkMatches;

@end
