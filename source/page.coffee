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


