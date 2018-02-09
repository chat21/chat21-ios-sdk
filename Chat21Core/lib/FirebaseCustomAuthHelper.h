//
//  FirebaseCustomAuthHelper.h
//  Soleto
//
//  Created by Andrea Sponziello on 13/11/14.
//
//

#import <Foundation/Foundation.h>

@import Firebase;
//@class Firebase;
@class FAuthData;

@interface FirebaseCustomAuthHelper : NSObject

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSString *token;

- (id) initWithFirebaseRef:(FIRDatabaseReference *)ref token:(NSString *)token;

- (void) authenticate:(void (^)(NSError *, FAuthData *authData))callback;

@end
