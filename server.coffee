express = require 'express'
app = express()

port = process.env.PORT || 2020

getJSON = (url) ->
  return new Promise (resolve, reject) ->
    xhr = new XMLHttpRequest
    xhr.open 'get', url, true
    xhr.responseType = 'json'

    xhr.onload = () ->
      status = xhr.status
      if status == 200
        resolve xhr.response
      else
        reject status
      return

    xhr.send()
    return


app.get '/', (req, res) ->
    res.sendFile __dirname+'/index.html'
    return
    
app.get '/client.js', (req, res) ->
    res.sendFile __dirname+'/client.js'
    return
    
app.get '/style.css', (req, res) ->
    res.sendFile __dirname+'/style.css'
    return

app.get '/search/:search', (req, res) ->
    search = req.params.search
    search = search.replace /\%/g, '&'
    search = '?' + search
    search = encodeURI search
    getJSON('https://www.quizdb.org/api/search'+search).then (data) ->
        res.send data
        return
    return

app.listen port, () ->
    console.log 'listening on port ' + port + ' :)'
    return
