//
//  ChatContactsSynchronizer.m
//  chat21
//
//  Created by Andrea Sponziello on 09/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatContactsSynchronizer.h"
#import "ChatUser.h"
#import "ChatUtil.h"
#import "ChatManager.h"
#import "ChatContactsDB.h"
@import Firebase;

@interface ChatContactsSynchronizer () {
//    dispatch_queue_t serialDatabaseQueue;
}
@end

@implementation ChatContactsSynchronizer

-(id)initWithTenant:(NSString *)tenant user:(ChatUser *)user {
    if (self = [super init]) {
        self.rootRef = [[FIRDatabase database] reference];
        self.tenant = tenant;
        self.loggeduser = user;
//        serialDatabaseQueue = dispatch_queue_create("db.sqllite", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)addSynchSubscriber:(id<ChatSynchDelegate>)subscriber {
    if (!self.synchSubscribers) {
        self.synchSubscribers = [[NSMutableArray alloc] init];
    }
    [self.synchSubscribers addObject:subscriber];
}

-(void)removeSynchSubscriber:(id<ChatSynchDelegate>)subscriber {
    if (!self.synchSubscribers) {
        return;
    }
    [self.synchSubscribers removeObject:subscriber];
}

-(void)callEndOnSubscribers {
    for (id<ChatSynchDelegate> subscriber in self.synchSubscribers) {
        [subscriber synchEnd];
    }
}

-(void)startSynchro {
    if (![self getFirstSynchroOver]) {
//        [[ContactsDB getSharedInstance] drop_database]; // can be corrupted by incomplete synch for app crashs
        self.synchronizing = YES;
    }
    else {
        self.synchronizing = NO;
    }
    [self synchContacts];
    
//    [self setFirstSynchro:NO];
//    if (![self getFirstSynchro]) {
//        NSLog(@"Synch local contacts");
//        [self firstLoadWithCompletion:^() {
//            NSLog(@"Local contacts end");
//            [self synchFirebase];
//        }];
//    }
//    else {
//        [self synchContacts];
//    }
}

-(void)synchContacts {
    NSLog(@"Remote contacts synch start.");
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    self.contactsRef = [rootRef child: [ChatUtil contactsPath]];
    [self.contactsRef keepSynced:YES];
    
    if (!self.contact_ref_handle_added) {
        NSInteger lasttime = [self lastQueryTime];
        NSLog(@"LAST TIME CONTACT SYNCH %ld", (long)lasttime);
        self.contact_ref_handle_added = [[[self.contactsRef queryOrderedByChild:@"timestamp"] queryStartingAtValue:@(lasttime)] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                ChatUser *contact = [ChatContactsSynchronizer contactFromSnapshotFactory:snapshot];
                if (contact) {
                    NSLog(@"FIREBASE: NEW CONTACT id: %@ firstname: %@ fullname: %@",contact.userId, contact.firstname, contact.fullname);
                    [self insertOrUpdateContactOnDB:contact];
                }
            });
        } withCancelBlock:^(NSError *error) {
            NSLog(@"%@", error.description);
        }];
    }
    
    [self startSynchTimer]; // if ZERO contacts, this timer puts self.synchronizing to FALSE
    
    if (!self.contact_ref_handle_changed) {
        self.contact_ref_handle_changed =
        [self.contactsRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSLog(@"FIREBASE: UPDATED CONTACT SNAPSHOT: %@", snapshot);
                ChatUser *contact = [ChatContactsSynchronizer contactFromSnapshotFactory:snapshot];
                if (contact) {
                    [self insertOrUpdateContactOnDB:contact];
                }
            });
        } withCancelBlock:^(NSError *error) {
            NSLog(@"%@", error.description);
        }];
    }
    
    if (!self.contact_ref_handle_removed) {
        self.contact_ref_handle_removed =
        [self.contactsRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSLog(@"FIREBASE: REMOVED CONTACT SNAPSHOT: %@", snapshot);
                ChatUser *contact = [ChatContactsSynchronizer contactFromSnapshotFactory:snapshot];
                if (contact) {
                    [self removeContactOnDB:contact];
                }
            });
        } withCancelBlock:^(NSError *error) {
            NSLog(@"%@", error.description);
        }];
    }
}

-(void)startSynchTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"STARTSYNCH!");
        self.synchronizing = YES;
//       if (self.synchTimer) {
//           if ([self.synchTimer isValid]) {
//               [self.synchTimer invalidate];
//           }
//           self.synchTimer = nil;
//       }
        [self resetSynchTimer];
        self.synchTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(synchTimerPaused:) userInfo:nil repeats:NO];
   });
}

-(void)synchTimerPaused:(NSTimer *)timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Synch off");
        [self setFirstSynchroOver:YES];
        self.synchronizing = NO;
        [self callEndOnSubscribers];
        [self resetSynchTimer];
    });
}

