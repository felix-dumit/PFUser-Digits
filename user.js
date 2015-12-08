var verifyDigitsLogin = function(requestURL, authHeader, link) {
    var data = undefined;
    var url = require('url');
    var uri = url.parse(requestURL);

    if (uri.hostname === 'api.digits.com') {
      return Parse.Cloud.httpRequest({
          url: requestURL,
          headers: {
              'Authorization': authHeader
          }
      }).then(function(res) {
          if (res.status != 200) {
              return Parse.Promise.error("error with echo twitter authentication");
          } else {
              return res.data;
          }
      });
  } else {
    return Parse.Promise.error('Authorization URL failed validation');
  }
};

var fillUserWithVerifiedData = function(user, data) {
    user.set('phone', data.phone_number);
    user.set('digitsId', data.id_str);

    if(!user.get('username')){
        user.set('username', data.id_str);
    }
    if (data.email_address && !user.get('email')) {
        user.set('email', data.email_address.address);
    }
    user.set("password", data.access_token.token);
}

Parse.Cloud.define("linkWithDigits", function(request, response) {

    Parse.Cloud.useMasterKey();

    var requestURL = request.params.requestURL;
    var authHeader = request.params.authHeader;
    var authData = {};

    verifyDigitsLogin(requestURL, authHeader).then(function(data) {
        authData = data;
        var query = new Parse.Query(Parse.User);
        query.equalTo('digitsId', data.id_str);
        return query.first();
    }).then(function(user) {
        if (user) {
            return Parse.Promise.error("already a user linked with this digits account");
        }
        var query = new Parse.Query(Parse.User);
        return query.get(request.user.id);
    }).then(function(user) {
        fillUserWithVerifiedData(user, authData);
        return user.save();
    }).then(function() {
        response.success(true);
    }, function(error) {
        response.error(error);
    });
});


Parse.Cloud.define("loginWithDigits", function(request, response) {

    Parse.Cloud.useMasterKey();

    var requestURL = request.params.requestURL;
    var authHeader = request.params.authHeader;

    verifyDigitsLogin(requestURL, authHeader).then(function(data) {
        var query = new Parse.Query(Parse.User);
        query.equalTo('digitsId', data.id_str);
        return query.first().then(function(user) {
            if (!user) {
                user = new Parse.User();
            }
            fillUserWithVerifiedData(user, data);
            return user.save().then(function() {
                return Parse.User.logIn(user.get("username"), data.access_token.token);
            });
        });
    }).then(function(user) {
        response.success(user.getSessionToken());
    }, function(error) {
        response.error(error);
    });
});
