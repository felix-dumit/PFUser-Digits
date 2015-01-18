//
//  PFUser+Digits.m
//
//  Created by Felix Dumit on 11/6/14.
//  Copyright (c) 2015 Felix Dumit. All rights reserved.
//

#import <Bolts/Bolts.h>
#import <TwitterKit/TwitterKit.h>
#import "PFUser+Digits.h"


@implementation PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block {
    [self loginWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil completion:block];
}

+ (void)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor completion:(void (^)(PFUser *user, NSError *error))block {
    [[self loginWithDigitsInBackgroundWithTitle:title backgroundColor:backgroundColor accentColor:accentColor] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock: ^id (BFTask *task) {
        if (block) {
            block(task.result, task.error);
        }
        return nil;
    }];
}

+ (BFTask *)loginWithDigitsInBackground {
    return [self loginWithDigitsInBackgroundWithTitle:nil backgroundColor:nil accentColor:nil];
}

+ (BFTask *)loginWithDigitsInBackgroundWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor accentColor:(UIColor *)accentColor {
    
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];

    DGTAppearance *appeareance = [[DGTAppearance alloc] init];
    appeareance.backgroundColor = backgroundColor;
    appeareance.accentColor = accentColor;    
    
    [[Digits sharedInstance] authenticateWithDigitsAppearance:appeareance viewController:nil title:title completion: ^(DGTSession *session, NSError *error) {
        if (error) {
            [taskCompletion setError:error];
            return;
        }
        [[[PFCloud callFunctionInBackground:@"loginWithDigits"
                             withParameters:@{
                                              @"userId": session.userID,
                                              @"phoneNumber": session.phoneNumber
                                              }
           ]
          continueWithSuccessBlock: ^id (BFTask *task) {
              return [PFUser becomeInBackground:task.result];
          }]
         continueWithBlock: ^id (BFTask *task) {
              [[PFUser currentUser] setObject:session.phoneNumber forKey:@"phone"];
              if (task.error) {
                    [taskCompletion setError:error];
                }
                else {
                    [taskCompletion setResult:task.result];
                }
              return nil;
         }];
    }];
    return taskCompletion.task;
}

@end