-(void)resetSynchTimer {
    if (self.synchTimer) {
        if ([self.synchTimer isValid]) {
            [self.synchTimer invalidate];
        }
        self.synchTimer = nil;
    }
}

-(NSInteger)lastQueryTime {
    ChatUser *most_recent = [[ChatContactsDB getSharedInstance] getMostRecentContact];
    if (most_recent) {
        NSInteger lasttime = most_recent.createdon * 1000; // objc return time in seconds, firebase saves time in milliseconds. queryStartingAtValue: will respond to events at nodes with a value greater than or equal to startValue. So seconds is always < then milliseconds. Multplying by 1000 translates seconds in millis and so the query is ok.
        return lasttime;
    }
    else {
        return 0;
    }
}

static NSString *LAST_CONTACTS_TIMESTAMP_KEY = @"last-contacts-timestamp";
static NSString *FIRST_SYNCHRO_KEY = @"first-contacts-synchro";

-(void)saveLastTimestamp:(NSInteger)timestamp {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    [userPreferences setInteger:timestamp forKey:LAST_CONTACTS_TIMESTAMP_KEY];
    [userPreferences synchronize];
}

-(NSInteger)restoreLastTimestamp {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    NSInteger timestamp = (NSInteger)[userPreferences integerForKey:LAST_CONTACTS_TIMESTAMP_KEY];
    return timestamp;
}

-(void)setFirstSynchroOver:(BOOL)isOver {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    NSString *userId = [ChatManager getInstance].loggedUser.userId;
    NSString *synchroKey = [[NSString alloc] initWithFormat:@"%@-%@",FIRST_SYNCHRO_KEY, userId];
    [userPreferences setBool:isOver forKey:synchroKey];
    [userPreferences synchronize];
}

-(BOOL)getFirstSynchroOver {
    NSString *userId = [ChatManager getInstance].loggedUser.userId;
    NSString *synchroKey = [[NSString alloc] initWithFormat:@"%@-%@",FIRST_SYNCHRO_KEY, userId];
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    BOOL firstSinchro = (BOOL)[userPreferences boolForKey:synchroKey];
    return firstSinchro;
}

//-(void)stopSynchro {
//    [self.contactsRef removeAllObservers];
//}

-(void)firstLoadWithCompletion:(void(^)()) callback {
    // FIRST SYNCHRONIZE CONTACTS FROM FILE
    NSString *contacts_path = [[NSBundle mainBundle] pathForResource:@"bppmobileintranet-contacts" ofType:@"json"];
    NSData *contacts_data = [NSData dataWithContentsOfFile:contacts_path];
    NSDictionary *contacts_dict = [NSJSONSerialization JSONObjectWithData:contacts_data options:kNilOptions error:nil];
    for (NSString* key in contacts_dict) {
        ChatUser *user = [ChatContactsSynchronizer contactFromDictionaryFactory:contacts_dict[key]];
//        NSLog(@"name: %@, id: %@", user.lastname, user.userId);
        [[ChatContactsDB getSharedInstance] insertContact:user];
    }
    [self setFirstSynchroOver:YES];
    callback();
}

-(void)insertOrUpdateContactOnDB:(ChatUser *)user {
//    NSLog(@"INSERTING OR UPDATING CONTACT WITH NAME: %@ (%@ %@)", user.userId, user.firstname, user.lastname);
    __block ChatUser *_user = user;
    [[ChatContactsDB getSharedInstance] insertOrUpdateContactSyncronized:_user completion:^{
        self.synchronizing ? NSLog(@"SYNCHRONIZING") : NSLog(@"NO-SYNCHRONIZING");
        _user = nil;
        [self startSynchTimer];
    }];
}

-(void)removeContactOnDB:(ChatUser *)user {
    NSLog(@"REMOVING CONTACT: %@ (%@ %@)", user.userId, user.firstname, user.lastname);
    [[ChatContactsDB getSharedInstance] removeContactSynchronized:user.userId completion:nil];
}

-(void)dispose {
//    [self.contactsRef removeObserverWithHandle:self.contact_ref_handle_added];
//    [self.contactsRef removeObserverWithHandle:self.contact_ref_handle_changed];
//    [self.contactsRef removeObserverWithHandle:self.contact_ref_handle_removed];
    [self.contactsRef removeAllObservers];
}

