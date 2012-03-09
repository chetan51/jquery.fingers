# jQuery Fingers

It's hard to do custom touch gesture detection in Javascript. This plugin keeps it simple.

(Requires jQuery 1.7+)

## Usage

Include the script after jQuery...

    <script src='/path/to/jquery.js'></script>
    <script src='/lib/jquery.fingers.js'></script>

and then start binding elements to any events in the list below. 

    $("#box").bind 'pullright', (event, data) ->
        alert "box pulled " + data.dx + " pixels to the right"

## Recognized gestures as events

  * **pullup**: the finger is currently above the touch starting position
  * **pulldown**: the finger is currently below the touch starting position
  * **pullright**: the finger is currently to the right of the touch starting position
  * **pullleft**: the finger is currently to the left of the touch starting position
  * **held**: the finger was held in the same position for some time
  * **tapped**: the finger tapped a position

## Data passed with triggered event

  * **start.{x,y,time}**: the touch starting position and time
  * **last.{x,y,time}**: the touch starting position and time
  
  For the following two values, "a gesture was detected" means a gesture broke out of its uncertainty threshold, and is definitely happening:
  
  * **dx**: the horizontal change in motion since a gesture was detected
  * **dy**: the vertical change in motion since a gesture was detected
  
  The following two values are the absolute versions of the ones above:
  
  * **absolute_dx**: the horizontal change in motion since touch started
  * **absolute_dy**: the vertical change in motion since touch started
  
  A couple more potentially useful things:
  
  * **gestures**: list of currently active gestures
  * **gesture_detected.{x,y,time}**: the position and time that the gesture was detected
  * **document_vertical_scrolling**: the document is being vertically scrolled
  * **document_horizontal_scrolling**: the document is being horizontally scrolled
 
## Make it better

It would be nice if it could recognize more gestures. Feel free to add what you need, just remember to send that pull request when you're done :)

And yeah, you probably noticed the irony in the name by now. jQuery Fingers can only recognize one finger. I was hoping the name would encourage the obvious next step of adding multi-finger detection. The challenge is doing so while keeping it simple. Working on it.
