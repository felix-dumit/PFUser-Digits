//
//  PFUser+Digits.h
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@class DGTAppearance;

@interface PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void(^) (PFUser * user, NSError * error))block;
+ (void)loginWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance completion:(void(^) (PFUser * user, NSError * error))block;

+ (BFTask<PFUser*> *)loginWithDigitsInBackground;
+ (BFTask<PFUser*> *)loginWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance;

- (void)linkWithDigitsInBackground:(void(^) (BOOL succeeded, NSError * error))block;

- (void)linkWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance completion:(void(^) (BOOL succeeded, NSError * error))block;

- (BFTask<NSNumber*> *)linkWithDigitsInBackground;
- (BFTask<NSNumber*> *)linkWithDigitsInBackgroundWithTitle:(NSString *)title appearance:(DGTAppearance*)appearance;

- (BOOL)isLinkedWithDigits;


@end