+(ChatUser *)contactFromSnapshotFactory:(FIRDataSnapshot *)snapshot {
    //    NSLog(@"Snapshot.value is of type: %@", [snapshot.value class]); // [snapshot.value boolValue]
    if (![snapshot.value isKindOfClass:[NSString class]]) {
        NSString *userId = userId = snapshot.value[FIREBASE_USER_ID];
        if (!userId) { // user_id can t be null
            NSLog(@"ERROR. NO UID. INVALID USER.");
            return nil;
        }
        else if (![snapshot.value[FIREBASE_USER_ID] isKindOfClass:[NSString class]]) { // user_id must be a string
            NSLog(@"ERROR. NO UID. INVALID USER.");
            return nil;
        }
        
        NSString *name = snapshot.value[FIREBASE_USER_FIRSTNAME];
        if (!name) {
            name = @"";
        }
        else if ([snapshot.value[FIREBASE_USER_FIRSTNAME] isKindOfClass:[NSString class]]) { // must be a string
            name = snapshot.value[FIREBASE_USER_FIRSTNAME];
        }
        else {
            name = @"";
        }
        
        NSString *lastname = snapshot.value[FIREBASE_USER_LASTNAME];
        if (!lastname) {
            lastname = @"";
        }
        else if ([snapshot.value[FIREBASE_USER_LASTNAME] isKindOfClass:[NSString class]]) { // must be a string
            lastname = snapshot.value[FIREBASE_USER_LASTNAME];
        }
        else {
            lastname = @"";
        }
        
        NSString *email = snapshot.value[FIREBASE_USER_EMAIL];
        if (!email) {
            email = @"";
        }
        else if ([snapshot.value[FIREBASE_USER_EMAIL] isKindOfClass:[NSString class]]) { // must be a string
            email = snapshot.value[FIREBASE_USER_EMAIL];
        }
        else {
            email = @"";
        }
        
        NSString *imageurl = snapshot.value[FIREBASE_USER_IMAGEURL];
        if (!imageurl) {
            imageurl = @"";
        }
        else if ([snapshot.value[FIREBASE_USER_IMAGEURL] isKindOfClass:[NSString class]]) { // must be a string
            imageurl = snapshot.value[FIREBASE_USER_IMAGEURL];
        }
        else {
            imageurl = @"";
        }
        
        NSNumber *createdon = snapshot.value[FIREBASE_USER_TIMESTAMP];
        
        ChatUser *contact = [[ChatUser alloc] init];
        contact.firstname = name;
        contact.lastname = lastname;
        contact.userId = userId;
        contact.email = email;
        contact.imageurl = imageurl;
        contact.createdon = [createdon integerValue] / 1000; // firebase timestamp is in millis
        return contact;
    }
    else {
        NSLog(@"ERROR. USER IS A STRING. MUST BE A DICTIONARY.");
    }
    return nil;
}

+(ChatUser *)contactFromDictionaryFactory:(NSDictionary *)snapshot {
    NSString *userId = userId = snapshot[FIREBASE_USER_ID];
    if (!userId) { // user_id can t be null
        NSLog(@"ERROR. NO UID. INVALID USER.");
        return nil;
    }
    else if (![snapshot[FIREBASE_USER_ID] isKindOfClass:[NSString class]]) { // user_id must be a string
        NSLog(@"ERROR. NO UID. INVALID USER.");
        return nil;
    }
    
    NSString *name = snapshot[FIREBASE_USER_FIRSTNAME];
    if (!name) {
        name = @"";
    }
    else if ([snapshot[FIREBASE_USER_FIRSTNAME] isKindOfClass:[NSString class]]) { // must be a string
        name = snapshot[FIREBASE_USER_FIRSTNAME];
    }
    else {
        name = @"";
    }
    
    NSString *lastname = snapshot[FIREBASE_USER_LASTNAME];
    if (!lastname) {
        lastname = @"";
    }
    else if ([snapshot[FIREBASE_USER_LASTNAME] isKindOfClass:[NSString class]]) { // must be a string
        lastname = snapshot[FIREBASE_USER_LASTNAME];
    }
    else {
        lastname = @"";
    }
    
    NSString *email = snapshot[FIREBASE_USER_EMAIL];
    if (!email) {
        email = @"";
    }
    else if ([snapshot[FIREBASE_USER_EMAIL] isKindOfClass:[NSString class]]) { // must be a string
        email = snapshot[FIREBASE_USER_EMAIL];
    }
    else {
        email = @"";
    }
    
    NSString *imageurl = snapshot[FIREBASE_USER_IMAGEURL];
    if (!imageurl) {
        imageurl = @"";
    }
    else if ([snapshot[FIREBASE_USER_IMAGEURL] isKindOfClass:[NSString class]]) { // must be a string
        imageurl = snapshot[FIREBASE_USER_IMAGEURL];
    }
    else {
        imageurl = @"";
    }
    
    NSNumber *createdon = snapshot[FIREBASE_USER_TIMESTAMP];
    
    ChatUser *contact = [[ChatUser alloc] init];
    contact.firstname = name;
    contact.lastname = lastname;
    contact.userId = userId;
    contact.email = email;
    contact.imageurl = imageurl;
    contact.createdon = [createdon integerValue] / 1000; // firebase timestamp is in millis
    return contact;
}

@end
