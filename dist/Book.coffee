window.Transformer = Transformer = do ->

  TRANSFORM_ATTRIBUTES = [
    'translateX', 'translateY', 'translateZ',
    'rotateX', 'rotateY', 'rotateZ'
    'scale'
  ]

  _getAllProperties = (steps) ->
    props = []
    for step in steps
      for attr, value of step.object
        props.push(attr) if props.indexOf(attr) is -1
    return props

  _orderSteps = (steps) ->
    steps.sort (a, b) -> 
      if a.percent < b.percent then -1 else 1
    return steps

  _getUnits = (key) ->
    if key.indexOf("rotate") is 0 then "deg" 
    else if key.indexOf("scale") is 0 then ""
    else "px"

  _calcAttributeValue = (attribute, percent, steps) ->
    prev = null
    next = null
    loop_prev = null
    for step in steps when step.object[attribute]?
      if step.percent >= percent
        next = {percent: step.percent, value: step.object[attribute]}
        if loop_prev
          prev = {percent: loop_prev.percent, value: loop_prev.object[attribute]}
        else prev = next
        break
      loop_prev = step
    value = (next.value - prev.value) * (percent - prev.percent) / 
            (next.percent - prev.percent) + prev.value

    if isNaN(value) then 0 else value


  _applyCssToElement = (element, attributes) ->
    transforms = []
    for key, value of attributes
      if TRANSFORM_ATTRIBUTES.indexOf(key) is -1
        element.style[key] = value
      else
        transforms.push("#{key}(#{value}#{_getUnits(key)})")
    if transforms.length
      element.style.webkitTransform = transforms.join(" ")
      element.style.MozTransform = transforms.join(" ")


  class CSS

    constructor: (@el, options={}) ->
      @steps = []
      @initialized = false
      return @

    init: ->
      @steps = _orderSteps(@steps)
      @all_properties = _getAllProperties(@steps)
      @initialized = true

    addStep: (percent, obj) ->
      @initialized = false
      @steps.push(percent: percent, object: obj)
      return @

    set: (percent, animate=false) ->
      if not @initialized then @init()
      element_properties = {}
      for property in @all_properties
        value = _calcAttributeValue(property, percent, @steps)
        element_properties[property] = value
      _applyCssToElement(@el, element_properties)
      return @

  (el) -> new CSS(el)




Book = do ->

  _bookContainer = ->
    el = document.createElement("article")
    el.className = "book"
    el

  BookClass = ->
    @container = null
    @pages = []
    @sides = []
    @index = -1
    return @

  BookClass:: =

    addDoublePage: (html) ->
      len = @pages.length
      @sides.push(BookPage.createPageSide(html, true))
      @sides.push(BookPage.createPageSide(html, true, true))
      return @

    addPage: (html) ->
      @sides.push(BookPage.createPageSide(html))
      return @

    next: ->
      len =  @pages.length
      if len > @index + 1
        @index++
        @pages[@index].toggle(false)
        return true
      return false

    previous: ->
      if @index > -1
        @pages[@index].toggle(true)
        @index--
        return true
      return false

    render: (container) ->
      @element = _bookContainer()
      container.appendChild(@element)
      total_pages = Math.round(@sides.length / 2)
      i = 0
      while i < @sides.length
        front = @sides[i]
        back = if i + 1 < @sides.length then @sides[i + 1] else null
        page = BookPage.create(front, back, @pages.length, total_pages)
        page.render(@element)
        @pages.push(page)
        i += 2

      BookEvents.init(@)
      return @

    currentPage: ->
      @pages[@index]


  create: (options) ->
    new BookClass(options or {})


window.Book = Book


BookPage = do ->

  # _next_transform = (el) ->
  #   Transformer(el)
  #     .addStep(0, rotateY: 0)
  #     .addStep(100, rotateY: -180)

  # _prev_transform = (el) ->
  #   Transformer(el)
  #     .addStep(0, rotateY: -180)
  #     .addStep(100, rotateY: 0)

  _bindToTransitionEnd = (el, callback) ->
    el.addEventListener("webkitTransitionEnd", callback)
    el.addEventListener("transitionend", callback)

  _unbindToTransitionEnd = (el, callback) ->
    el.removeEventListener("webkitTransitionEnd", callback)
    el.removeEventListener("transitionend", callback)

  _createPageContainer = (index, total_index) ->
    element = document.createElement("section")
    element.setAttribute("data-page-index", (index + 1) + "/" + total_index)
    element.className = "book-page"
    element.style.zIndex = index * -1
    element

  _onTransitionEnd = (ev) ->
    ev.currentTarget.removeAttribute("style")
    index_parts = ev.currentTarget.getAttribute("data-page-index").split("/")
    current = index_parts[0] - 1
    total = index_parts[1] - 1
    if ev.currentTarget.getAttribute("data-status")
      ev.currentTarget.style.zIndex = (total - current) * -1
    else ev.currentTarget.style.zIndex = current * -1
    _unbindToTransitionEnd(ev.currentTarget, _onTransitionEnd)
    ev.preventDefault()
    ev.stopPropagation()

  PageClass = (front_side, back_side, index, total_index) ->
    @element = _createPageContainer(index, total_index)
    front_side.className = "book-page-front"
    @element.appendChild(front_side)
    back_side or= document.createElement("div")
    back_side.className = "book-page-back"
    @element.appendChild(back_side)
    # @forward_tr = _next_transform(@element)
    # @backward_tr = _prev_transform(@element)
    return @


  PageClass:: =

    toggle: (is_back=false) ->
      _bindToTransitionEnd(@element, _onTransitionEnd)
      @element.removeAttribute("style")
      @element.removeAttribute("book-page-noanim")
      @element.style.zIndex = 1
      if is_back is true
       @element.removeAttribute("data-status")
      else
        @element.setAttribute("data-status", "passed")
      return @

    render: (container) ->
      container.appendChild(@element)



  create: (front, back, index, total_index) ->
    return new PageClass(front, back, index, total_index)

  createPageSide: (html, is_double = false, scrolled_right = false) ->
    el = document.createElement("div")
    if is_double is true
      el.setAttribute("data-page-type", "double")
      subel = document.createElement("div")
      subel.innerHTML = html
      el.appendChild(subel)
      if scrolled_right is true
        el.scrollLeft = 999999
        subel.scrollLeft = 999999
      else
        el.scrollLeft = 0
        subel.scrollLeft = 0

    else
      el.innerHTML = html
    el



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
