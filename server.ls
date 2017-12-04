api = require './api'
express = require 'express'
secrets = require './secrets'

app = express!

app.use require('body-parser')!

app.use '/static', express.static 'static'

app.get '/', (req, res) -> res.send-file 'static/base.htm', root: __dirname

app.post '/availability', (req, res) ->
  success = (response) ->
    res.send(JSON.stringify(ok: response))
  fail = (err) ->
    res.send(JSON.stringify(err: err.message))

  {rooms, date-string} = req.body
  api.get_room_availability(
     secrets.user, secrets.pass, rooms, date-string
  ).then(success, fail)


port = process.env.PORT or 3000
#app.listen port, -> console.log 'Server listening at http://localhost:3000/'
app.listen port, '0.0.0.0'
