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

+ (void)loginWithDigitsInBackground:(void (^) (PFUser *user, NSError *error))block;
+ (void)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (PFUser *user, NSError *error))block;

+ (BFTask<PFUser *> *)  loginWithDigitsInBackground;
+ (BFTask<PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;

- (void)linkWithDigitsInBackground:(void (^) (BOOL succeeded, NSError *error))block;

- (void)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration completion:(void (^) (BOOL succeeded, NSError *error))block;

- (BFTask<NSNumber *> *)linkWithDigitsInBackground;
- (BFTask<NSNumber *> *)linkWithDigitsInBackgroundWithConfiguration:(nullable DGTAuthenticationConfiguration *)configuration;

- (BOOL)                isLinkedWithDigits;


@end

NS_ASSUME_NONNULL_END
