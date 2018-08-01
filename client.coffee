console.log 'up!'

# this is the not stuff you want to configure! configurables are at the bottom.

searchParameters = {
  query: '',
  categories: [],
  subcategories: [],
  search_types: [],
  difficulties: [],
  tournaments: []
}
readSpeed = 120
currentlyIsBuzzing = false
questionEnded = false
questionFinished = false
questionAnswered = false
questions = null
question = null
questionText = null
readInterval = null
word = 0

getJSON = (url) ->
  promise = new Promise (resolve, reject) ->
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
  return promise

next = () ->
  finish()
  questionEnded = false
  questionFinished = false
  question = questions[(questions.indexOf(question) + 1) % questions.length]
  $('#metadata').empty()
  $('#metadata').append('<li class="breadcrumb-item">'+question["tournament"].name+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question["tournament"].difficulty+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question.category.name+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question.subcategory.name+'</li>')
  questionText = question.text.split(' ')
  $('#question').text('');
  $('#answer').text('');
  readInterval = window.setInterval () ->
    if currentlyIsBuzzing or questionFinished or questionEnded
      return
    $('#question').append(questionText[word] + ' ')
    word++
    if word == questionText.length
      questionEnded = true
    return
  , readSpeed
  return

finish = () ->
  questionEnded = true
  questionFinished = true
  window.clearInterval(readInterval)
  if questionText?
    while word < questionText.length
      $('#question').append(questionText[word] + ' ')
      word++
  word = 0
  $('#answer').text(question.answer) if question?
  return

search = () ->
  url = ''
  url += 'search[query]='+searchParameters.query
  for category in searchParameters.categories
    url += '!search[filters][category]='+category
  for search_type in searchParameters.search_types
    url += '!search[filters][search_type][]='+search_type
  for difficulty in searchParameters.difficulties
    url += '!search[filters][difficulty][]='+difficulty
  for subcategory in searchParameters.subcategories
    url	+= '!search[filters][subcategories][]='+subcategory
  url += '!search[filters][question_type][]=Tossup'
  for tournament in searchParameters.tournaments
    url	+= '!search[filters][tournament][]='+tournament
  url += '!crossDomain=true'
  finish()
  $('#question').text('this takes a while...')
  $('#answer').text('if it does not load within 30 seconds, the request timed out. make your parameters more specific and try again.')
  getJSON('search/'+url).then (res) ->
    questions = res.data.tossups
    question = null
    next()
    return
  return

$(document).ready () ->
  $(document).keyup () ->
    # these are the configurables!
    searchParameters = {
      query: '', # the string of your query
      categories: [], # quizdb ids
      subcategories: [], # ^
      search_types: [], # none, Question, Answer, or both
      difficulties: [], # middle_school, easy_high_school, etc
      tournaments: [] # use quizdb ids - good luck with finding them
    }
    readSpeed = 120 # number of milliseconds between words
    # end configurables
    if event.which == 32
      if currentlyIsBuzzing and not questionFinished
        finish()
        currentlyIsBuzzing = false
      else if not questionFinished
        $('#question').append('(#) ')
        currentlyIsBuzzing = true
    else if event.which == 78
      next()
    else if event.which == 83
      search()
    setTimeout () ->
      window.scrollTo 0, 0
      return
    , 30
    return
  return

