# Recognized gestures:
  # pullup    - the finger is currently above the touch starting position
  # pulldown  - the finger is currently below the touch starting position
  # pullright - the finger is currently to the right of the touch starting position
  # pullleft  - the finger is currently to the left of the touch starting position
  # held      - the finger was held in the same position for some time
  # tapped    - the finger tapped a position

# Data passed with triggered event:
  # originalEvent    - the original touch event
  # start.{x,y,time} - the touch starting position and time
  # last.{x,y,time}  - the touch starting position and time
  # (/note The following two values are calibrated to accommodate the delayed gesture detection due to held detection)
  # dx               - the horizontal change in motion since touch start
  # dy               - the vertical change in motion since touch start
  # (The following two values are the absolute versions of the above two)
  # absolute_dx
  # absolute_dy
  # (/end note)
  # gestures         - list of currently active gestures
  # gestures         - list of currently active gestures
  # gesture_detected.{x,y,time}   - the position and time that the gesture was detected
  # document_vertical_scrolling   - the document is being vertically scrolled
  # document_horizontal_scrolling - the document is being horizontally scrolled

$ = jQuery


# Thresholds and constants
# distance in pixels, times in ms
thresholds =
  distance:
    scroll : 3
    held   : 3
  time:
    held   : 300


# Variables
touch_data = {}
touch_data.start    = {}
touch_data.last     = {}
touch_data.gestures = {}
touch_data.gesture_detected = {}


# Set up gesture events that can be bound to
$.event.special.pullup    = {}
$.event.special.pulldown  = {}
$.event.special.pullright = {}
$.event.special.pullleft  = {}
$.event.special.held      = {}
$.event.special.tapped    = {}
 

# Catch all touch events
$(document).ready ->
  #console.log "binding to document touch events"
  $(document).bind 'touchstart.fingers', touchStartHandler
  $(document).bind 'touchmove.fingers',  touchMoveHandler
  $(document).bind 'touchend.fingers',   touchEndHandler


# Event handlers
touchStartHandler = (event) ->
  #console.log "touchstart"
  # Reset all variables
  touch_data.start = extractTouchData event
  touch_data.last  = Object.create touch_data.start
  touch_data.gesture_detected = null # means no gesture detected
  touch_data.gestures = {}
  
  touch_data.absolute_dx = 0
  touch_data.absolute_dy = 0
  
  touch_data.document_vertical_scrolling   = false
  touch_data.document_horizontal_scrolling = false
  
  touch_data.dx = 0
  touch_data.dy = 0
  
  # After a delay, check if held
  delay thresholds.time.held, =>
    #console.log "checking if held"
    if not touch_data.gesture_detected
      #console.log "gesture detected by time"
      threshold = thresholds.distance.held
      touch_data.gestures.held = (touch_data.absolute_dx <= threshold and touch_data.absolute_dy <= threshold)
      #console.log "held" if touch_data.gestures.held
      gestureDetected()
    triggerEvents($(event.target), event) if touch_data.gestures.held
   
  return true

touchMoveHandler = (event) ->
  #console.log "touchmove"
  touch_data.last = extractTouchData event
  
  touch_data.absolute_dx = touch_data.last.x - touch_data.start.x
  touch_data.absolute_dy = touch_data.last.y - touch_data.start.y

  # Check if document scrolling
  if Math.abs(touch_data.absolute_dy) > thresholds.distance.scroll
    touch_data.document_vertical_scrolling = true
    #console.log "document vertical scrolling"
   
  if Math.abs(touch_data.absolute_dx) > thresholds.distance.scroll
    touch_data.document_horizontal_scrolling = true
    #console.log "document horizontal scrolling"
   
  # Check if gesture detected
  threshold = thresholds.distance.held
  if not touch_data.gesture_detected and (Math.abs(touch_data.absolute_dx) > threshold or Math.abs(touch_data.absolute_dy) > threshold)
    #console.log "gesture detected by moving"
    gestureDetected()
  
  if touch_data.gesture_detected
    touch_data.dx = calibrateDiff touch_data.absolute_dx, 'x'
    touch_data.dy = calibrateDiff touch_data.absolute_dy, 'y'
    
    # Detect pulling if not held
    if touch_data.gestures.held is true
      touch_data.gestures.pullup    = false
      touch_data.gestures.pulldown  = false
      touch_data.gestures.pullright = false
      touch_data.gestures.pullleft  = false
    else
      if touch_data.absolute_dy is 0
        touch_data.gestures.pullup   = false
        touch_data.gestures.pulldown = false
      else if touch_data.absolute_dy > 0
        # Pulling down
        touch_data.gestures.pulldown = true
        touch_data.gestures.pullup   = false
      else if touch_data.absolute_dy < 0
        # Pulling up
        touch_data.gestures.pullup   = true
        touch_data.gestures.pulldown = false
        
      if touch_data.absolute_dx is 0
        touch_data.gestures.pullright = false
        touch_data.gestures.pullleft  = false
      else if touch_data.absolute_dx > 0
        # Pulling right
        touch_data.gestures.pullright = true
        touch_data.gestures.pullleft  = false
      else if touch_data.absolute_dx < 0
        # Pulling left
        touch_data.gestures.pullleft  = true
        touch_data.gestures.pullright = false

      triggerEvents $(event.target), event

  return true

touchEndHandler = (event) ->
  #console.log "touchend"
  # Trigger events if gestures detected
  if Object.keys(touch_data.gestures).length is 0 # no gestures detected
    threshold = thresholds.distance.held
    if touch_data.absolute_dx <= threshold and touch_data.absolute_dy <= threshold # within held threshold
      # Tapped
      touch_data.gestures.tapped = true
      gestureDetected()
      triggerEvents $(event.target), event

  return true


# Methods
gestureDetected = ->
  touch_data.gesture_detected = Object.create touch_data.last # REFACTOR

triggerEvents = (element, original_event) ->
  # Trigger the correct event on the element
  gesture_list = Object.keys(touch_data.gestures)
  for gesture in gesture_list
    if touch_data.gestures[gesture]
      #console.log "triggering event on element. gesture: " + gesture + ". element: "
      touch_data.originalEvent = original_event
      element.trigger gesture, touch_data


# Utilities
extractTouchData = (event) ->
  x    : event.originalEvent.touches[0].pageX
  y    : event.originalEvent.touches[0].pageY
  time : new Date()

calibrateDiff = (diff, diff_key) ->
  # Since we're detecting pulling with a delay due to held tolerance, we calibrate diff to account for this
  zero_diff = touch_data.gesture_detected[diff_key] - touch_data.start[diff_key]
  calibrated = diff
  
  if diff > zero_diff
    calibrated -= zero_diff
  else if diff < -zero_diff
    calibrated += zero_diff
  else
    calibrated = 0
  return calibrated
 

# Helpers
window.delay = (ms, func) -> setTimeout func, ms