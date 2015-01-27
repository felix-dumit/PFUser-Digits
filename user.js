var _ = require('underscore');

var Buffer = require('buffer').Buffer;

var createNewDigitsUser = function(userId) {

    var user = new Parse.User();

    var username = new Buffer(24);
    var password = new Buffer(24);
    _.times(24, function(i) {
        username.set(i, _.random(0, 255));
        password.set(i, _.random(0, 255));
    });
    user.set("username", username.toString('base64'));
    user.set("password", password.toString('base64'));

    user.set('digitsId', userId);

    return user.signUp();

};


Parse.Cloud.define("loginWithDigits", function(request, response) {

    Parse.Cloud.useMasterKey();

    var userId = request.params.userId;
    var requestURL = request.params.requestURL;
    var authHeader = {
        'Authorization': request.params.authHeader
    };

    Parse.Cloud.httpRequest({
        url: requestURL,
        headers: authHeader
    }).then(function(res) {
        if (res.status != 200) {
            return Parse.Promise.error("error with echo twitter authentication");
        }
        var query = new Parse.Query(Parse.User);
        query.equalTo('digitsId', userId);
        return query.first();
    }).then(function(user) {
        return user || createNewDigitsUser(userId);
    }).then(function(user) {
        user.set('phone', request.params.phoneNumber);
        return user.save();
    }).then(function(user) {
        response.success(user.getSessionToken());
    }, function(error) {
        response.error(error);
    });
});