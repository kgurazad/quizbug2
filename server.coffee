express = require 'express'
request = require 'request'
mongoose = require 'mongoose'
app = express()
mongoose.connect process.env.DB

port = process.env.PORT || 2020

schema = mongoose.Schema({
    text: Object,
    difficulty: Number,
    tournament: Object,
    category: String,
    subcategory: String
})
model = mongoose.model('qs',schema,'raw-quizdb-clean')

split = (str, separator) ->  
  if str.length == 0
    return []
  str.split separator

mergeSpaces = (arr) ->
  res = ''
  for str in arr
    res += ' '
    res += str
  return res.slice 1

escapeRegExp = (str) ->
  str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&'

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
  try
    search = req.params.search.split('!')
    queryString = escapeRegExp search[0]
    query = {}
    categories = split(search[1], ',')
    subcategories = split(search[2], ',')
    difficulties = split(search[3], ',')
    tournamentsRaw = split(search[4], ',')
    console.log 'raw ' + tournamentsRaw
    tournaments = {$or: []} # as it is in the mongodb
    searchType = search[5]

    searchParams = {$and: []}

    for k,v of difficulties
      difficulties[k] = Number v

    if tournamentsRaw.length == 0
      tournaments = {'tournament': {$exists: true}}
    for tournament in tournamentsRaw
      tSplit = tournament.split ' '
      try
        year = Number tSplit[0]
        if tSplit.length == 1
          tournaments.$or.push {'tournament.year': year, 'tournament.name': {$exists: true} }
        else
          tournaments.$or.push {'tournament.year': year, 'tournament.name': mergeSpaces tSplit.slice 1 }
      catch e
        tournaments.$or.push {'tournament.year': {$exists: true}, 'tournament.name': mergeSpaces tSplit.slice 1 }

    if tournamentsRaw.length == 1
      tournaments = tournaments.$or

    if searchType == 'qa'
      query.$or = []
      query.$or.push {'text.question': {$regex: new RegExp(queryString, 'i')}}
      query.$or.push {'text.answer': {$regex: new RegExp(queryString, 'i')}}
    else if searchType == 'q'
      query = {'text.question': {$regex: new RegExp(queryString, 'i')}}
    else
      query = {'text.answer': {$regex: new RegExp(queryString, 'i')}}

    if queryString == ''
      query = {'text': {$exists: true}}

    searchParams.$and.push query
    searchParams.$and.push tournaments
    searchParams['difficulty'] = {$in: difficulties}
    searchParams['category'] = {$in: categories}
    searchParams['subcategory'] = {$in: subcategories}

    console.log JSON.stringify searchParams

    model.find(searchParams).limit(1331).find (e, data) ->
      if e?
        console.log e.stack
        res.sendStatus 503
        return
      res.send data
      return

  catch e
    console.log e.stack
    res.sendStatus 400
    
  return

app.listen port, () ->
  console.log 'listening on port ' + port + ' :)'
  return
