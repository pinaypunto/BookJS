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

