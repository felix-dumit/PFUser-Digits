//
//  PFUser+Digits.h
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix. All rights reserved.


#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@class DGTAuthenticationConfiguration;

@interface PFUser (Digits)

+(void) enableDigitsLogin;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable digitsId;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable digitsEmail;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable digitsPhone;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL digitsEmailVerified;

+ (void) cleanupDigitsSessionAfterLogout;

+ (void)loginWithDigitsInBackground:(void (^) (__kindof PFUser * _Nullable, NSError * _Nullable))block;
+ (void)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (__kindof PFUser *, NSError *error))block;

+ (BFTask<__kindof PFUser *> *)  loginWithDigitsInBackground;
+ (BFTask<__kindof PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;

- (void)linkWithDigitsInBackground:(void (^) (BOOL succeeded, NSError *error))block;

- (void)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (BOOL succeeded, NSError *error))block;

- (BFTask<NSNumber *> *)linkWithDigitsInBackground;
- (BFTask<NSNumber *> *)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;
- (BFTask<NSNumber *> *)unlinkWithDigits;


@property (NS_NONATOMIC_IOSONLY, getter=isLinkedWithDigits, readonly) BOOL linkedWithDigits;


@end

NS_ASSUME_NONNULL_END
