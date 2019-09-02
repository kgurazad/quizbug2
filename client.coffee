console.log 'up!'

window.addEventListener 'keydown', (e) ->
  if e.keyCode == 32 and e.target == document.body
    e.preventDefault()
  return

buttons = false
dark = false
readSpeed = 120
currentlyIsBuzzing = false
questionEnded = false
questionFinished = false
questionAnswered = false
questions = null
question = null
questionText = null
readInterval = null
session = null
word = 0

back = () ->
  question = questions[(questions.indexOf(question) - 2 + questions.length) % questions.length]
  next()

next = () ->
  if not questionFinished
    finish()
  console.log question
  $('#negged').hide()
  try
    readSpeed = Number($('#readSpeed').val())
  catch e
    alert ('read speed was not a number!')
    readSpeed = 120    
  questionEnded = false
  questionFinished = false
  question = questions[(questions.indexOf(question) + 1) % questions.length]
  $('#metadata').empty()
  $('#metadata').append('<li class="breadcrumb-item">'+question.tournament+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">Difficulty Level '+question.difficulty+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+question.category+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">'+(question.subcategory || 'No Subcat')+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">QuizDB ID #'+question.id+'</li>')
  $('#metadata').append('<li class="breadcrumb-item">Question '+(questions.indexOf(question) + 1)+' of '+questions.length+'</li>')
  $('#question').text('');
  questionText = question.text.question.split ' '
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
  currentlyIsBuzzing = false
  window.clearInterval(readInterval)
  if questionText?
    while word < questionText.length
      $('#question').append(questionText[word] + ' ')
      word++
  word = 0
  if question?
    $('#answer').text(question.text.answer)
    $('#negged').show()
    questionText = $('#question').html()
    if questionText.indexOf('(#)') == -1
      question.fate = '0'
    else if questionText.indexOf('(#)') < questionText.indexOf('(*)')
      question.fate = '15'
    else
      question.fate = '10'
    
  return

neg = () ->
  if not question?
    return
  if not questionFinished
    return
  questionText = $('#question').html()
  if questionText.indexOf('(#)') < questionText.indexOf('(end)')
    question.fate = '0'
  else
    question.fate = '-5'

  return

search = () ->
  searchParameters = {
    query: $('#query').val().trim(),
    categories: $('#categories').val().trim(),
    subcategories: $('#subcategories').val().trim(),
    difficulties: $('#difficulties').val().trim(),
    tournaments: $('#tournaments').val().trim(),
    searchType: $('#searchType').find(':selected').val().trim()
  }
  url = 'search?'
  url += $.param([
    {name: 'query', value: searchParameters.query},
    {name: 'categories', value: searchParameters.categories},
    {name: 'subcategories', value: searchParameters.subcategories},
    {name: 'difficulties', value: searchParameters.difficulties},
    {name: 'tournaments', value: searchParameters.tournaments},
    {name: 'searchType', value: searchParameters.searchType}
  ]); 
  console.log url
  finish()
  $('#question').text('this may take a while...')
  $('#answer').text('maybe i could advertise here >:)') # $('#answer').hide()?
  $.getJSON url, (res) ->
    questions = res
    if questions.length == 0
      $('#question').text('No questions found. Try loosening your filters.')
      return
    question = null
    next()
    return
  return

initMenus = () ->
  $.getJSON '/categories', (data) ->
    new window.ViSelect 'categories', data
    return
  $.getJSON '/subcategories', (data) ->
    new window.ViSelect 'subcategories', data
    return
  $.getJSON '/tournaments', (data) ->
    new window.ViSelect 'tournaments', data
    return
  return

$(document).ready () ->
  initMenus()
  $('#buttons').hide()
  $('#negged').hide()
  $('#searchType').val('a')
  $('#style-toggle').click () ->
    if dark
      $('#style-toggle').text 'Light Mode'
      $('head').append '<link id="dark-mode-link" rel="stylesheet" href="https://quizbug2.herokuapp.com/dark-style.css">'
      $('#light-mode-link').remove()
    else
      $('#style-toggle').text 'Dark Mode'
      $('head').append '<link id="light-mode-link" rel="stylesheet" href="https://quizbug2.herokuapp.com/style.css">'
      $('#dark-mode-link').remove()
    dark = !dark
    return
  $('#p').click () ->
    $('#buttons').toggle()
    buttons = !buttons
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
  $('#negged').click () ->
    neg()
    return
  document.addEventListener "keyup", (event) ->
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
    else if event.which == 189
      neg()
    return
  return
