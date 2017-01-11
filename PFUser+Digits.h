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

-(nullable NSString *)digitsId;
-(nullable NSString *)digitsEmail;
-(nullable NSString *)digitsPhone;

+ (void)loginWithDigitsInBackground:(void (^) (__kindof PFUser *, NSError *error))block;
+ (void)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (__kindof PFUser *, NSError *error))block;

+ (BFTask<__kindof PFUser *> *)  loginWithDigitsInBackground;
+ (BFTask<__kindof PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;

- (void)linkWithDigitsInBackground:(void (^) (BOOL succeeded, NSError *error))block;

- (void)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (BOOL succeeded, NSError *error))block;

- (BFTask<NSNumber *> *)linkWithDigitsInBackground;
- (BFTask<NSNumber *> *)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;
- (BFTask<NSNumber *> *)unlinkWithDigits;

- (BOOL)                isLinkedWithDigits;


@end

NS_ASSUME_NONNULL_END
