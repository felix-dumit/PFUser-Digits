var _ = require('underscore');

var Buffer = require('buffer').Buffer;

var randomString = function(){
    var str = new Buffer(24);
    _.times(24, function (i) {
        str.set(i, _.random(0, 255));
    });
    return str.toString('base64');
}

var createNewDigitsUser = function (userId) {

    var user = new Parse.User();

    var username = randomString();
    var password = randomString();

    user.set("username", username);
    user.set("password", password);

    user.set('digitsId', userId);

    return user.signUp().then(function(user){
        return Parse.User.logIn(username, password);
    });

};

var verifyDigitsLogin = function(requestURL, authHeader){
    var promise = new Parse.Promise();
    Parse.Cloud.httpRequest({
        url: requestURL,
        headers: {'Authorization': authHeader}
    }).then(function (res) {
        if (res.status != 200) {
            promise.reject("error with echo twitter authentication");
        } else{
            promise.resolve(true);
       }
    }, function(error){
        promise.reject(error);
    });

    return promise;
};

Parse.Cloud.define("linkWithDigits", function(request, response){

    Parse.Cloud.useMasterKey();

    var userId = request.params.userId;
    var digitsId = request.params.digitsId;
    var requestURL = request.params.requestURL;
    var authHeader = request.params.authHeader;

    verifyDigitsLogin(requestURL, authHeader).then(function(){
        var query = new Parse.Query(Parse.User);
        query.equalTo('digitsId', digitsId);
        return query.first();
    }).then(function(user){
        if(user){
            return Parse.Promise.error("already a user linked with this digits account");
        }
        var query = new Parse.Query(Parse.User);
        return query.get(userId);
    }).then(function(user){
        user.set('digitsId', digitsId);
        user.set('phone', request.params.phoneNumber);
        return user.save();
    }).then(function(){
        response.success(true);
    }, function(error){
        response.error(error);
    });
});


Parse.Cloud.define("loginWithDigits", function (request, response) {

    Parse.Cloud.useMasterKey();

    var userId = request.params.digitsId;
    var requestURL = request.params.requestURL;
    var authHeader = request.params.authHeader;
    var password = randomString();

    verifyDigitsLogin(requestURL, authHeader).then(function(){
        var query = new Parse.Query(Parse.User);
        query.equalTo('digitsId', userId);
        return query.first({useMasterKey: true}).then(function(user){
          if(user){
            user.set("password", password);
            return user.save();
          }
        });
    }).then(function (user) {
        if(user){
            return Parse.User.logIn(user.get("username"), password);
        }
        else {
            return createNewDigitsUser(userId);
        }
    }).then(function (user) {
        user.set('phone', request.params.phoneNumber);
        return user.save();
    }).then(function (user) {
        response.success(user.getSessionToken());
    }, function (error) {
        response.error(error);
    });
});
