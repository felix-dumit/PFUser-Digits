//
//  PFUser+Firebase.h
//  Umwho
//
//  Created by Felix Dumit on 6/17/17.
//  Copyright © 2017 Umwho. All rights reserved.
//

#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface PFUser (Firebase)

+(void) enableFirebaseLogin;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable firebaseId;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable firebaseEmail;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable firebasePhone;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL firebaseEmailVerified;

+ (BFTask*) cleanupFirebaseSessionAfterLogout;

+ (void)loginWithFirebaseInBackground:(void (^) (__kindof PFUser * _Nullable, NSError * _Nullable))block;
+ (BFTask<__kindof PFUser *> *)  loginWithFirebaseInBackground;

- (void)linkWithFirebaseInBackground:(void (^) (BOOL succeeded, NSError *error))block;
- (BFTask<NSNumber *> *)linkWithFirebaseInBackground;

- (BFTask<NSNumber *> *)unlinkWithFirebase;

- (BFTask<NSNumber*>*)tryMigrateDigitsSessionWithConsumerKey:(NSString*)consumerKey consumerSecret:(NSString*) consumerSecret;

@property (NS_NONATOMIC_IOSONLY, getter=isLinkedWithFirebase, readonly) BOOL linkedWithFirebase;

@end

NS_ASSUME_NONNULL_END
