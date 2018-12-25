class ViSelect

  constructor: (name, values) ->
    @name = name
    @values = values
    @setFocusListeners()
    @setClickListeners()
    @setKeyListeners()
    return

  setFocusListeners: () ->
    self = this
    $('#' + @name).on 'focusin', ->
      @name = self.name
      $('#under-' + @name).show()
      return
    $('#' + @name).on 'focusout', ->
      if $('#around-' + @name).find(':hover').length == 0
        # $('#under-' + @name).hide()
        return
      return
    return

  setClickListeners: () ->
    self = this
    $('body').on 'click', '#under-' + @name + ' li', ->
      @name = self.name
      if $(this).attr('id') == 'hide-' + @name
        $('#' + @name).val $('#' + @name).val().slice(0, -1)
        $('#hide-' + @name).remove()
        $('#under-' + @name).hide()
        return
      ins = $('#' + @name).val().trim().split(/,\s*/)
      ins[ins.length - 1] = $(this).html()
      str = ''
      for i of ins
        str += ins[i] + ','
      $('#' + @name).val str
      if $('#hide-' + @name).length == 0
        $('#under-' + @name).append '<li id="hide-' + @name + '" class="under-' + @name + '-item list-group-item disabled">Hide</li>'
        return
      return
    return  

  setKeyListeners: () ->
    self = this
    $('#' + @name).on 'keyup', ->
      @name = self.name
      @values = self.values
      if event.which == 13
        ins = $(this).val().trim().split(/,\s*/)
        ins[ins.length - 1] = $('.under-' + @name + '-item.active').html()
        str = ''
        for i of ins
          str += ins[i] + ','
        $('#' + @name).val str
        return
      if event.which == 186
        $(this).val $(this).val().slice(0, -2)
        return
      if event.which == 38
        event.preventDefault()
        newActive = $('#under-' + @name + ' li.active').index()
        if newActive == 0
          newActive = $('#under-' + @name + ' li').length
        $('#under-' + @name + ' li.active').removeClass 'active'
        $('#under-' + @name + ' li:nth-child(' + newActive + ')').addClass 'active'
        return
      if event.which == 40
        event.preventDefault()
        s = $('#under-' + @name + ' li').length
        newActive = ($('#under-' + @name + ' li.active').index() + 2) % s
        if newActive == 0
          newActive = s
        $('#under-' + @name + ' li.active').removeClass 'active'
        $('#under-' + @name + ' li:nth-child(' + newActive + ')').addClass 'active'
        return
      $('#under-' + @name).empty()
      val = $(this).val().toLowerCase().trim().split(/,\s*/).slice(-1)[0]
      num = 0
      for i of @values
        word = words[i]
        if word.toLowerCase().startsWith(val)
          num++
          if num == 1
            $('#under-' + @name).append '<li class="under-' + @name + '-item list-group-item active">' + word + '</li>'
          else
            $('#under-' + @name).append '<li class="under-' + @name + '-item list-group-item">' + word + '</li>'
          if num == 6
            break
      if num == 0
        $('#under-' + @name).append '<li class="under-' + @name + '-item list-group-item">No results found.</li>'
        return
      return
    return
  #
#