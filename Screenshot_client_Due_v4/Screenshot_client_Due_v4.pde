// This is a Processing sketch, see https://processing.org/ to download the IDE

// The sketch is a client that requests TFT screenshots from an Arduino board.
// The Arduino must call a screenshot server function to respond with pixels.

// This sketch has been created to work with the library (at v2.9) here:
// https://github.com/prenticedavid/MCUFRIEND_kbv
// and a Arduino compatible sketch called kbv_screen_server that is in the Github repository
// with this Processing sketch here:
// https://github.com/Bodmer/MCUFRIEND_kbv-screenshot-server-and-client-sketch

// The sketch must only be run when the designated serial port is available and enumerated
// otherwise the screenshot window may freeze and that process will need to be terminated
// This is a limitation of the Processing environment and not the sketch.
// If anyone knows how to determine if a serial port is available at start up the PM me
// on (Bodmer) the Arduino forum.

// The block below contains variables that the user may need to change for a particular setup
// As a minimum set the serial port and baud rate must be defined. The cpture window is
// automatically resized for landscape, portrait and different TFT resolutions.

// Captured images are stored in the sketch folder, use the Processing IDE "Sketch" menu
// option "Show Sketch Folder" or press Ctrl+K

// To do: automatically set the x and y screen size

// Created by: Bodmer 5/3/17

// MIT licence applies, all text above must be included in derivative works

import processing.serial.*;

Serial serial;           // Create an instance called serial

// ###########################################################################################
// #                  These are the values to change for a particular setup                  #
//                                                                                           #
int serial_port = 1;     // Use enumerated value from list provided when sketch is run       #
//                                                                                           #
// On an Arduino Due Programming Port use a baud rate of:115200)                             #
// On an Arduino Due Native USB Port use a baud rate of any value                            #
int serial_baud_rate = 115200; //                                                            #
//                                                                                           #
// These are default values, this sketch obtains the actual values from the Arduino board    #
int tft_width  = 480;    // default TFT width                                                #
int tft_height = 480;    // default TFT height                                               #
//                                                                                           #
int color_bytes = 2;     // 2 for 16 bit transfers, 3 for three RGB bytes                    #
//                                                                                           #
// Change the image file type saved here, comment out all but one                            #
//String image_type = ".jpg"; //                                                             #
String image_type = ".png";   // Lossless compression                                        #
//String image_type = ".bmp"; //                                                             #
//String image_type = ".tif"; //                                                             #
//                                                                                           #
boolean save_border = true;   // Save the image with a border                                #
int border = 5;               // Border pixel width                                          #
boolean fade = false;         // Fade out image after saving                                 #
//                                                                                           #
int max_images = 12; // Maximum of numbered saved images before over-writing files           #
//                                                                                           #
// #                   End of the values to change for a particular setup                    #
// ###########################################################################################

int serialCount = 0;    // Count of colour bytes arriving

color bgcolor1 = color(0, 100, 104);			// Background colors
//color bgcolor2 = color(23, 161, 165);
color bgcolor2 = color(77, 183, 187);
//color bgcolor2 = color(255, 255, 255);

color frameColor = 42;

int[] rgb = new int[6]; // Buffer for the RGB colour bytes
int indexRed   = 0;     // Colour byte index in the array
int indexGreen = 1;
int indexBlue  = 2;

int n = 0;

int x_offset = (500 - tft_width) /2; // Image offsets in the window
int y_offset = 20; //
int xpos, ypos;                // Pixel position

int beginTime     = 0;
int pixelWaitTime = 1000;  // Maximum 1000ms wait for image pixels to arrive
int lastPixelTime = 0;     // Time that "image send" command was sent

int state = 0;  // State machine current state

int   progress_bar = 0;
int   pixel_count  = 0;
float percentage   = 0;

int drawLoopCount = 0;

void setup() {

  size(500, 540);  // Stage size, can handle 480 pixels wide screen
  noStroke();      // No border on the next thing drawn

  // Graded background
  drawWindow();

  frameRate(5000); // High frame rate so draw() loops fast

  xpos = 0;
  ypos = 0;

  // Print a list of the available serial ports
  println("-----------------------");
  println("Available Serial Ports:");
  println("-----------------------");
  printArray(Serial.list());
  println("-----------------------");

  print("Port currently used: [");
  print(serial_port);
  println("]");

  String portName = Serial.list()[serial_port];

  delay(1000);

  serial = new Serial(this, portName, serial_baud_rate);

  noSmooth();      // Turn off anti-aliasing to avoid adjacent pixel merging

  state = 99;
}

void draw() {
  switch(state) {

  case 0: // Init varaibles, send start request
    tint(0, 0, 0, 255);
    flushBuffer();
    println("");
    print("Ready: ");

    xpos = 0;
    ypos = 0;
    serialCount = 0;
    progress_bar = 0;
    pixel_count = 0;
    percentage   = 0;
    drawLoopCount = frameCount;
    lastPixelTime = millis() + 1000;

    state = 1;
    break;

  case 1: // Console message, give server some time
    print("requesting image ");
    serial.write("S");
    delay(10);
    beginTime = millis() + 1000;
    state = 2;
    break;

  case 2: // Get size and set start time for render time report
    if (millis() > beginTime) {
      System.err.println(" - no response!");
      state = 0;
    }
    if ( getSize() == true ) {
      beginTime = millis();
      state = 3;
    }
    //noTint();
    break;

  case 3: // Request pixels and render returned RGB values
    state = renderPixels();
    // Request 32 more pixels
    serial.write("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR");
    break;

  case 4: // Time-out, flush serial buffer
    flushBuffer();
    state = 6;
    break;

  case 5: // Save the image to the sketch folder (Ctrl+K to access)
    saveScreenshot();
    drawLoopCount = frameCount; // Reset value ready for counting in step 6
    state = 6;
    break;

  case 6: // Fade the old image if enabled
    if ( fadedImage() == true ) state = 0;
    break;

  case 99: // Draw image viewer window
    drawWindow();
    state = 0;
    break;

  default:
    println("");
    System.err.println("Error state reached - check sketch!");
    break;
  }
}

