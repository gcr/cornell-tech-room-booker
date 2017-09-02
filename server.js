// Generated by LiveScript 1.4.0
(function(){
  var api, express, secrets, app;
  api = require('./api');
  express = require('express');
  secrets = require('./secrets');
  app = express();
  app.use(require('body-parser')());
  app.use('/static', express['static']('static'));
  app.get('/', function(req, res){
    return res.sendFile('static/base.htm', {
      root: __dirname
    });
  });
  app.post('/availability', function(req, res){
    var success, fail, rooms;
    success = function(response){
      return res.send(JSON.stringify({
        ok: response
      }));
    };
    fail = function(err){
      return res.send(JSON.stringify({
        err: err.message
      }));
    };
    rooms = req.body.rooms;
    return api.get_room_availability(secrets.user, secrets.pass, rooms).then(success, fail);
  });
  app.listen(3000, function(){
    return console.log('Server listening at http://localhost:3000/');
  });
}).call(this);