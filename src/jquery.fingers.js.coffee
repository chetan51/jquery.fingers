# Recognized gestures:
  # pullup    - the finger is currently above the touch starting position
  # pulldown  - the finger is currently below the touch starting position
  # pullright - the finger is currently to the right of the touch starting position
  # pullleft  - the finger is currently to the left of the touch starting position
  # hold      - the finger was held in the same position for some time
  # tap       - the finger tapped a position

# Data passed with triggered event:
  # start.{x,y,time} - the touch starting position and time
  # last.{x,y,time}  - the touch starting position and time
  # (/note The following two values are calibrated to accommodate the delayed gesture detection due to hold detection)
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
    hold   : 3
  time:
    hold   : 300


# Variables
touch_data = {}
touch_data.start    = {}
touch_data.last     = {}
touch_data.gestures = {}
touch_data.gesture_detected = {}


# Set up gestures
eventSetup = ->
  #console.log "setup for element: "
  #console.log $(this)
  # Unbind any existing touch events, and then bind. Ensures one handler per event.
  $(this).off '.fingers'
  $(this).on 'touchstart.fingers', elementTouchStartHandler
  $(this).on 'touchmove.fingers',  elementTouchMoveHandler
  $(this).on 'touchend.fingers',   elementTouchEndHandler

eventTeardown = ->
  #console.log "teardown"
  # Unbind touch events
  $(this).off '.fingers'
 
$.event.special.pullup    = setup: eventSetup, teardown: eventTeardown
$.event.special.pulldown  = setup: eventSetup, teardown: eventTeardown
$.event.special.pullright = setup: eventSetup, teardown: eventTeardown
$.event.special.pullleft  = setup: eventSetup, teardown: eventTeardown
$.event.special.hold      = setup: eventSetup, teardown: eventTeardown
$.event.special.tap       = setup: eventSetup, teardown: eventTeardown
 

# Bind to whole document
$(document).ready ->
  #console.log "binding to document touch events"
  $(document).bind 'touchstart.fingers', documentTouchStartHandler
  $(document).bind 'touchmove.fingers',  documentTouchMoveHandler
  $(document).bind 'touchend.fingers',   documentTouchEndHandler

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

touchMoveHandler = (event) ->
  #console.log "touchmove"
  touch_data.last = extractTouchData event
  
  touch_data.absolute_dx = touch_data.last.x - touch_data.start.x
  touch_data.absolute_dy = touch_data.last.y - touch_data.start.y

touchEndHandler = (event) ->
  #console.log "touchend"


elementTouchStartHandler = (event) ->
  #console.log "element touchstart. element: "
  #console.log $(this)
  touch_data.dx = 0
  touch_data.dy = 0
  
  # After a delay, check if holding
  delay thresholds.time.hold, =>
    #console.log "checking if holding"
    if not touch_data.gesture_detected
      console.log "gesture detected by time"
      threshold = thresholds.distance.hold
      touch_data.gestures.hold = (touch_data.absolute_dx <= threshold and touch_data.absolute_dy <= threshold)
      #console.log "holding" if touch_data.gestures.hold
      gestureDetected()
    triggerEvents($(this)) if touch_data.gestures.hold
   
  return true

elementTouchMoveHandler = (event) ->
  #console.log "element touchmove. absolute dx: " + touch_data.absolute_dx + ". absolute dy: " + touch_data.absolute_dy
  # Gesture detected if moved outside the hold threshold
  threshold = thresholds.distance.hold
  if not touch_data.gesture_detected and (touch_data.absolute_dx > threshold or touch_data.absolute_dy > threshold)
    console.log "gesture detected by moving"
    gestureDetected()
  
  if touch_data.gesture_detected
    touch_data.dx = calibrateDiff touch_data.absolute_dx, 'x'
    touch_data.dy = calibrateDiff touch_data.absolute_dy, 'y'
    
    # Detect pulling if not holding
    if touch_data.gestures.hold is true
      touch_data.gestures.pullup    = false
      touch_data.gestures.pulldown  = false
      touch_data.gestures.pullright = false
      touch_data.gestures.pullleft  = false
    else
      if touch_data.dy is 0
        touch_data.gestures.pullup   = false
        touch_data.gestures.pulldown = false
      else if touch_data.dy > 0
        # Pulling down
        touch_data.gestures.pulldown = true
        touch_data.gestures.pullup   = false
      else if touch_data.dy < 0
        # Pulling up
        touch_data.gestures.pullup   = true
        touch_data.gestures.pulldown = false
        
      if touch_data.dx is 0
        touch_data.gestures.pullright = false
        touch_data.gestures.pullleft  = false
      else if touch_data.dx > 0
        # Pulling right
        touch_data.gestures.pullright = true
        touch_data.gestures.pullleft  = false
      else if touch_data.dx < 0
        # Pulling left
        touch_data.gestures.pullleft  = true
        touch_data.gestures.pullright = false

      triggerEvents $(this)

  return true

calibrateDiff = (diff, diff_key) ->
  # Since we're detecting pulling with a delay due to hold tolerance, we calibrate diff to account for this
  zero_diff = touch_data.gesture_detected[diff_key] - touch_data.start[diff_key]
  calibrated = diff
  
  if diff > zero_diff
    calibrated -= zero_diff
  else if diff < -zero_diff
    calibrated += zero_diff
  else
    calibrated = 0
  return calibrated
 
elementTouchEndHandler = (event) ->
  #console.log "element touchend"
  if Object.keys(touch_data.gestures).length is 0 # no gestures detected
    threshold = thresholds.distance.hold
    if touch_data.absolute_dx <= threshold and touch_data.absolute_dy <= threshold # within holding threshold
      # Tapped
      touch_data.gestures.tap = true
      gestureDetected()
      triggerEvents $(this)

  return true

gestureDetected = ->
  touch_data.gesture_detected = Object.create touch_data.last # REFACTOR

triggerEvents = (element) ->
  # Trigger the correct event on the element
  gesture_list = Object.keys(touch_data.gestures)
  for gesture in gesture_list
    if touch_data.gestures[gesture]
      #console.log "triggering event on element. gesture: " + gesture + ". element: "
      #console.log element
      element.trigger gesture, touch_data

documentTouchStartHandler = (event) ->
  #console.log "document touchstart"
  touchStartHandler event
  
  touch_data.document_vertical_scrolling   = false
  touch_data.document_horizontal_scrolling = false
  
  return true

documentTouchMoveHandler = (event) ->
  #console.log "document touchmove"
  touchMoveHandler event
  
  if Math.abs(touch_data.absolute_dy) > thresholds.distance.scroll
    touch_data.document_vertical_scrolling = true
    #console.log "document vertical scrolling"
   
  if Math.abs(touch_data.absolute_dx) > thresholds.distance.scroll
    touch_data.document_horizontal_scrolling = true
    #console.log "document horizontal scrolling"
   
  return true

documentTouchEndHandler = (event) ->
  #console.log "document touchend"
  touchEndHandler event

  return true

# Utilities
extractTouchData = (event) ->
  x    : event.originalEvent.touches[0].pageX
  y    : event.originalEvent.touches[0].pageY
  time : new Date()

# Helpers
window.delay = (ms, func) -> setTimeout func, ms