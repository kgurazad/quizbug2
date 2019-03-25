express = require 'express'
request = require 'request'
mongoose = require 'mongoose'
app = express()
app.use express.json()
app.use express.urlencoded()
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
metascheme = mongoose.Schema({
    name: String,
    values: [String]
})
metamodel = mongoose.model('meta', metascheme, 'meta')

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

app.use (err, req, res, next) ->
  res.status(404).send 'NEG 5 - Page Not Found (404)'
  return

app.use (err, req, res, next) ->
  res.status(500).send 'NEG 5 - Internal Server Error (500)'
  return

app.use (err, req, res, next) ->
  res.status(503).send 'NEG 5 - Server Breakdown; Temporarily Unavailable (503)'
  return

app.get '/', (req, res) ->
  res.sendFile __dirname+'/index.html'
  return

app.get '/info', (req, res) ->
  res.sendFile __dirname+'/info.html'
  return

app.get '/update', (req, res) ->
  res.sendFile __dirname+'/update.html'
  return

app.get '/teapot', (req, res) ->
  res.sendStatus 418
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

app.get '/viselect.js', (req, res) ->
  res.sendFile __dirname+'/viselect.js'
  return

app.get '/categories', (req, res) ->
  metamodel.findOne({name: 'categories'}).read('sp').exec (err, meta) ->
    res.send meta.values
    return
  return

app.get '/subcategories', (req, res) ->
  metamodel.findOne({name: 'subcategories'}).read('sp').exec (err, meta) ->
    res.send meta.values
    return
  return

app.get '/tournaments', (req, res) ->
  metamodel.findOne({name: 'tournaments'}).read('sp').exec (err, meta) ->
    res.send meta.values
    return
  return

