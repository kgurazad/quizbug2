console.log 'up!'

window.addEventListener 'keydown', (e) ->
  if e.keyCode == 32 and e.target == document.body
    e.preventDefault()
  return

readSpeed = 120
currentlyIsBuzzing = false
questionEnded = false
questionFinished = false
questionAnswered = false
buttons = false
questions = null
question = null
questionText = null
readInterval = null
word = 0

back = () ->
  question = questions[(questions.indexOf(question) - 2 + questions.length) % questions.length]
  next()

next = () ->
  finish()
  try
    readSpeed = Number($('#readSpeed').val())
  catch e
    alert ('read speed was not a number!')
    readSpeed = 120    
  questionEnded = false
  questionFinished = false
  question = questions[(questions.indexOf(question) + 1) % questions.length]
  $('#metadata').empty()
  $('#metadata').append('<li class="breadcrumb-item">'+question.tournament.year+' '+question.tournament.name+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">Difficulty Level '+question.difficulty+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question.category+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question.subcategory+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">QuizDB ID #'+question.id+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">Question '+(questions.indexOf(question) + 1)+' of '+questions.length+'</li>')
  questionText = question.text.question.split(' ')
  $('#question').text('');
  if buttons
    $('#answer').text('Click the button to buzz.')
    $('#b').text('Buzz')
  else
    $('#answer').text('Press [space] to buzz.');
  readInterval = window.setInterval () ->
    if currentlyIsBuzzing or questionFinished or questionEnded
      return
    $('#question').append(questionText[word] + ' ')
    word++
    if word == questionText.length
      $('#question').append(' (end) ')
      questionEnded = true
    return
  , readSpeed
  return

randomize = () ->
  currentIndex = questions.length
  while 0 != currentIndex
    randomIndex = Math.floor(Math.random() * currentIndex)
    currentIndex -= 1
    temporaryValue = questions[currentIndex]
    questions[currentIndex] = questions[randomIndex]
    questions[randomIndex] = temporaryValue
  question = null
  next()
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
  $('#answer').text(question.text.answer) if question?
  return

search = () ->
  searchParameters = {
    query: $('#query').val(),
    categories: $('#categories').val(),
    subcategories: $('#subcategories').val(),
    difficulties: $('#difficulties').val(),
    tournaments: $('#tournaments').val(),
    searchType: $('#searchType').find(':selected').val()
  }
  url = ''
  url += searchParameters.query
  url += '!'
  url += searchParameters.categories
  url += '!'
  url += searchParameters.subcategories
  url += '!'
  url += searchParameters.difficulties
  url += '!'
  url += searchParameters.tournaments
  url += '!'
  url += searchParameters.searchType
  finish()
  $('#question').text('this may take a while...')
  $('#answer').text('')
  console.log url
  $.getJSON 'search/'+url, (res) ->
    questions = res
    console.log questions
    if questions.length == 0
      $('#question').text('No questions found. Try loosening your filters.')
      return
    question = null
    next()
    return
  return

$(document).ready () ->
  $('.btn-block').hide()
  $('#searchType').val('a')
  $('#p').click () ->
    if buttons
      buttons = false
      $('.btn-block').hide()
    else
      buttons = true
      $('.btn-block').show()
    return
  $('#s').click () ->
    search()
    return
  $('#n').click () ->
    next()
    return
  $('#m').click () ->
    back()
    return
  $('#r').click () ->
    randomize()
    return
  $('#b').click () ->
    if currentlyIsBuzzing and not questionFinished
      finish()
      currentlyIsBuzzing = false
    else if not questionFinished
      $('#question').append('(#) ')
      $('#answer').text('Click again to reveal.')
      $('#b').text('Reveal')
      currentlyIsBuzzing = true
    return
  $(document).keyup () ->
    if document.activeElement.tagName != 'BODY'
      return
    if event.which == 32
      if currentlyIsBuzzing and not questionFinished
        finish()
        currentlyIsBuzzing = false
      else if not questionFinished
        $('#answer').text('Press [space] to reveal.')
        $('#question').append('(#) ')
        currentlyIsBuzzing = true
    else if event.which == 78
      next()
    else if event.which == 66
      back()
    else if event.which == 83
      search()
    else if event.which == 82
      randomize()
    return
  return

