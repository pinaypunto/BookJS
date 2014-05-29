(function() {
  var Book, BookEvents, BookPage, Transformer;

  window.Transformer = Transformer = (function() {
    var CSS, TRANSFORM_ATTRIBUTES, _applyCssToElement, _calcAttributeValue, _getAllProperties, _getUnits, _orderSteps;
    TRANSFORM_ATTRIBUTES = ['translateX', 'translateY', 'translateZ', 'rotateX', 'rotateY', 'rotateZ', 'scale'];
    _getAllProperties = function(steps) {
      var attr, props, step, value, _i, _len, _ref;
      props = [];
      for (_i = 0, _len = steps.length; _i < _len; _i++) {
        step = steps[_i];
        _ref = step.object;
        for (attr in _ref) {
          value = _ref[attr];
          if (props.indexOf(attr) === -1) {
            props.push(attr);
          }
        }
      }
      return props;
    };
    _orderSteps = function(steps) {
      steps.sort(function(a, b) {
        if (a.percent < b.percent) {
          return -1;
        } else {
          return 1;
        }
      });
      return steps;
    };
    _getUnits = function(key) {
      if (key.indexOf("rotate") === 0) {
        return "deg";
      } else if (key.indexOf("scale") === 0) {
        return "";
      } else {
        return "px";
      }
    };
    _calcAttributeValue = function(attribute, percent, steps) {
      var loop_prev, next, prev, step, value, _i, _len;
      prev = null;
      next = null;
      loop_prev = null;
      for (_i = 0, _len = steps.length; _i < _len; _i++) {
        step = steps[_i];
        if (!(step.object[attribute] != null)) {
          continue;
        }
        if (step.percent >= percent) {
          next = {
            percent: step.percent,
            value: step.object[attribute]
          };
          if (loop_prev) {
            prev = {
              percent: loop_prev.percent,
              value: loop_prev.object[attribute]
            };
          } else {
            prev = next;
          }
          break;
        }
        loop_prev = step;
      }
      value = (next.value - prev.value) * (percent - prev.percent) / (next.percent - prev.percent) + prev.value;
      if (isNaN(value)) {
        return 0;
      } else {
        return value;
      }
    };
    _applyCssToElement = function(element, attributes) {
      var key, transforms, value;
      transforms = [];
      for (key in attributes) {
        value = attributes[key];
        if (TRANSFORM_ATTRIBUTES.indexOf(key) === -1) {
          element.style[key] = value;
        } else {
          transforms.push("" + key + "(" + value + (_getUnits(key)) + ")");
        }
      }
      if (transforms.length) {
        element.style.webkitTransform = transforms.join(" ");
        return element.style.MozTransform = transforms.join(" ");
      }
    };
    CSS = (function() {
      function CSS(el, options) {
        this.el = el;
        if (options == null) {
          options = {};
        }
        this.steps = [];
        this.initialized = false;
        return this;
      }

      CSS.prototype.init = function() {
        this.steps = _orderSteps(this.steps);
        this.all_properties = _getAllProperties(this.steps);
        return this.initialized = true;
      };

      CSS.prototype.addStep = function(percent, obj) {
        this.initialized = false;
        this.steps.push({
          percent: percent,
          object: obj
        });
        return this;
      };

      CSS.prototype.set = function(percent, animate) {
        var element_properties, property, value, _i, _len, _ref;
        if (animate == null) {
          animate = false;
        }
        if (!this.initialized) {
          this.init();
        }
        element_properties = {};
        _ref = this.all_properties;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          property = _ref[_i];
          value = _calcAttributeValue(property, percent, this.steps);
          element_properties[property] = value;
        }
        _applyCssToElement(this.el, element_properties);
        return this;
      };

      return CSS;

    })();
    return function(el) {
      return new CSS(el);
    };
  })();

  Book = (function() {
    var BookClass, _bookContainer;
    _bookContainer = function() {
      var el;
      el = document.createElement("article");
      el.className = "book";
      return el;
    };
    BookClass = function() {
      this.container = null;
      this.pages = [];
      this.sides = [];
      this.index = -1;
      return this;
    };
    BookClass.prototype = {
      addDoublePage: function(html) {
        var len;
        len = this.pages.length;
        this.sides.push(BookPage.createPageSide(html, true));
        this.sides.push(BookPage.createPageSide(html, true, true));
        return this;
      },
      addPage: function(html) {
        this.sides.push(BookPage.createPageSide(html));
        return this;
      },
      next: function() {
        var len;
        len = this.pages.length;
        if (len > this.index + 1) {
          this.index++;
          this.pages[this.index].toggle(false);
          return true;
        }
        return false;
      },
      previous: function() {
        if (this.index > -1) {
          this.pages[this.index].toggle(true);
          this.index--;
          return true;
        }
        return false;
      },
      render: function(container) {
        var back, front, i, page, total_pages;
        this.element = _bookContainer();
        container.appendChild(this.element);
        total_pages = Math.round(this.sides.length / 2);
        i = 0;
        while (i < this.sides.length) {
          front = this.sides[i];
          back = i + 1 < this.sides.length ? this.sides[i + 1] : null;
          page = BookPage.create(front, back, this.pages.length, total_pages);
          page.render(this.element);
          this.pages.push(page);
          i += 2;
        }
        BookEvents.init(this);
        return this;
      },
      currentPage: function() {
        return this.pages[this.index];
      }
    };
    return {
      create: function(options) {
        return new BookClass(options || {});
      }
    };
  })();

  window.Book = Book;

  BookPage = (function() {
    var PageClass, _bindToTransitionEnd, _createPageContainer, _onTransitionEnd, _unbindToTransitionEnd;
    _bindToTransitionEnd = function(el, callback) {
      el.addEventListener("webkitTransitionEnd", callback);
      return el.addEventListener("transitionend", callback);
    };
    _unbindToTransitionEnd = function(el, callback) {
      el.removeEventListener("webkitTransitionEnd", callback);
      return el.removeEventListener("transitionend", callback);
    };
    _createPageContainer = function(index, total_index) {
      var element;
      element = document.createElement("section");
      element.setAttribute("data-page-index", (index + 1) + "/" + total_index);
      element.className = "book-page";
      element.style.zIndex = index * -1;
      return element;
    };
    _onTransitionEnd = function(ev) {
      var current, index_parts, total;
      ev.currentTarget.removeAttribute("style");
      index_parts = ev.currentTarget.getAttribute("data-page-index").split("/");
      current = index_parts[0] - 1;
      total = index_parts[1] - 1;
      if (ev.currentTarget.getAttribute("data-status")) {
        ev.currentTarget.style.zIndex = (total - current) * -1;
      } else {
        ev.currentTarget.style.zIndex = current * -1;
      }
      _unbindToTransitionEnd(ev.currentTarget, _onTransitionEnd);
      ev.preventDefault();
      return ev.stopPropagation();
    };
    PageClass = function(front_side, back_side, index, total_index) {
      this.element = _createPageContainer(index, total_index);
      front_side.className = "book-page-front";
      this.element.appendChild(front_side);
      back_side || (back_side = document.createElement("div"));
      back_side.className = "book-page-back";
      this.element.appendChild(back_side);
      return this;
    };
    PageClass.prototype = {
      toggle: function(is_back) {
        if (is_back == null) {
          is_back = false;
        }
        _bindToTransitionEnd(this.element, _onTransitionEnd);
        this.element.removeAttribute("style");
        this.element.removeAttribute("book-page-noanim");
        this.element.style.zIndex = 1;
        if (is_back === true) {
          this.element.removeAttribute("data-status");
        } else {
          this.element.setAttribute("data-status", "passed");
        }
        return this;
      },
      render: function(container) {
        return container.appendChild(this.element);
      }
    };
    return {
      create: function(front, back, index, total_index) {
        return new PageClass(front, back, index, total_index);
      },
      createPageSide: function(html, is_double, scrolled_right) {
        var el, subel;
        if (is_double == null) {
          is_double = false;
        }
        if (scrolled_right == null) {
          scrolled_right = false;
        }
        el = document.createElement("div");
        if (is_double === true) {
          el.setAttribute("data-page-type", "double");
          subel = document.createElement("div");
          subel.innerHTML = html;
          el.appendChild(subel);
          if (scrolled_right === true) {
            el.scrollLeft = 999999;
            subel.scrollLeft = 999999;
          } else {
            el.scrollLeft = 0;
            subel.scrollLeft = 0;
          }
        } else {
          el.innerHTML = html;
        }
        return el;
      }
    };
  })();

  BookEvents = (function() {
    var RESISTANCE, TRIGGER_PX, init, _closestPage, _current, _diffX, _end, _getEventX, _move, _next_transform, _prev_transform, _start, _startX, _started;
    TRIGGER_PX = 50;
    RESISTANCE = 0.5;
    _current = null;
    _started = false;
    _diffX = 0;
    _startX = 0;
    _closestPage = function(ev_target) {
      var current, i;
      console.log(ev_target);
      console.log("p1", ev_target.parentNode);
      console.log("p2", ev_target.parentNode.parentNode);
      console.log("p3", ev_target.parentNode.parentNode.parentNode);
      if (ev_target.className === "book-page") {
        return ev_target;
      } else {
        current = ev_target;
        i = 0;
        while ((current.parentNode != null) && i++ < 100) {
          if (current.parentNode.className === "book-page") {
            return current.parentNode;
          }
        }
      }
      return null;
    };
    _next_transform = function(el) {
      return Transformer(el).addStep(0, {
        rotateY: 0
      }).addStep(100, {
        rotateY: -180
      });
    };
    _prev_transform = function(el) {
      return Transformer(el).addStep(0, {
        rotateY: -180
      }).addStep(100, {
        rotateY: 0
      });
    };
    _getEventX = function(ev) {
      return ev.pageX;
    };
    _start = function() {
      return function(ev) {
        _started = true;
        _diffX = 0;
        _startX = _getEventX(ev);
        ev.preventDefault();
        ev.stopPropagation();
        _current = _closestPage(ev.target);
        _current.style.zIndex = 1;
      };
    };
    _move = function() {
      return function(ev) {
        var _percent;
        if (_started && _current) {
          _diffX = _getEventX(ev) - _startX;
          _percent = Math.max(Math.min(_diffX * 20 / TRIGGER_PX, 99), -99);
          _current.setAttribute("book-page-noanim", "true");
          if (_diffX < 0 && !_current.getAttribute("data-status")) {
            _next_transform(_current).set(Math.abs(_percent));
          } else if (_diffX > 0 && _current.getAttribute("data-status")) {
            _prev_transform(_current).set(Math.abs(_percent));
          }
          ev.preventDefault();
          ev.stopPropagation();
        }
      };
    };
    _end = function(book_instance) {
      return function(ev) {
        var absDiff, command;
        _started = false;
        absDiff = Math.abs(_diffX);
        console.log(absDiff);
        if (absDiff > TRIGGER_PX) {
          command = _diffX > 0 ? "previous" : "next";
          book_instance[command]();
        } else if (_current) {
          _current.removeAttribute("book-page-noanim");
          _current.removeAttribute("style");
        }
        _current = null;
        _started = false;
        _diffX = 0;
        _startX = 0;
      };
    };
    init = function(book_instance) {
      book_instance.element.addEventListener("mousedown", _start(book_instance));
      book_instance.element.addEventListener("mousemove", _move(book_instance));
      book_instance.element.addEventListener("mouseup", _end(book_instance));
    };
    return {
      init: init
    };
  })();

}).call(this);