void drawWindow()
{
  // Graded background in Arduino colours
  for (int i = 0; i < height - 25; i++) {
    float inter = map(i, 0, height - 25, 0, 1);
    color c = lerpColor(bgcolor1, bgcolor2, inter);
    stroke(c);
    line(0, i, 500, i);
  }
  fill(bgcolor2);
  rect( 0, height-25, width-1, 24);
  textAlign(CENTER);
  textSize(20);
  fill(0);
  text("Bodmer's TFT image viewer", width/2, height-6);
}

void flushBuffer()
{
  println();
  //println("Clearing serial pipe after a time-out");
  int clearTime = millis() + 50;
  while ( millis() < clearTime ) 
  {
    serial.read();
  }
}

boolean getSize()
{
  if ( serial.available() > 6 ) {
    println();
    char code = (char)serial.read();
    if (code == 'W') {
      tft_width = serial.read()<<8 | serial.read();
    }
    code = (char)serial.read();
    if (code == 'H') {
      tft_height = serial.read()<<8 | serial.read();
    }
    code = (char)serial.read();
    if (code == 'Y') {
      drawWindow();

      x_offset = (500 - tft_width) /2;
      tint(0, 0, 0, 255);
      noStroke();
      fill(frameColor);
      rect((width - tft_width)/2 - border, y_offset - border, tft_width + 2 * border, tft_height + 2 * border);
      return true;
    }
  }
  return false;
}

int renderPixels()
{
  if ( serial.available() > 0 ) {

    // Add the latest byte from the serial port to array:
    while (serial.available()>0)
    {
      rgb[serialCount++] = serial.read();

      // If we have 3 colour bytes:
      if ( serialCount >= color_bytes ) {
        serialCount = 0;
        pixel_count++;
        if (color_bytes == 3)
        {
          stroke(rgb[indexRed], rgb[indexGreen], rgb[indexBlue], 1000);
        } else
        {
          //stroke( (rgb[1] & 0x1F)<<3, (rgb[1] & 0xE0)>>3 | (rgb[0] & 0x07)<<5, (rgb[0] & 0xF8));
          stroke( (rgb[1] & 0xF8), (rgb[0] & 0xE0)>>3 | (rgb[1] & 0x07)<<5, (rgb[0] & 0x1F)<<3);
        }
        // We get some pixel merge aliasing if smooth() is defined, so draw pixel twice
        point(xpos + x_offset, ypos + y_offset);
        //point(xpos + x_offset, ypos + y_offset);

        lastPixelTime = millis();
        xpos++;
        if (xpos >= tft_width) {
          xpos = 0; 
          progressBar();
          ypos++;
          if (ypos>=tft_height) {
            ypos = 0;
            if ((int)percentage <100) {
              percent(100);
              println(" [ " + 100 + "% ]");
            }
            println("Image fetch time = " + (millis()-beginTime)/1000.0 + " s");
            return 5;
          }
        }
      }
    }
  } else
  {
    if (millis() > (lastPixelTime + pixelWaitTime))
    {
      println("");
      System.err.println("No response, trying again...");
      return 4;
    }
  }
  return 3;
}

void progressBar()
{
  progress_bar++;
  print(".");
  if (progress_bar >31)
  {
    progress_bar = 0;
    percentage = 0.5 + 100 * pixel_count/(0.001 + tft_width * tft_height);
    percent(percentage);
  }
}

void percent(float percentage)
{
  if (percentage > 100) percentage = 100;
  println(" [ " + (int)percentage + "% ]");
  textAlign(LEFT);
  textSize(16);
  noStroke();
  fill(bgcolor2);
  rect(10, height - 25, 70, 20);
  fill(0);
  text(" [ " + (int)percentage + "% ]", 10, height-8);
}

void saveScreenshot()
{
  println();
  String filename = "tft_screen_" + n  + image_type;
  println("Saving image as \"" + filename);
  if (save_border)
  {
    PImage partialSave = get(x_offset - border, y_offset - border, tft_width + 2*border, tft_height + 2*border);
    partialSave.save(filename);
  } else {
    PImage partialSave = get(x_offset, y_offset, tft_width, tft_height);
    partialSave.save(filename);
  }

  n = n + 1;
  if (n>=max_images) n = 0;
}

boolean fadedImage()
{
  int opacity = frameCount - drawLoopCount;  // So we get increasing fade
  if (fade)
  {
    tint(255, opacity);
    //image(tft_img, x_offset, y_offset);
    noStroke();
    fill(50, 50, 50, opacity);
    rect( (width - tft_width)/2, y_offset, tft_width, tft_height);
    delay(10);
  }
  if (opacity > 50)       // End fade after 50 cycles
  {
    return true;
  }
  return false;
}