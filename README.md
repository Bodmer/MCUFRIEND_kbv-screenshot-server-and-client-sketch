# Processing TFT screenshot client

This is a Processing sketch, see https://processing.org/ to download the IDE

The sketch is a client that requests TFT screenshots from an Arduino board.
The Arduino must call a screenshot server function to respond with pixels.

This sketch has been created to work with the library (at v2.9) here:
https://github.com/prenticedavid/MCUFRIEND_kbv
and a Arduino compatible sketch called kbv_screen_server that is in the Github repository
with this Processing sketch here:
https://github.com/Bodmer/MCUFRIEND_kbv-screenshot-server-and-client-sketch

The sketch must only be run when the designated serial port is available and enumerated
otherwise the screenshot window may freeze and that process will need to be terminated
This is a limitation of the Processing environment and not the sketch.
If anyone knows how to determine if a serial port is available at start up the PM me
on (Bodmer) the Arduino forum.

The block below contains variables that the user may need to change for a particular setup
As a minimum set the serial port and baud rate must be defined. The cpture window is
automatically resized for landscape, portrait and different TFT resolutions.

Captured images are stored in the sketch folder, use the Processing IDE "Sketch" menu
option "Show Sketch Folder" or press Ctrl+K

To do: automatically set the x and y screen size

Created by: Bodmer 5/3/17

MIT licence applies, all text above must be included in derivative works

Version 0.01