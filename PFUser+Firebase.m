//
//  PFUser+Firebase.m
//  Umwho
//
//  Created by Felix Dumit on 6/17/17.
//  Copyright © 2017 Umwho. All rights reserved.
//

#import "PFUser+Firebase.h"
#import <FirebaseAuth/FirebaseAuth.h>
#import <FirebasePhoneAuthUI/FirebasePhoneAuthUI.h>
@import DigitsMigrationHelper;

NSString* const PFFirebaseAuthenticationType = @"firebase";

static NSString *const kFirebaseAuthParamId = @"id";
static NSString *const kFirebaseAuthParamToken = @"access_token";
static NSString *const kFirebaseAuthParamPhone = @"phone";
static NSString *const kFirebaseAuthParamEmail = @"email";
static NSString *const kFirebaseAuthParamEmailVerified = @"email_verified";



@interface PFFirebaseDelegate : NSObject<PFUserAuthenticationDelegate, FUIAuthDelegate>

@property (strong, nonatomic) BFTaskCompletionSource<FIRUser*>* loginTCS;
+(NSDictionary<NSString *,NSString *> *)authDataForUser:(nonnull FIRUser*)user;
+(instancetype)sharedInstance;

@end

@interface FIRUser (Token)

@property (strong, nonatomic, nullable, readonly) NSString* token;

@end

@implementation PFUser (Firebase)


+(void) enableFirebaseLogin {
    PFFirebaseDelegate* del = [PFFirebaseDelegate sharedInstance];
    [PFUser registerAuthenticationDelegate:del forAuthType:PFFirebaseAuthenticationType];
}

- (BOOL)isLinkedWithFirebase
{
    return [self isLinkedWithAuthType:PFFirebaseAuthenticationType];
}


-(NSDictionary*)firebaseAuthData {
    return [self valueForKeyPath:@"authData"][PFFirebaseAuthenticationType];
}

-(NSString *)firebaseId {
    return [self firebaseAuthData][kFirebaseAuthParamId];
}

-(NSString*)firebaseEmail {
    return [self firebaseAuthData][kFirebaseAuthParamEmail];
}

-(NSString*)firebasePhone {
    return [self firebaseAuthData][kFirebaseAuthParamPhone];
}

-(BOOL)firebaseEmailVerified {
    return [[self firebaseAuthData][kFirebaseAuthParamEmailVerified] boolValue];
}

#pragma mark - Parse Firebase Login
+ (BFTask*) cleanupFirebaseSessionAfterLogout
{
    NSError* error = nil;
    [[FIRAuth auth] signOut:&error];
    if(error) {
        return [BFTask taskWithError:error];
    }
    return [BFTask taskWithResult:nil];
}


+ (void)loginWithFirebaseInBackground:(void (^)(__kindof PFUser *user, NSError *error))block
{
    [[self loginWithFirebaseInBackground]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock: ^id (BFTask *task) {
         if (block) {
             block(task.result, task.error);
         }
         
         return nil;
     }];
}

+ (BFTask<__kindof PFUser *> *)loginWithFirebaseInBackground
{
    return [[self authenticateWithFirebase] continueWithSuccessBlock:^id _Nullable(BFTask<FIRUser *> * _Nonnull task) {
        return [PFUser logInWithAuthTypeInBackground:PFFirebaseAuthenticationType
                                            authData:[PFFirebaseDelegate authDataForUser:task.result]];
    }];
}


