//
//  ChatConnectionStatusHandler.m
//  chat21
//
//  Created by Andrea Sponziello on 01/01/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatConnectionStatusHandler.h"
#import <libkern/OSAtomic.h>

@implementation ChatConnectionStatusHandler

-(void)connect {
    NSLog(@"Connection status.");
    NSString *url = @"/.info/connected";
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    self.connectedRef = [rootRef child:url];
    
    // event
    if (!self.connectedRefHandle) {
        self.connectedRefHandle = [self.connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            NSLog(@"snapshot %@ - %d", snapshot, [snapshot.value boolValue]);
            BOOL status = [snapshot.value boolValue];
            if(status) {
                NSLog(@".connected.");
                [self notifyEvent:ChatConnectionStatusEventConnected];
            } else {
                NSLog(@".not connected.");
                [self notifyEvent:ChatConnectionStatusEventDisconnected];
            }
        }];
    }
}

-(void)isStatusConnectedWithCompletionBlock:(void (^)(BOOL connected, NSError* error))callback {
    // once
    [self.connectedRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get user value
        NSLog(@"SNAPSHOT ONCE %@ - %d", snapshot, [snapshot.value boolValue]);
        if([snapshot.value boolValue]) {
            NSLog(@"..connected once..");
            callback(YES, nil);
        }
        else {
            NSLog(@"..not connected once..");
            callback(NO, nil);
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
        callback(NO, error);
    }];
}

-(void)dispose {
    [self.connectedRef removeAllObservers];
    [self removeAllObservers];
    self.connectedRef = nil;
    self.connectedRefHandle = 0;
}

// observer

-(void)notifyEvent:(ChatConnectionStatusEventType)event {
    if (!self.eventObservers) {
        return;
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(event)];
    if (!eventCallbacks) {
        return;
    }
    for (NSNumber *event_handle_key in eventCallbacks.allKeys) {
        void (^callback)() = [eventCallbacks objectForKey:event_handle_key];
        callback();
    }
}

-(NSUInteger)observeEvent:(ChatConnectionStatusEventType)eventType withCallback:(void (^)())callback {
    if (!self.eventObservers) {
        self.eventObservers = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:@(eventType)];
    if (!eventCallbacks) {
        eventCallbacks = [[NSMutableDictionary alloc] init];
        [self.eventObservers setObject:eventCallbacks forKey:@(eventType)];
    }
    NSUInteger callback_handle = (NSUInteger) OSAtomicIncrement64Barrier(&_lastEventHandle);
    [eventCallbacks setObject:callback forKey:@(callback_handle)];
    return callback_handle;
}

-(void)removeObserverWithHandle:(NSUInteger)event_handle {
    if (!self.eventObservers) {
        return;
    }
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeObjectForKey:@(event_handle)];
    }
}

-(void)removeAllObservers {
    if (!self.eventObservers) {
        return;
    }
    // iterate all keys (events)
    for (NSNumber *event_key in self.eventObservers) {
        NSMutableDictionary *eventCallbacks = [self.eventObservers objectForKey:event_key];
        [eventCallbacks removeAllObjects];
    }
}

@end
