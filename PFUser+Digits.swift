//
//  PFUser+Digits.swift
//  Umwho
//
//  Created by Felix Dumit on 12/15/15.
//  Copyright © 2015 Umwho. All rights reserved.
//

import Foundation
import DigitsKit

extension PFUser {
    
    public typealias LoginCompletionBlock = ((PFUser?, NSError?) -> Void)
    public typealias LinkCompletionBlock = ((Bool, NSError?) -> Void)
    
    private struct Constants {
        static let sessionKey = "session"
        static let requestURLStringKey = "requestURLString"
        static let authorizationHeaderKey = "authorizationHeader"
    }
    
    public var isLinkedWithDigits:Bool {
        return self["digitsId"] != nil
    }
    
    public static func loginWithDigitsInBackground(block:LoginCompletionBlock ) {
        self.loginWithDigitsInBackgroundWithConfiguration(nil, completion: block)
    }
    
    public static func loginWithDigitsInBackgroundWithConfiguration(configuration: DGTAuthenticationConfiguration?, completion block:LoginCompletionBlock ) {
        self.loginWithDigitsInBackgroundWithConfiguration(configuration).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { task in
            block(task.result as? PFUser, task.error)
            return nil
        })
    }
    
    public static func loginWithDigitsInBackground() -> BFTask {
        return self.loginWithDigitsInBackgroundWithConfiguration(nil)
    }
    
    public static func loginWithDigitsInBackgroundWithConfiguration(configuration: DGTAuthenticationConfiguration?) -> BFTask {
        
        return PFUser._privateDigitsLoginWithConfiguration(configuration).continueWithSuccessBlock{ task in
            guard let result = task.result else {
                return nil
            }
            let requestURLString = result[Constants.requestURLStringKey] as! String
            let authorizationHeader = result[Constants.authorizationHeaderKey] as! String
            return PFCloud.callFunctionInBackground("loginWithDigits", withParameters: ["requestURL": requestURLString, "authHeader": authorizationHeader])
            }.continueWithSuccessBlock { PFUser.becomeInBackground($0.result as! String) }
    }
    
    public func linkWithDigitsInBackground(block:LinkCompletionBlock ) {
        self.linkWithDigitsInBackgroundWithConfiguration(nil, completion: block)
    }
    
    public func linkWithDigitsInBackgroundWithConfiguration(configuration: DGTAuthenticationConfiguration?, completion block:LinkCompletionBlock? ) {
        self.linkWithDigitsInBackgroundWithConfiguration(configuration).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { task in
                block?(task.error == nil, task.error)
                return nil
        })
    }
    
    public func linkWithDigitsInBackground() -> BFTask {
        return self.linkWithDigitsInBackgroundWithConfiguration(nil)
    }
    
    public func linkWithDigitsInBackgroundWithConfiguration(configuration: DGTAuthenticationConfiguration?) -> BFTask {
        if let phone = self["phone"] as? String {
            configuration?.phoneNumber = phone
        }
        
        return PFUser._privateDigitsLoginWithConfiguration(configuration).continueWithSuccessBlock { task in
            guard let result = task.result else {
                return nil
            }
            let requestURLString = result[Constants.requestURLStringKey] as! String
            let authorizationHeader = result[Constants.authorizationHeaderKey] as! String
            return PFCloud.callFunctionInBackground("linkWithDigits", withParameters: ["requestURL": requestURLString, "authHeader": authorizationHeader])
        }.continueWithSuccessBlock { task in
            self.fetchInBackground()
        }.continueWithBlock{ task in
            return task.error != nil
        }
    }
    
    
    private static func _privateDigitsLoginWithConfiguration(configuration: DGTAuthenticationConfiguration?) -> BFTask {
        let config = configuration ?? DGTAuthenticationConfiguration(accountFields: .None)
        let taskCompletion = BFTaskCompletionSource()
        
        Digits.sharedInstance().authenticateWithViewController(nil, configuration: config!) {
            (session:DGTSession!, error:NSError?) in
            guard error == nil else {
                taskCompletion.trySetError(error!)
                return
            }
            
            let oauthSigning = DGTOAuthSigning(authConfig: Digits.sharedInstance().authConfig, authSession: session)
            let authHeaders = oauthSigning.OAuthEchoHeadersToVerifyCredentials()
            
            guard let requestURLString = authHeaders[TWTROAuthEchoRequestURLStringKey] as? String,
                let authorizationHeader = authHeaders[TWTROAuthEchoAuthorizationHeaderKey] as? String else {
                    taskCompletion.trySetResult(nil)
                    return
            }
            
            let nsdict:[String:AnyObject] = [Constants.sessionKey: session,
                Constants.requestURLStringKey: requestURLString,
                Constants.authorizationHeaderKey: authorizationHeader]
            let dict = NSDictionary(dictionary: nsdict)
            taskCompletion.trySetResult(dict)
        }
        
        return taskCompletion.task
    }

}