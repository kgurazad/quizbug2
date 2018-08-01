express = require 'express'
request = require 'request'
app = express()

port = process.env.PORT || 2020

app.get '/', (req, res) ->
  res.sendFile __dirname+'/index.html'
  return

app.get '/favicon.ico', (req, res) ->
  res.sendFile __dirname+'/favicon.ico'
  return

app.get '/client.js', (req, res) ->
  res.sendFile __dirname+'/client.js'
  return
    
app.get '/style.css', (req, res) ->
  res.sendFile __dirname+'/style.css'
  return

app.get '/search/:search', (req, res) ->
  search = req.params.search
  search = search.replace(/!/g, '&')
  search = '?' + search
  search = encodeURI search
  request({url:'https://www.quizdb.org/api/search'+search, json:true}, (err, res2, body) ->
    res.send body if !err and res2.statusCode == 200
    return
  )
  return

app.listen port, () ->
  console.log 'listening on port ' + port + ' :)'
  return