#pragma mark - Parse Digits link
- (void)linkWithFirebaseInBackground:(void (^)(BOOL, NSError * _Nonnull))block
{
    [[self linkWithFirebaseInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                    withBlock: ^id (BFTask *task) {
                                                        if (block) {
                                                            block(task.error == nil, task.error);
                                                        }
                                                        
                                                        return nil;
                                                    }];
}

- (BFTask<NSNumber *> *)linkWithFirebaseInBackground
{
    return [[[self class] authenticateWithFirebase] continueWithSuccessBlock:^id _Nullable(BFTask<FIRUser *> * _Nonnull task) {
        return [self linkWithAuthTypeInBackground:PFFirebaseAuthenticationType
                                         authData:[PFFirebaseDelegate authDataForUser:task.result]];
    }];
}

-(BFTask<NSNumber *> *)unlinkWithFirebase {
    return [self unlinkWithAuthTypeInBackground:PFFirebaseAuthenticationType];
}

#pragma mark - Firebase
+ (BFTask <FIRUser *> *)authenticateWithFirebase {
    
    BFTaskCompletionSource *tcs = [BFTaskCompletionSource taskCompletionSource];
    // USE THIS FOR MANUAL SETUP
    //    [[FIRPhoneAuthProvider provider] verifyPhoneNumber:@"+15094601408" completion:^(NSString * _Nullable verificationID, NSError * _Nullable error) {
    //        NSLog(@"Sent verification: %@ -> %@", verificationID, error);
    //        FIRPhoneAuthCredential* credential = [[FIRPhoneAuthProvider provider] credentialWithVerificationID:verificationID verificationCode:@"CODE_HERE"];
    //        [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
    //            NSLog(@"Logged in: %@ - %@", user, error);
    //        }];
    //    }];
    
    UIViewController* vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    FUIAuth* auth = [FUIAuth defaultAuthUI];
    auth.delegate = [PFFirebaseDelegate sharedInstance];
    FUIPhoneAuth* phoneAuth = [[FUIPhoneAuth alloc] initWithAuthUI:auth];
    auth.providers = @[phoneAuth];
    [phoneAuth signInWithPresentingViewController:vc];
    
    [PFFirebaseDelegate sharedInstance].loginTCS = tcs;
    
    return tcs.task;
}

- (BFTask<NSNumber*>*)tryMigrateDigitsSessionWithConsumerKey:(NSString*)consumerKey consumerSecret:(NSString*) consumerSecret {
    
    FIRDigitsMigrator *migrator = [[FIRDigitsMigrator alloc]
                                   initWithDigitsAppConsumerKey:consumerKey withDigitsAppConsumerSecret:consumerSecret];
    
    BFTaskCompletionSource* tcs = [BFTaskCompletionSource taskCompletionSource];
    
    [migrator getLegacyAuth:^(NSString * _Nullable customSignInToken, FIRDigitsSession * _Nullable session) {
        if(customSignInToken) {
            NSLog(@"Migrating digits user to firebase.");
            [[FIRAuth auth] signInWithCustomToken:customSignInToken
                                       completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                           if(error) {
                                               [tcs trySetError:error];
                                           } else {
                                               [tcs trySetResult:user];
                                           }
                                       }];
        } else {
            [tcs trySetResult:nil];
        }
    }];
    
    return [tcs.task continueWithBlock:^id _Nullable(BFTask<FIRUser *> * _Nonnull t) {
        if(t.result) {
            return [[self linkWithAuthTypeInBackground:PFFirebaseAuthenticationType
                                              authData:[PFFirebaseDelegate authDataForUser:t.result]] continueWithSuccessBlock:^id _Nullable(BFTask<NSNumber *> * _Nonnull t) {
                
                [migrator clearLegacyAuth:^(BOOL success, NSError * _Nullable error) {
                    
                }];
                return t;
            }];
            
        }
        return @NO;
    }];
}

@end

@implementation PFFirebaseDelegate

+ (instancetype)sharedInstance {
    static PFFirebaseDelegate* _sharedInstance = nil;
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
    
    FIRUser* user = [[FIRAuth auth] currentUser];
    if(![user.uid isEqualToString:authData[kFirebaseAuthParamId]] || ![user.token isEqualToString:authData[kFirebaseAuthParamToken]]) {
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


+(NSDictionary<NSString *,NSString *> *)authDataForUser:(FIRUser *)user {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    dict[kFirebaseAuthParamId] = user.uid;
    dict[kFirebaseAuthParamToken] = user.token;
    dict[kFirebaseAuthParamPhone] = user.phoneNumber;
    if(user.email) {
        dict[kFirebaseAuthParamEmail] = user.email;
        dict[kFirebaseAuthParamEmailVerified] = @(user.isEmailVerified);
    }
    //    user.displayName;
    //    user.photoURL;
    return [dict copy];
}

- (void)authUI:(FUIAuth *)authUI
didSignInWithUser:(nullable FIRUser *)user
         error:(nullable NSError *)error {
    
    if(error) {
        [self.loginTCS trySetError:error];
        return;
    }
    [user getIDTokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if(error) {
            [self.loginTCS trySetError:error];
        }
        [self.loginTCS trySetResult:user];
    }];
}

@end

@implementation FIRUser (Token)

-(NSString *)token {
    return [self valueForKeyPath:@"tokenService.accessToken"];
}

@end

