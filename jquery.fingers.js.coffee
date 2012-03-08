# Recognized gestures:
  # pullup   - the finger is currently above the touch starting position
  # pulldown - the finger is currently below the touch starting position

$ = jQuery


# Thresholds and constants
# distance in pixels, times in ms
thresholds =
  distance:
    scroll : 3
    hold  : 3
  time:
    hold  : 300


# Variables
touch_data = {}
touch_data.start    = {}
touch_data.end      = {}
touch_data.gestures = {}

touch_state = {}


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
 
$.event.special.pullup   = setup: eventSetup, teardown: eventTeardown
$.event.special.pulldown = setup: eventSetup, teardown: eventTeardown
 

# Bind to whole document
$(document).ready ->
  $(document).bind 'touchstart.fingers', documentTouchStartHandler
  $(document).bind 'touchmove.fingers',  documentTouchMoveHandler
  $(document).bind 'touchend.fingers',   documentTouchEndHandler

# Event handlers
touchStartHandler = (event) ->
  #console.log "touchstart"
  touch_data.start = extractTouchData event
  touch_data.last  = Object.create touch_data.start
  
  touch_data.dx = 0
  touch_data.dy = 0

touchMoveHandler = (event) ->
  #console.log "touchmove"
  touch_data.last = extractTouchData event
  
  touch_data.dx = touch_data.last.x - touch_data.start.x
  touch_data.dy = touch_data.last.y - touch_data.start.y

touchEndHandler = (event) ->
  #console.log "touchend"


elementTouchStartHandler = (event) ->
  console.log "element touchstart"
  # After a delay, check if holding
  delay thresholds.time.hold, ->
    threshold = thresholds.distance.hold
    touch_data.gestures.hold = (touch_data.dx <= threshold and touch_data.dy <= threshold)
    console.log "holding" if touch_data.gestures.hold
  return true

elementTouchMoveHandler = (event) ->
  #console.log "element touchmove"
  if touch_data.gestures.hold or touch_data.dy is 0
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

  # Trigger the correct event on the element
  gesture_list = Object.keys(touch_data.gestures)
  for gesture in gesture_list
    if touch_data.gestures[gesture]
      #console.log "triggering event on element. gesture: " + gesture
      $(event.target).trigger gesture, touch_data

  return true

elementTouchEndHandler = (event) ->
  #console.log "element touchend"
  return true

documentTouchStartHandler = (event) ->
  #console.log "document touchstart"
  touchStartHandler event
  
  touch_state.document_vertical_scrolling   = false
  touch_state.document_horizontal_scrolling = false
  
  return true

documentTouchMoveHandler = (event) ->
  #console.log "document touchmove"
  touchMoveHandler event
  
  dy = touch_data.last.y - touch_data.start.y
  if Math.abs(dy) > thresholds.distance.scroll
    touch_state.document_vertical_scrolling = true
    #console.log "document vertical scrolling"
   
  dx = touch_data.last.x - touch_data.start.x
  if Math.abs(dx) > thresholds.distance.scroll
    touch_state.document_horizontal_scrolling = true
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