//
//  UIView+UIView_Property.m
//  BirdWatching
//
//  Created by andrea sponziello on 05/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIView+Property.h"
#import <objc/runtime.h>

@implementation UIView (UIView_Property)

static char UIB_PROPERTY_KEY;

@dynamic property;

-(void)setProperty:(NSObject *)property
{
    objc_setAssociatedObject(self, &UIB_PROPERTY_KEY, property, OBJC_ASSOCIATION_RETAIN);
}

-(NSObject*)property
{
    return (NSObject*)objc_getAssociatedObject(self, &UIB_PROPERTY_KEY);
}

@end
