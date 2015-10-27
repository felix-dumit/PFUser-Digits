//
//  PFUser+Digits.m
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix Dumit. All rights reserved.
//

#import <Bolts/Bolts.h>
#import <DigitsKit/DigitsKit.h>
#import "PFUser+Digits.h"

static NSString *const kSessionKey = @"session";
static NSString *const kRequestURLStringKey = @"requestURLString";
static NSString *const kAuthorizationHeaderKey = @"authorizationHeader";


@implementation PFUser (Digits)


- (BOOL)isLinkedWithDigits
{
    return !(self[@"digitsId"] == nil);
}

#pragma mark - Parse Digits Login
+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block
{
    [self loginWithDigitsInBackgroundWithConfiguration:nil completion:block];
}

+ (void)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration completion:(void (^)(PFUser *, NSError *))block
{
    [[self loginWithDigitsInBackgroundWithConfiguration:configuration]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock: ^id (BFTask *task) {
         if (block) {
             block(task.result, task.error);
         }
         
         return nil;
     }];
}

+ (BFTask<PFUser *> *)loginWithDigitsInBackground
{
    return [self loginWithDigitsInBackgroundWithConfiguration:nil];
}

+ (BFTask<PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration
{
    return [[[self _privateDigitsLoginWithConfiguration:configuration]
             continueWithSuccessBlock: ^id (BFTask *task) {
                 NSString *requestURLString = task.result[kRequestURLStringKey];
                 NSString *authorizationHeader = task.result[kAuthorizationHeaderKey];
                 
                 return [PFCloud callFunctionInBackground:@"loginWithDigits"
                                           withParameters:@{
                                                            @"requestURL": requestURLString,
                                                            @"authHeader": authorizationHeader,
                                                            }];
             }]
            continueWithSuccessBlock: ^id (BFTask *task) {
                return [PFUser becomeInBackground:task.result];
            }];
}

#pragma mark - Parse Digits link
- (void)linkWithDigitsInBackground:(void (^)(BOOL succeeded, NSError *error))block
{
    [self linkWithDigitsInBackgroundWithConfiguration:nil completion:block];
}

- (void)linkWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration completion:(void (^)(BOOL, NSError *))block
{
    [[self linkWithDigitsInBackgroundWithConfiguration:configuration]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock: ^id (BFTask *task) {
         if (block) {
             block(task.error == nil, task.error);
         }
         
         return nil;
     }];
}

- (BFTask<NSNumber *> *)linkWithDigitsInBackground
{
    return [self linkWithDigitsInBackgroundWithConfiguration:nil];
}

- (BFTask<NSNumber *> *)linkWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration
{
    configuration.phoneNumber = self[@"phone"];
    return [[[[[self class] _privateDigitsLoginWithConfiguration:configuration] continueWithSuccessBlock: ^id (BFTask *task) {
        NSString *requestURLString = task.result[kRequestURLStringKey];
        NSString *authorizationHeader = task.result[kAuthorizationHeaderKey];
        
        return [PFCloud callFunctionInBackground:@"linkWithDigits"
                                  withParameters:@{
                                                   @"requestURL": requestURLString,
                                                   @"authHeader": authorizationHeader,
                                                   }];
    }] continueWithSuccessBlock:^id (BFTask *task) {
        return [self fetchInBackground];
    }] continueWithBlock:^id (BFTask *task) {
        return @(task.error != nil);
    }];
}

#pragma mark - private Digits login
+ (BFTask *)_privateDigitsLoginWithConfiguration:(DGTAuthenticationConfiguration *)configuration
{
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    
    [[Digits sharedInstance] authenticateWithViewController:nil
                                              configuration:configuration
                                                 completion:^(DGTSession *session, NSError *error) {
                                                     if (error) {
                                                         [taskCompletion trySetError:error];
                                                         return;
                                                     }
                                                     
                                                     DGTOAuthSigning *oauthSigning = [[DGTOAuthSigning alloc]
                                                                                      initWithAuthConfig:[Digits sharedInstance].authConfig
                                                                                      authSession:[Digits sharedInstance].session];
                                                     
                                                     NSDictionary *authHeaders = [oauthSigning OAuthEchoHeadersToVerifyCredentials];
                                                     NSString *requestURLString = authHeaders[TWTROAuthEchoRequestURLStringKey];
                                                     NSString *authorizationHeader = authHeaders[TWTROAuthEchoAuthorizationHeaderKey];
                                                     
                                                     [taskCompletion trySetResult:@{ kSessionKey: session,
                                                                                     kRequestURLStringKey: requestURLString,
                                                                                     kAuthorizationHeaderKey: authorizationHeader }];
                                                 }];
    
    return taskCompletion.task;
}

@end
