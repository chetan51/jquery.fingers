# jQuery Fingers

It's hard to do custom touch gesture detection in Javascript. This plugin keeps it simple.

## Recognized gestures
  * **pullup**: the finger is currently above the touch starting position
  * **pulldown**: the finger is currently below the touch starting position
  * **pullright**: the finger is currently to the right of the touch starting position
  * **pullleft**: the finger is currently to the left of the touch starting position
  * **hold**: the finger was held in the same position for some time
  * **tap**: the finger tapped a position

## Data passed with triggered event
  * **start.{x,y,time}**: the touch starting position and time
  * **last.{x,y,time}**: the touch starting position and time
  
  The following two values are calibrated to accommodate the delayed gesture detection due to hold detection:
  
  * **dx**: the horizontal change in motion since touch start
  * **dy**: the vertical change in motion since touch start
  
  The following two values are the non-calibrated, raw versions of the two above:
  
  * **absolute_dx**
  * **absolute_dy**
  
  * **gestures**: list of currently active gestures
  * **gesture_detected.{x,y,time}**: the position and time that the gesture was detected
  * **document_vertical_scrolling**: the document is being vertically scrolled
  * **document_horizontal_scrolling**: the document is being horizontally scrolled
