PFUser-Digits
=============

A way to authenticate Parse Users using the Twitter Digits API

To call make sure you setup [Digits](https://docs.fabric.io/ios/digits/) login and also setup your project with [Parse](https://www.parse.com/docs/ios_guide#top/iOS)

Drag the PFUser+Digits.m and PFUser+Digits.h into your XCode project.
Add the user.js file to your cloud code folder and include in your main.js file 
```js
require('cloud/user.js');
``` 
or copy the contents to main.js

#Login with Digits

To use just call the function which will trigger the Digits sign-in flow and when succeded, will authenticate or create a new user on Parse.

You may call using blocks: 

```objc
[PFUser loginWithDigitsInBackground:^(PFUser *user, NSError *error) {
    if(!error){
      // do something with user
    }
}];
```
Or Using Bolts:

```objc
[[PFUser loginWithDigitsInBackground] continueWithBlock: ^id (BFTask *task) {
    if(!task.error){
      PFUser *user = task.result;
      // do something with user
    }
}];
```

#Link Existing Account

You can also link an existing account (anonymous or not) with Digits. This works in the same way as linking with Facebook and allows you to later on log back in using the Digits sign-in

```objc
[[PFUser currentUser] linkWithDigitsInBackground]; //returns BFTask*
```
or 
```objc
[[PFUser currentUser] linkWithDigitsInBackground:^(PFUser* user, NSError* error) {}]; //block callback
```

#Customising

For all the previous examples you can pass an `DGTAuthenticationConfiguration` object. Use it to configure the appearance of the login screen or pass in the phone number to verify.
For more information view the [Official documentation](https://docs.fabric.io/ios/digits/theming.html)
For example:
```objc
[PFUser loginWithDigitsInBackgroundWithTitle:@"Digits Login" backgroundColor:[UIColor whiteColor] accentColor:[UIColor redColor]];
```

#Improvements
If you are using revokable sessions, make sure to disable `revoking sessions when user changes password`.
This is due to the fact that currently the only workaround I found to returning a session token from CloudCode was to login the user - and for that you need to specify the password. So the solution for now is to change the user's password before every login.
Would really like a better solution so if you have any ideas please let me know.


#License
The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
