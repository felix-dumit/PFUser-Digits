//
//  PFUser+Digits.m
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2017 Felix Dumit. All rights reserved.
//

#import <Bolts/Bolts.h>
#import <DigitsKit/DigitsKit.h>
#import "PFUser+Digits.h"

//TODO: change to digits?
NSString *const PFDigitsAuthenticationType = @"twitter";


static NSString *const kDigitsAuthParamToken = @"auth_token";
static NSString *const kDigitsAuthParamTokenSecret = @"auth_token_secret";
static NSString *const kDigitsAuthParamId = @"id";
static NSString *const kDigitsAuthParamPhone = @"phone";
static NSString *const kDigitsAuthParamEmail = @"email";
static NSString *const kDigitsAuthParamEmailVerified = @"email_verified";

@interface PFDigitsDelegate : NSObject<PFUserAuthenticationDelegate, DGTSessionUpdateDelegate>

+(NSDictionary<NSString *,NSString *> *)authDataForSession:(nonnull DGTSession*)session;
+(instancetype)sharedInstance;

@end

@implementation PFUser (Digits)

+(void) enableDigitsLogin {
    PFDigitsDelegate* del = [PFDigitsDelegate sharedInstance];
    [PFUser registerAuthenticationDelegate:del forAuthType:PFDigitsAuthenticationType];
    [Digits sharedInstance].sessionUpdateDelegate = del;
}

- (BOOL)isLinkedWithDigits
{
    return [self isLinkedWithAuthType:PFDigitsAuthenticationType];
}


-(NSDictionary*)digitsAuthData {
    return [self valueForKeyPath:@"authData"][PFDigitsAuthenticationType];
}

-(NSString *)digitsId {
    return [self digitsAuthData][kDigitsAuthParamId];
}

-(NSString*)digitsEmail {
    return [self digitsAuthData][kDigitsAuthParamEmail];
}

-(NSString*)digitsPhone {
    return [self digitsAuthData][kDigitsAuthParamPhone];
}

-(BOOL)digitsEmailVerified {
    return [self digitsAuthData][kDigitsAuthParamEmailVerified] != nil;
}

#pragma mark - Parse Digits Login
+ (void)loginWithDigitsInBackground:(void (^)(__kindof PFUser *user, NSError *error))block
{
    [self loginWithDigitsInBackgroundWithConfiguration:nil completion:block];
}

+ (void)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration completion:(void (^)(__kindof PFUser *, NSError *))block
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

+ (BFTask<__kindof PFUser *> *)loginWithDigitsInBackground
{
    return [self loginWithDigitsInBackgroundWithConfiguration:nil];
}

+ (BFTask<__kindof PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration
{
    return [[self authenticateWithDigitsWithConfiguration:configuration] continueWithSuccessBlock:^id _Nullable(BFTask<DGTSession *> * _Nonnull task) {
        return [PFUser logInWithAuthTypeInBackground:PFDigitsAuthenticationType authData:[PFDigitsDelegate authDataForSession:task.result]];
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
    return [[[self class] authenticateWithDigitsWithConfiguration:configuration] continueWithSuccessBlock:^id _Nullable(BFTask<DGTSession *> * _Nonnull task) {
        return [self linkWithDigitsSession:task.result];
    }];
}

-(BFTask<NSNumber *> *)linkWithDigitsSession:(DGTSession*)session {
    return [self linkWithAuthTypeInBackground:PFDigitsAuthenticationType authData:[PFDigitsDelegate authDataForSession:session]];
}

-(BFTask<NSNumber *> *)unlinkWithDigits {
    return [self unlinkWithAuthTypeInBackground:PFDigitsAuthenticationType];
}

#pragma mark - Digits
+ (BFTask <DGTSession *> *)authenticateWithDigitsWithConfiguration:(DGTAuthenticationConfiguration*)configuration {
    
    BFTaskCompletionSource* tcs = [BFTaskCompletionSource taskCompletionSource];
    [[Digits sharedInstance] authenticateWithViewController:nil configuration:configuration completion:^(DGTSession *session, NSError *error) {
        if(error){
            if([error.domain isEqualToString:@"DigitsErrorDomain"] && error.code == 1) {
                [tcs trySetCancelled];
            } else {
                [tcs trySetError:error];
            }
        } else {
            [tcs trySetResult:session];
        }
    }];
    
    return tcs.task;
}

@end


@implementation PFDigitsDelegate

+ (instancetype)sharedInstance {
    static PFDigitsDelegate* _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

-(BOOL)restoreAuthenticationWithAuthData:(NSDictionary<NSString *,NSString *> *)authData {
    if (![authData isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    DGTSession* session = [Digits sharedInstance].session;
    if(![session.userID isEqualToString:authData[kDigitsAuthParamId]] ||
       ![session.authToken isEqualToString:authData[kDigitsAuthParamToken]]) {
        //TODO: figure out how to do something like this (similar to how FB auth works:
        //        [Digits sharedInstance].session = [[DGTSession alloc] initWithAuthToken:authData[kDigitsAuthParamToken]
        //                                                                authTokenSecret:authData[kDigitsAuthParamTokenSecret]
        //                                                                         userID:authData[kDigitsAuthParamId]
        //                                                                    phoneNumber:authData[kDigitsAuthParamPhone]
        //                                                                   emailAddress:authData[kDigitsAuthParamEmail]
        //                                                         emailAddressIsVerified:authData[kDigitsAuthParamEmailVerified]];
    }
    
    return YES;
}

+(NSDictionary<NSString *,NSString *> *)authDataForSession:(nonnull DGTSession*)session {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    dict[kDigitsAuthParamId] = session.userID;
    dict[kDigitsAuthParamToken] = session.authToken;
    dict[kDigitsAuthParamTokenSecret] = session.authTokenSecret;
    dict[kDigitsAuthParamPhone] = session.phoneNumber;
    dict[kDigitsAuthParamEmailVerified] = @(session.emailAddressIsVerified);
    if(session.emailAddress) dict[kDigitsAuthParamEmail] = session.emailAddress;
    return [dict copy];
}

-(void)digitsSessionHasChanged:(DGTSession *)newSession {
    [[PFUser currentUser] linkWithDigitsSession:newSession];
}

-(void)digitsSessionExpiredForUserID:(NSString *)userID {
    if([[PFUser currentUser].digitsId isEqualToString:userID]) {
        [PFUser logOutInBackground];
    }
}

@end
