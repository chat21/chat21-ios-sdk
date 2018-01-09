//
//  ChatStringUtil.h
//  tilechat
//
//  Created by Andrea Sponziello on 07/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatStringUtil : NSObject

+(NSString *)timeFromNowToString:(NSDate *)date;
+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

@end