app.get '/search', (req, res) ->
  try

    searchParams = {};

    # alright i am rewriting this code 24 mar 2019 because it was a mess
    # adding matching features for and/or/not, really basic boolean operations
    # and is denoted with &&, or with ||, not with !!
    # things to sort by -
    # query string - does it contain any combination of what is given? also use a/q/qa mods
    # category/subcategory - match it so that it falls under either (ie use an or clause)
    # also subject to !! modifiers - || and && not needed
    # difficulties - again same as cat/subcat, use only !!, otherwise , to separate
    # add question type later? will need to find a way to read bonuses but seems rewarding ;)
    # tournament - name contains, again same as usual
    # &&, || only used for query string
    
    # define boolean regexes - not global because will evaluate from left to right
    # || is separated first then && - for example Giotto || Grant && Wood || Frans && Hals
    andRegex = /\s*&&\s*/
    orRegex = /\s*\|\|\s*/
    notRegex = /^!!/
    commaRegex = /\s*,/

    # begin parsing query string
    queryString = req.query.query || '' # lol
    searchType = req.query.searchType
    queryMatchExp = {} # should be self-contained; ie done at the end of this
    queryContainsNot = notRegex.test queryString
    if queryContainsNot
        queryString = queryString.replace notRegex, ''
    addQueryAnd = (split, field) -> 
        toReturn = {$and: []};
        for str in split
            tmp = {}
            tmp[field] = {$regex: new RegExp(str, 'i')}
            toReturn.$and.push tmp
        toReturn
    # whitespace
    addQueryOr = (split, field) ->
        toReturn = {$or: []}
        for str in split
            if andRegex.test str
                queryStringSplit = str.split andRegex
                toReturn.$or.push addQueryAnd queryStringSplit, field
            else
                tmp = {}
                tmp[field] = {$regex: new RegExp(str, 'i')}
                toReturn.$and.push tmp
            # whitespace
        toReturn
    # whitespace
    if not orRegex.test queryString
        if andRegex.test queryString
            queryStringSplit = queryString.split andRegex
            # oh god oh god why this so hard ;-;
            if searchType == 'q'
                queryMatchExp = addQueryAnd queryStringSplit, 'text.question'
            else if searchType == 'a'
                queryMatchExp = addQueryAnd queryStringSplit, 'text.answer'
            else
                queryMatchExp = {$or: [addQueryAnd(queryStringSplit, 'text.question'), addQueryAnd(queryStringSplit, 'text.answer')]}
            # queries like Grant && Wood && Gothic
            # matches anything with those words (case-insensitive)
        else
            # simple query (yay)
            if searchType == 'q'
                queryMatchExp = {'text.question': new RegExp(queryString, 'i')}
            else if searchType == 'a'
                queryMatchExp = {'text.answer': new RegExp(queryString, 'i')}
            else
                queryMatchExp = {$or: [{'text.question': new RegExp(queryString, 'i')}, {'text.answer': new RegExp(queryString, 'i')}]}
            # nice and clean :)
        # now for the hard part oO
    else # has an or
        queryStringSplit = queryString.split orRegex
        if searchType == 'q'
            queryMatchExp = addQueryOr queryStringSplit, 'text.question'
        else if searchType == 'a'
            queryMatchExp = addQueryOr queryStringSplit, 'text.answer'
        else
            queryMatchExp = {$or: [addQueryOr(queryStringSplit, 'text.question'), addQueryOr(queryStringSplit, 'text.answer')]}
        # the complex bois
        # matches anything with those words (case-insensitive)
    # whitespace
    ###
    if queryContainsNot
        queryMatchExp = {$not: queryMatchExp} # this one is broken D:
    ###
    # congratulations you made it through wooooo
    
    # now for cats and subcats
    rawCats = req.query.categories || ''
    rawSubcats = req.query.subcategories || ''
    # these should both merge into one $or
    catContainsNot = notRegex.test rawCats
    if catContainsNot
        rawCats = rawCats.replace notRegex, ''
    subcatContainsNot = notRegex.test rawSubcats
    if subcatContainsNot
        rawSubcats = rawSubcats.replace notRegex, ''
    catSubcatMatchExp = {$or: []} # there has to be a $or
    cats = rawCats.split commaRegex
    if rawCats == ''
        cats = []
    subcats = rawSubcats.split commaRegex
    catMatchExp = {'category': {$in: cats}} # the cat component
    if catMatchExp['category'].$in.length == 0
        catMatchExp = {'category': {$exists: true}}
    if catContainsNot
        catMatchExp = {'category': {$not: {$in: catMatchExp['category'].$in}}}
    subcatMatchExp = {'subcategory': {$in: subcats}} # the subcat component
    if subcatMatchExp['subcategory'].$in.length == 0
        subcatMatchExp = {'subcategory': {$exists: true}}
    if subcatContainsNot
        subcatMatchExp = {'subcategory': {$not: {$in: subcatMatchExp['subcategory'].$in}}}
    if rawCats != ''
        catSubcatMatchExp.$or.push catMatchExp
    if rawSubcats != ''
        catSubcatMatchExp.$or.push subcatMatchExp
    
    # difficulty time
    rawDiffs = req.query.difficulties || ''
    diffMatchExp = {'difficulty': {$in: []}}
    diffContainsNot = notRegex.test rawDiffs
    if diffContainsNot
        rawDiffs = rawDiffs.replace notRegex, ''
    diffs = rawDiffs.split commaRegex
    if rawDiffs == ''
        diffs = []
    for d in diffs
        diffMatchExp['difficulty'].$in.push Number(d)
    if diffMatchExp['difficulty'].$in.length == 0
        diffMatchExp = {'difficulty': {$exists: true}}
    if diffContainsNot
        diffMatchExp = {'difficulty': {$not: {$in: diffMatchExp['difficulty'].$in}}}
    
    # last but not least, tournament name matching
    rawTourneys = req.query.tournaments || ''
    tourneyMatchExp = {$or: []}
    tourneyContainsNot = notRegex.test rawTourneys
    if tourneyContainsNot
        rawTourneys = rawTourneys.replace notRegex, ''
    tourneys = rawTourneys.split commaRegex
    if rawTourneys == ''
        tourneys = []
    for tourney in tourneys
        tourneyMatchExp.$or.push {'tournament': {$regex: new RegExp(tourney, 'i')}}
    if tourneyMatchExp.$or.length == 0
        tourneyMatchExp = {'tournament': {$exists: true}}
    if tourneyContainsNot
        tourneyMatchExp = {$not: tourneyMatchExp}
    # break out the chocolate ;)
    
    searchParams = {$and: []} # one big $and for all the params    
    searchParams.$and.push queryMatchExp
    if catSubcatMatchExp.$or.length != 0 # no restrictions on any
        searchParams.$and.push catSubcatMatchExp
    searchParams.$and.push diffMatchExp
    searchParams.$and.push tourneyMatchExp
    console.log JSON.stringify searchParams # for good measure D:

    model.count(searchParams).read('sp').exec (err, count) ->
      if err?
         console.log err
         return
      console.log 'there are ' + count  + ' documents found'
      if count > 1331
        console.log 'aggregating!'
        aggregateParams = [{$match: searchParams}, {$sample: {size: 1331}}]
        console.log JSON.stringify aggregateParams
        model.aggregate(aggregateParams).read('sp').exec (err, data) ->
          console.log 'there are ' + data.length + ' documents to be sent'
          if err?
            console.log err.stack
            res.sendStatus 503
            return
          res.send data
          return
	# comment <- what is this lol, whitespace drives u mad
      else
        console.log 'regular finding!'
        model.find(searchParams).read('sp').exec (err, data) ->
          console.log 'there are ' + data.length + ' documents to be sent'
          if err?
            console.log err.stack
            res.sendStatus 503
            return
          res.send data
          return
        # comment
      return
	
  catch e
    console.log e.stack
    res.sendStatus 400
    
  return

app.listen port, () ->
  console.log 'listening on port ' + port + ' :)'
  return
