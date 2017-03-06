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

int bgcolor = 255;			// Background color

PImage bg_img;

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

  // Graded background image
  bg_img = createImage(500, 540, ARGB);
  for (int i = 0; i < bg_img.pixels.length; i++) {
    float a = map(i, 0, bg_img.pixels.length, 255, 0);
    bg_img.pixels[i] = color(0, 100, 104, a);
  }


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

  fill(0);
  text("Bodmer's TFT image viewer", width/2, height-10);

  noSmooth();      // Turn off anti-aliasing to avoid adjacent pixel merging

  state = 99;
}

void draw() {
  drawLoopCount++;
  switch(state) {

  case 0: // Init varaibles, send start request
    tint(0, 0, 0, 255);
    println("");
    //println("Clearing pipe...");
    beginTime = millis() + 200;
    while ( millis() < beginTime ) 
    {
      serial.read();
    }
    print("Ready: ");

    xpos = 0;
    ypos = 0;
    serialCount = 0;
    progress_bar = 0;
    pixel_count = 0;
    percentage   = 0;
    drawLoopCount = 0;
    lastPixelTime = millis() + 1000;
    state = 1;
    break;

  case 1: // Console message, give server some time
    print("requesting image size ");
    serial.write("S");
    delay(10);
    beginTime = millis() + 1000;
    state = 2;
    break;

  case 2: // Get size and set start time for render time report
    // To do: Read image size info, currently hard coded
    if (millis() > beginTime) {
      System.err.println(" - no response!");
      state = 0;
    }
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
        textAlign(CENTER);
        textSize(20);
        background(bgcolor);
        image(bg_img, 0, 0);

        fill(0);
        text("Bodmer's TFT image viewer", width/2, height-10);

        x_offset = (500 - tft_width) /2;
        tint(0, 0, 0, 255);
        noStroke();
        fill(50);
        rect((width - tft_width)/2 - border, y_offset - border, tft_width + 2 * border, tft_height + 2 * border);
        //fill(50);
        //rect( (width - tft_width)/2, y_offset, tft_width-1, tft_height-1);

        beginTime = millis();
        state = 3;
      }
    }

    noTint();
    break;

  case 3: // Request pixels and render returned RGB values

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
            print(".");
            progress_bar++;
            if (progress_bar >31)
            {
              progress_bar = 0;
              percentage = 0.5 + 100 * pixel_count/(0.001 + tft_width * tft_height);
              if (percentage > 100) percentage = 100;
              println(" [ " + (int)percentage + "% ]");
              textAlign(LEFT);
              textSize(16);
              noStroke();
              fill(255);
              rect(10, height - 28, 70, 20);
              fill(0);
              text(" [ " + (int)percentage + "% ]", 10, height-12);
            }
            ypos++;
            if (ypos>=tft_height) { 
              ypos = 0;
              noStroke();
              fill(255);
              rect(10, height - 28, 70, 20);
              fill(0);
              text(" [ " + 100 + "% ]", 10, height-12);
              if ((int)percentage <100) println(" [ " + 100 + "% ]");
              println("Image fetch time = " + (millis()-beginTime)/1000.0 + " s");
              state = 5;
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
        state = 4;
      }
    }
    // Request 32pixels
    serial.write("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR");
    break;

  case 4: // Time-out, flush serial buffer
    println();
    //println("Clearing serial pipe after a time-out");
    int clearTime = millis() + 50;
    while ( millis() < clearTime ) 
    {
      serial.read();
    }
    state = 6;
    break;

  case 5: // Save the image to the sketch folder (Ctrl+K to access)
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
    drawLoopCount = 0; // Reset value ready for counting in step 6
    state = 6;
    break;

  case 6: // Fade the old image if enabled
    int opacity = drawLoopCount;  // So we get increasing fade
    if (drawLoopCount > 50)       // End fade after 50 cycles
    {
      opacity = 255;
      state = 0;
    }
    delay(10);
    if (fade)
    {
      tint(255, opacity);
      //image(tft_img, x_offset, y_offset);
      noStroke();
      fill(50, 50, 50, opacity);
      rect( (width - tft_width)/2, y_offset, tft_width, tft_height);
    }

    break;

  case 99: // Draw image viewer window
    textAlign(CENTER);
    textSize(20);
    background(bgcolor);
    image(bg_img, 0, 0);

    fill(0);

    text("Bodmer's TFT image viewer", width/2, height-10);

    state = 0;
    break;

  default:
    println("");
    System.err.println("Error state reached - check sketch!");
    break;
  }
}