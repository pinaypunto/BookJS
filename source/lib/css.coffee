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



