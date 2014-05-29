BookEvents = do ->

  TRIGGER_PX = 50
  RESISTANCE = 0.5

  _current = null
  _started = false
  _diffX = 0
  _startX = 0

  _closestPage = (ev_target) ->
    console.log ev_target
    console.log "p1", ev_target.parentNode
    console.log "p2", ev_target.parentNode.parentNode
    console.log "p3", ev_target.parentNode.parentNode.parentNode
    if ev_target.className is "book-page"
      return ev_target
    else
      current = ev_target
      i = 0
      while current.parentNode? and i++ < 100
        if current.parentNode.className is "book-page"
          return current.parentNode
    return null

  _next_transform = (el) ->
    Transformer(el)
      .addStep(0, rotateY: 0)
      .addStep(100, rotateY: -180)

  _prev_transform = (el) ->
    Transformer(el)
      .addStep(0, rotateY: -180)
      .addStep(100, rotateY: 0)


  _getEventX = (ev) -> ev.pageX

  _start = -> (ev) ->
    _started = true
    _diffX = 0
    _startX = _getEventX(ev)
    ev.preventDefault()
    ev.stopPropagation()
    _current = _closestPage(ev.target)
    _current.style.zIndex = 1
    return

  _move = -> (ev) ->
    if _started and _current
      _diffX = _getEventX(ev) - _startX
      _percent = Math.max(Math.min(_diffX * 20 / TRIGGER_PX, 99), -99)
      _current.setAttribute("book-page-noanim", "true")
      if _diffX < 0 and !_current.getAttribute("data-status")
        _next_transform(_current).set(Math.abs(_percent))
      else if _diffX > 0 and _current.getAttribute("data-status")
        _prev_transform(_current).set(Math.abs(_percent))

      ev.preventDefault()
      ev.stopPropagation()

    return

  _end = (book_instance) -> (ev) ->
    _started = false
    absDiff = Math.abs(_diffX)
    console.log absDiff
    if absDiff > TRIGGER_PX
      command = if _diffX > 0 then "previous" else "next"
      book_instance[command]()
    else if _current
      _current.removeAttribute("book-page-noanim")
      _current.removeAttribute("style")

    _current = null
    _started = false
    _diffX = 0
    _startX = 0
    return

  init = (book_instance) ->
    book_instance.element.addEventListener "mousedown", _start(book_instance)
    book_instance.element.addEventListener "mousemove", _move(book_instance)
    book_instance.element.addEventListener "mouseup", _end(book_instance)
    return

  init: init
