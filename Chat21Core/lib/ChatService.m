//
//  ChatService.m
//  tiledesk
//
//  Created by Andrea Sponziello on 08/07/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "ChatService.h"
#import "ChatConversation.h"
#import "ChatManager.h"

@implementation ChatService

+(NSString *)archiveConversationService:(NSString *)conversationId {
    // https://us-central1-chat-v2-dev.cloudfunctions.net/api/tilechat/conversations/support-group-LGdXjl_T98q_Kz3ycdJ
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *host = [ChatManager getInstance].baseURL;
    NSString *archiveConversationURI = [ChatManager getInstance].archiveConversationURI;
    NSString *archiveConversationURIpopulated = [NSString stringWithFormat:archiveConversationURI, tenant, conversationId];
//    NSString *url = [[NSString alloc] initWithFormat:@"%@/api/%@/conversations/%@", host, tenant, conversationId];
    NSString *url = [[NSString alloc] initWithFormat:@"%@%@", host, archiveConversationURIpopulated];
    NSLog(@"archiveConversationService URL: %@", url);
    return url;
}

+(NSString *)archiveAndCloseSupportConversationService:(NSString *)conversationId {
    // https://us-central1-chat-v2-dev.cloudfunctions.net/supportapi/tilechat/groups/support-group-LG9WBQE2mkIKVIhZmHW
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *host = [ChatManager getInstance].baseURL;
    NSString *archiveAndCloseSupportConversationURI = [ChatManager getInstance].archiveAndCloseSupportConversationURI;
    NSString *archiveAndCloseSupportConversationURIpopulated = [NSString stringWithFormat:archiveAndCloseSupportConversationURI, tenant, conversationId];
    NSString *url = [[NSString alloc] initWithFormat:@"%@%@", host, archiveAndCloseSupportConversationURIpopulated];
    NSLog(@"archiveAndCloseSupportConversationService URL: %@", url);
    return url;
}

+(NSString *)deleteProfilePhotoService:(NSString *)userId {
    // https://us-central1-chat-v2-dev.cloudfunctions.net/supportapi/chat21/groups/support-group-LG9WBQE2mkIKVIhZmHW
    NSString *tenant = [ChatManager getInstance].tenant;
    NSString *host = [ChatManager getInstance].baseURL;
    NSString *deleteProfilePhotoURI = [ChatManager getInstance].deleteProfilePhotoURI;
    NSString *deleteProfilePhotoURIpopulated = [NSString stringWithFormat:deleteProfilePhotoURI, tenant];
    NSString *url = [[NSString alloc] initWithFormat:@"%@%@", host, deleteProfilePhotoURIpopulated];
    NSLog(@"deleteProfilePhotoService URL: %@", url);
    return url;
}

+(void)archiveConversation:(ChatConversation *)conversation completion:(void (^)(NSError *error))callback {
    FIRUser *fir_user = [FIRAuth auth].currentUser;
    [fir_user getIDTokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error while getting current Firebase token: %@", error);
            callback(error);
            return;
        }
        NSLog(@"Firebase token ok: %@", token);
        NSString *service_url = [ChatService archiveConversationService:conversation.conversationId];
        NSLog(@"URL: %@", service_url);
        NSURL *url = [NSURL URLWithString:service_url];
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];
        NSString *authorization_field = [[NSString alloc] initWithFormat:@"Bearer %@", token];
        [request addValue:authorization_field forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"DELETE"];
        
        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"firebase auth ERROR: %@", error);
                callback(error);
            }
            else {
                NSString *token = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                NSLog(@"token response: %@", token);
                callback(nil);
            }
        }];
        [task resume];
    }];
}

+(void)archiveAndCloseSupportConversation:(ChatConversation *)conversation completion:(void (^)(NSError *error))callback {
    FIRUser *fir_user = [FIRAuth auth].currentUser;
    [fir_user getIDTokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error while getting current Firebase token: %@", error);
            callback(error);
            return;
        }
        NSLog(@"Firebase token ok: %@", token);
        NSString *service_url = [ChatService archiveAndCloseSupportConversationService:conversation.conversationId];
        NSLog(@"URL: %@", service_url);
        NSURL *url = [NSURL URLWithString:service_url];
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];
        NSString *authorization_field = [[NSString alloc] initWithFormat:@"Bearer %@", token];
        [request addValue:authorization_field forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"PUT"];
        
        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"firebase auth ERROR: %@", error);
                callback(error);
            }
            else {
                NSString *token = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                NSLog(@"token response: %@", token);
                callback(nil);
            }
        }];
        [task resume];
    }];
}

+(void)deleteProfilePhoto:(NSString *)profileId completion:(void (^)(NSError *error))callback {
    FIRUser *fir_user = [FIRAuth auth].currentUser;
    [fir_user getIDTokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if (error) {
            NSLog(@"(DELETE PROFILE) Error while getting current Firebase token: %@", error);
            callback(error);
            return;
        }
        NSLog(@"Firebase token ok: %@", token);
        NSString *service_url = [ChatService deleteProfilePhotoService:profileId];
        NSLog(@"DELETE PROFILE: URL: %@", service_url);
        NSURL *url = [NSURL URLWithString:service_url];
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];
        NSString *authorization_field = [[NSString alloc] initWithFormat:@"Bearer %@", token];
        [request addValue:authorization_field forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"DELETE"];
        
        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"DELETE PROFILE: firebase auth ERROR: %@", error);
                callback(error);
            }
            else {
                NSString *token = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                NSLog(@"DELETE PROFILE OK: token response: %@", token);
                callback(nil);
            }
        }];
        [task resume];
    }];
}

@end
