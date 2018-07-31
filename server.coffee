express = require 'express'
app = express()

port = process.env.PORT || 2020

app.get '/', (req, res) ->
    res.sendFile __dirname+'/index.html'

app.get '/client.js', (req, res) ->
    res.sendFile __dirname+'client.js'

app.get '/style.css', (req, res) ->
    res.sendFile __dirname+'style.css'

app.listen port, () ->
    console.log 'listening on port ' + port + ' :)'

