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


#pragma mark - Parse Digits Login
+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block {
    [self loginWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil completion:block];
}

+ (void)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor completion:(void (^)(PFUser *user, NSError *error))block {
    [[self loginWithDigitsInBackgroundWithTitle:title backgroundColor:backgroundColor accentColor:accentColor] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock: ^id (BFTask *task) {
        if (block) {
            block(task.result, task.error);
        }
        return nil;
    }];
}

+ (BFTask *)loginWithDigitsInBackground {
    return [self loginWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil];
}

+ (BFTask *)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor {
    DGTAppearance *appeareance = [[DGTAppearance alloc] init];
    appeareance.backgroundColor = backgroundColor;
    appeareance.accentColor = accentColor;
    
    
    return [[[self _privateDigitsLoginWithTitle:title backgroundColor:backgroundColor accentColor:accentColor]
             continueWithSuccessBlock: ^id (BFTask *task) {
                 DGTSession *session = [task.result objectForKey:kSessionKey];
                 NSString *requestURLString = [task.result objectForKey:kRequestURLStringKey];
                 NSString *authorizationHeader = [task.result objectForKey:kAuthorizationHeaderKey];
                 
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
- (void)linkWithDigitsInBackground:(void (^)(BOOL succeeded, NSError *error))block {
    [self linkWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil completion:block];
}

- (void)linkWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor completion:(void (^)(BOOL succeeded, NSError *error))block {
    [[self linkWithDigitsInBackgroundWithTitle:title backgroundColor:backgroundColor accentColor:accentColor] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock: ^id (BFTask *task) {
        if (block) {
            block(task.error == nil, task.error);
        }
        return nil;
    }];
}

- (BFTask *)linkWithDigitsInBackground {
    return [self linkWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil];
}

- (BFTask *)linkWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor {
    DGTAppearance *appeareance = [[DGTAppearance alloc] init];
    appeareance.backgroundColor = backgroundColor;
    appeareance.accentColor = accentColor;
    
    
    return [[[self class] _privateDigitsLoginWithTitle:title backgroundColor:backgroundColor accentColor:accentColor]
            continueWithSuccessBlock: ^id (BFTask *task) {
                DGTSession *session = [task.result objectForKey:kSessionKey];
                NSString *requestURLString = [task.result objectForKey:kRequestURLStringKey];
                NSString *authorizationHeader = [task.result objectForKey:kAuthorizationHeaderKey];
                
                return [PFCloud callFunctionInBackground:@"linkWithDigits"
                                          withParameters:@{
                                                           @"userId": self.objectId,
                                                           @"digitsId": session.userID,
                                                           @"phoneNumber": session.phoneNumber,
                                                           @"requestURL": requestURLString,
                                                           @"authHeader": authorizationHeader,
                                                           }];
            }];
}

- (BOOL)isLinkedWithDigits {
    return !([self objectForKey:@"digitsId"] == nil);
}

#pragma mark - private Digits login

+ (BFTask *)_privateDigitsLoginWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor {
    DGTAppearance *appeareance = [[DGTAppearance alloc] init];
    appeareance.backgroundColor = backgroundColor;
    appeareance.accentColor = accentColor;
    
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    
    [[Digits sharedInstance] authenticateWithDigitsAppearance:appeareance viewController:nil title:title completion: ^(DGTSession *session, NSError *error) {
        if (error) {
            [taskCompletion setError:error];
            return;
        }
        
        DGTOAuthSigning *oauthSigning = [[DGTOAuthSigning alloc] initWithAuthConfig:[Digits sharedInstance].authConfig
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
