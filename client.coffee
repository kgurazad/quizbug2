console.log 'up!'

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


currentlyIsBuzzing = false
questionFinished = false
questionAnswered = false
questions = null
question = null
questionText = null
readInterval = null
word = 0

next = () ->
  question = questions[(questions.indexOf(question) + 1) % currentQuestions.length]
  questionText = question.formatted_text.split(' ')
  readInterval = setInterval () ->
    if currentlyIsBuzzing
      return
    $('#question').append(questionText[word])
    word++
    if word = questionText.length
      finish()
    return
  , readSpeed
  return

finish = () ->
  clearInterval readInterval
  $('#question').text(question.formatted_text)
  $('#answer').text(question.answer)

search = () ->
  url = ''
  url += '?search[query]='+searchParameters.query
  for category in searchParameters.categories
    url += '&search[filters][category]='+category
  for search_type in searchParameters.search_types
    url += '&search[filters][search_type][]='+search_type
  for difficulty in searchParameters.difficulties
    url += '&search[filters][difficulty][]='+difficulty
  for subcategory in searchParameters.subcategories
    url	+= '&search[filters][subcategories][]='+subcategory
  url += '&search[filters][question_type][]=Tossup'
  for tournament in searchParameters.tournaments
    url	+= '&search[filters][tournament][]='+tournament
  url += '&crossDomain=true'
  getJSON('search/'+url).then (data) ->
    res = JSON.parse data
    questions = res.data.tossups
    return
  return

searchParameters = {
  query: '', # text of your query
  categories: [], # categories in an array: use quizdb ids
  search_types: [], # none, Question, Answer, or both
  difficulties: [], # middle_school, easy_high_school, regular_high_school, etc
  subcategories: [], # subcategories in	an array: use quizdb ids
  tournaments: [] # use the quizdb ids
}
  
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
    return
  return

