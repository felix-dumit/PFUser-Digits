//
//  PFUser+Digits.h
//  NameBrain2
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2014 RockBottom. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block;
+ (BFTask *)loginWithDigitsInBackground;
@end
