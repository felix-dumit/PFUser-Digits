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


-(BOOL)isLinkedWithDigits {
    return !([self objectForKey:@"digitsId"] == nil);
}

#pragma mark - Parse Digits Login
+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block
{
    [self loginWithDigitsInBackgroundWithTitle:nil appearance:nil];
}

+ (void)loginWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance completion:(void (^)(PFUser *user, NSError *error))block
{
    [[self loginWithDigitsInBackgroundWithTitle:title
                                    appearance:appearance]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock: ^id (BFTask *task) {
         if (block) {
             block(task.result, task.error);
         }
         
         return nil;
     }];
}

+ (BFTask<PFUser*> *)loginWithDigitsInBackground
{
    return [self loginWithDigitsInBackgroundWithTitle:nil appearance:nil];
}

+ (BFTask<PFUser*> *)loginWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance{
    return [[[self _privateDigitsLoginWithTitle:title
                                     appearance:appearance
                                    phoneNumber:nil]
             continueWithSuccessBlock: ^id (BFTask *task) {
                 DGTSession *session = [task.result
                                        objectForKey:kSessionKey];
                 NSString *requestURLString = [task.result
                                               objectForKey:kRequestURLStringKey];
                 NSString *authorizationHeader = [task.result
                                                  objectForKey:kAuthorizationHeaderKey];
                 
                 return [PFCloud callFunctionInBackground:@"loginWithDigits"
                                           withParameters:@{
                                                            @"digitsId": session.userID,
                                                            @"phoneNumber": session.phoneNumber,
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
    [self linkWithDigitsInBackgroundWithTitle:nil appearance:nil completion:block];
}

- (void)linkWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance completion:(void (^)(BOOL succeeded, NSError *error))block
{
    [[self linkWithDigitsInBackgroundWithTitle:title
                                   appearance:appearance]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock: ^id (BFTask *task) {
         if (block) {
             block(task.error == nil, task.error);
         }
         
         return nil;
     }];
}

- (BFTask<NSNumber*> *)linkWithDigitsInBackground
{
    return [self linkWithDigitsInBackgroundWithTitle:nil appearance:nil];
}

-(BFTask<NSNumber*> *)linkWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance *)appearance {

    return [[[[[self class] _privateDigitsLoginWithTitle:title
                                             appearance:appearance
                                            phoneNumber:[self objectForKey:@"phone"]]
             continueWithSuccessBlock: ^id (BFTask *task) {
                 DGTSession *session = [task.result
                                        objectForKey:kSessionKey];
                 NSString *requestURLString = [task.result
                                               objectForKey:kRequestURLStringKey];
                 NSString *authorizationHeader = [task.result
                                                  objectForKey:kAuthorizationHeaderKey];

                 return [PFCloud callFunctionInBackground:@"linkWithDigits"
                                           withParameters:@{
                                                            @"userId": self.objectId,
                                                            @"digitsId": session.userID,
                                                            @"phoneNumber": session.phoneNumber,
                                                            @"requestURL": requestURLString,
                                                            @"authHeader": authorizationHeader,
                                                            }];
             }] continueWithSuccessBlock:^id (BFTask *task) {
                 return [self fetchInBackground];
             }] continueWithBlock:^id(BFTask *task) {
                 return @(task.error != nil);
             }];
}

#pragma mark - private Digits login
+(BFTask*)_privateDigitsLoginWithTitle:(NSString*)title appearance:(DGTAppearance*)appearance phoneNumber:(NSString*)phoneNumber {
    
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    
    [[Digits sharedInstance] authenticateWithPhoneNumber:phoneNumber
                                        digitsAppearance:appearance
                                          viewController:nil
                                                   title:title
                                              completion:^(DGTSession *session, NSError *error) {
                                                  if (error) {
                                                      [taskCompletion setError:error];
                                                      return;
                                                  }
                                                  
                                                  DGTOAuthSigning *oauthSigning = [[DGTOAuthSigning alloc]  initWithAuthConfig:[Digits sharedInstance].authConfig
                                                                                                                   authSession:session];
                                                  
                                                  NSDictionary *authHeaders = [oauthSigning OAuthEchoHeadersToVerifyCredentials];
                                                  NSString *requestURLString = authHeaders[TWTROAuthEchoRequestURLStringKey];
                                                  NSString *authorizationHeader = authHeaders[TWTROAuthEchoAuthorizationHeaderKey];
                                                  
                                                  [taskCompletion setResult:@{ kSessionKey: session,
                                                                               kRequestURLStringKey: requestURLString,
                                                                               kAuthorizationHeaderKey: authorizationHeader }];
                                              }];
    
    return taskCompletion.task;
}

@end
