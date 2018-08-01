console.log 'up!'

# this is the stuff you	may want to configure!

searchParameters = {
  query: '', # the string of your query
  categories: [], # quizdb ids
  subcategories: [], # ^
  search_types: [], # none, Question, Answer, or both
  difficulties: [], # middle_school, easy_high_school, etc
  tournaments: [] # use quizdb ids - good luck with finding them
}
readSpeed = 120 # number of milliseconds between words

# end configurable stuff

currentlyIsBuzzing = false
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
  question = questions[(questions.indexOf(question) + 1) % questions.length]
  questionText = question.text.split(' ')
  $('#question').text('');
  $('#answer').text('');
  readInterval = setInterval () ->
    if currentlyIsBuzzing
      return
    $('#question').append(questionText[word] + ' ')
    word++
    if word == questionText.length
      finish()
    return
  , readSpeed
  return

finish = () ->
  clearInterval readInterval
  $('#question').text(question.text)
  $('#answer').text(question.answer)

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
  console.log url
  cnsl = console
  getJSON('search/'+url).then (res) ->
    questions = res.data.tossups
    question = null
    return
  next()
  return

$(document).ready () ->
  $(document).keypress () ->
    if event.which == 32
      if currentlyIsBuzzing
        finish()
        currentlyIsBuzzing = false
      else
        currentlyIsBuzzing = true
    else if event.which == 110
      next()
    else if event.which == 115
      search()
    setTimeout () ->
      window.scrollTo 0, 0
      return
    , 32
    return
  return

