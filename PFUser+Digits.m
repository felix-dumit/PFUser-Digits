//
//  PFUser+Digits.m
//
//  Created by Felix Dumit on 2/3/14.
//  Copyright (c) 2014 Felix Dumit. All rights reserved.
//

#import <Bolts/Bolts.h>
#import <TwitterKit/TwitterKit.h>
#import "PFUser+Digits.h"



@implementation PFUser (Digits)

+ (void)loginWithDigitsInBackground:(void (^)(PFUser *user, NSError *error))block {
    [[self loginWithDigitsInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock: ^id (BFTask *task) {
        block(task.result, task.error);
        return nil;
    }];
}

+ (BFTask *)loginWithDigitsInBackground {
    BFTaskCompletionSource *taskCompletion = [BFTaskCompletionSource taskCompletionSource];
    
    [[Digits sharedInstance] authenticateWithCompletion: ^(DGTSession *session, NSError *error) {
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
