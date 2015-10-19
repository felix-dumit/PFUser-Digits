//
//  PFUser+Digits.h
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@class DGTAuthenticationConfiguration;

@interface PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void (^) (PFUser *user, NSError *error))block;
+ (void)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration completion:(void (^) (PFUser *user, NSError *error))block;

+ (BFTask<PFUser *> *)  loginWithDigitsInBackground;
+ (BFTask<PFUser *> *)loginWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration;

- (void)linkWithDigitsInBackground:(void (^) (BOOL succeeded, NSError *error))block;

- (void)linkWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration completion:(void (^) (BOOL succeeded, NSError *error))block;

- (BFTask<NSNumber *> *)linkWithDigitsInBackground;
- (BFTask<NSNumber *> *)linkWithDigitsInBackgroundWithConfiguration:(DGTAuthenticationConfiguration *)configuration;

- (BOOL)                isLinkedWithDigits;


@end
