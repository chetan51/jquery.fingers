(function() {
  var $, calibrateDiff, documentTouchEndHandler, documentTouchMoveHandler, documentTouchStartHandler, elementTouchEndHandler, elementTouchMoveHandler, elementTouchStartHandler, eventSetup, eventTeardown, extractTouchData, gestureDetected, thresholds, touchEndHandler, touchMoveHandler, touchStartHandler, touch_data, triggerEvents;
  $ = jQuery;
  thresholds = {
    distance: {
      scroll: 3,
      hold: 3
    },
    time: {
      hold: 300
    }
  };
  touch_data = {};
  touch_data.start = {};
  touch_data.last = {};
  touch_data.gestures = {};
  touch_data.gesture_detected = {};
  eventSetup = function() {
    $(this).off('.fingers');
    $(this).on('touchstart.fingers', elementTouchStartHandler);
    $(this).on('touchmove.fingers', elementTouchMoveHandler);
    return $(this).on('touchend.fingers', elementTouchEndHandler);
  };
  eventTeardown = function() {
    return $(this).off('.fingers');
  };
  $.event.special.pullup = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $.event.special.pulldown = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $.event.special.pullright = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $.event.special.pullleft = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $.event.special.hold = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $.event.special.tap = {
    setup: eventSetup,
    teardown: eventTeardown
  };
  $(document).ready(function() {
    $(document).bind('touchstart.fingers', documentTouchStartHandler);
    $(document).bind('touchmove.fingers', documentTouchMoveHandler);
    return $(document).bind('touchend.fingers', documentTouchEndHandler);
  });
  touchStartHandler = function(event) {
    touch_data.start = extractTouchData(event);
    touch_data.last = Object.create(touch_data.start);
    touch_data.gesture_detected = null;
    touch_data.gestures = {};
    touch_data.absolute_dx = 0;
    return touch_data.absolute_dy = 0;
  };
  touchMoveHandler = function(event) {
    touch_data.last = extractTouchData(event);
    touch_data.absolute_dx = touch_data.last.x - touch_data.start.x;
    return touch_data.absolute_dy = touch_data.last.y - touch_data.start.y;
  };
  touchEndHandler = function(event) {};
  elementTouchStartHandler = function(event) {
    touch_data.dx = 0;
    touch_data.dy = 0;
    delay(thresholds.time.hold, function() {
      var threshold;
      if (!touch_data.gesture_detected) {
        console.log("gesture detected by time");
        threshold = thresholds.distance.hold;
        touch_data.gestures.hold = touch_data.absolute_dx <= threshold && touch_data.absolute_dy <= threshold;
        gestureDetected();
        if (touch_data.gestures.hold) {
          return triggerEvents($(event.target));
        }
      }
    });
    return true;
  };
  elementTouchMoveHandler = function(event) {
    var threshold;
    threshold = thresholds.distance.hold;
    if (!touch_data.gesture_detected && (touch_data.absolute_dx > threshold || touch_data.absolute_dy > threshold)) {
      console.log("gesture detected by moving");
      gestureDetected();
    }
    if (touch_data.gesture_detected) {
      touch_data.dx = calibrateDiff(touch_data.absolute_dx, 'x');
      touch_data.dy = calibrateDiff(touch_data.absolute_dy, 'y');
      if (touch_data.gestures.hold === true) {
        touch_data.gestures.pullup = false;
        touch_data.gestures.pulldown = false;
        touch_data.gestures.pullright = false;
        touch_data.gestures.pullleft = false;
      } else {
        if (touch_data.dy === 0) {
          touch_data.gestures.pullup = false;
          touch_data.gestures.pulldown = false;
        } else if (touch_data.dy > 0) {
          touch_data.gestures.pulldown = true;
          touch_data.gestures.pullup = false;
        } else if (touch_data.dy < 0) {
          touch_data.gestures.pullup = true;
          touch_data.gestures.pulldown = false;
        }
        if (touch_data.dx === 0) {
          touch_data.gestures.pullright = false;
          touch_data.gestures.pullleft = false;
        } else if (touch_data.dx > 0) {
          touch_data.gestures.pullright = true;
          touch_data.gestures.pullleft = false;
        } else if (touch_data.dx < 0) {
          touch_data.gestures.pullleft = true;
          touch_data.gestures.pullright = false;
        }
        triggerEvents($(event.target));
      }
    }
    return true;
  };
  calibrateDiff = function(diff, diff_key) {
    var calibrated, zero_diff;
    zero_diff = touch_data.gesture_detected[diff_key] - touch_data.start[diff_key];
    calibrated = diff;
    if (diff > zero_diff) {
      calibrated -= zero_diff;
    } else if (diff < -zero_diff) {
      calibrated += zero_diff;
    } else {
      calibrated = 0;
    }
    return calibrated;
  };
  elementTouchEndHandler = function(event) {
    var threshold;
    if (Object.keys(touch_data.gestures).length === 0) {
      threshold = thresholds.distance.hold;
      if (touch_data.absolute_dx <= threshold && touch_data.absolute_dy <= threshold) {
        touch_data.gestures.tap = true;
        gestureDetected();
        triggerEvents($(event.target));
      }
    }
    return true;
  };
  gestureDetected = function() {
    return touch_data.gesture_detected = Object.create(touch_data.last);
  };
  triggerEvents = function(element) {
    var gesture, gesture_list, _i, _len, _results;
    gesture_list = Object.keys(touch_data.gestures);
    _results = [];
    for (_i = 0, _len = gesture_list.length; _i < _len; _i++) {
      gesture = gesture_list[_i];
      _results.push(touch_data.gestures[gesture] ? element.trigger(gesture, touch_data) : void 0);
    }
    return _results;
  };
  documentTouchStartHandler = function(event) {
    touchStartHandler(event);
    touch_data.document_vertical_scrolling = false;
    touch_data.document_horizontal_scrolling = false;
    return true;
  };
  documentTouchMoveHandler = function(event) {
    touchMoveHandler(event);
    if (Math.abs(touch_data.absolute_dy) > thresholds.distance.scroll) {
      touch_data.document_vertical_scrolling = true;
    }
    if (Math.abs(touch_data.absolute_dx) > thresholds.distance.scroll) {
      touch_data.document_horizontal_scrolling = true;
    }
    return true;
  };
  documentTouchEndHandler = function(event) {
    touchEndHandler(event);
    return true;
  };
  extractTouchData = function(event) {
    return {
      x: event.originalEvent.touches[0].pageX,
      y: event.originalEvent.touches[0].pageY,
      time: new Date()
    };
  };
  window.delay = function(ms, func) {
    return setTimeout(func, ms);
  };
}).call(this);
