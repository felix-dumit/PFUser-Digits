//
//  PFUser+Digits.h
//  NameBrain2
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block;
+ (void)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor completion:(void (^)(PFUser *user, NSError *error))block;

+ (BFTask *)loginWithDigitsInBackground;
+ (BFTask *)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor;

@end
