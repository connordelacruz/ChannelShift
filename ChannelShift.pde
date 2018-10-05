/**
 * ChannelShift.pde
 *
 * Randomly shift and swap color channels in an image.
 * 
 * After running the sketch: 
 *    Press SPACEBAR to save result and run again
 *    Press X to discard result and run again
 *    Click the left mouse button to save result and quit
 *    Press ESC to discard result and quit
 *
 * Based on: 
 *   http://datamoshing.com/2016/06/16/how-to-glitch-images-using-processing-scripts/
 * 
 * @author Connor de la Cruz
 */

// CONSTANTS (DO NOT MODIFY)
// Shift Types
static final int NORMAL_SHIFT = 0;


// ================================================================
// CONFIG START
// ================================================================

//  FILE SETUP
// --------------------------------

// File path (relative to script directory)
String imgDir = "source/";
// File name
String imgFileName = "test";
// File extension
String fileType = "jpg";

// Output folder (relative to script directory)
String outputDir = imgDir + imgFileName + "/";
// If true, add a suffix to the output filename with details on the sketch config
boolean verboseFilename = true;


//  SKETCH CONFIGURATIONS
// --------------------------------

// TODO: document
int shiftType = NORMAL_SHIFT;
// repeat the process this many times
int iterations = 3;
// swap channels at random if true, just shift if false
boolean swapChannels = true;
// Max percent of image size to shift channels by. Lower numbers for less drastic effects
float shiftThreshold = 1.0;
// use result image as new source for iterations
boolean recursiveIterations = true;
// shift the image vertically true/false
boolean shiftVertically = false;
// shift the image horizontally true/false
boolean shiftHorizontally = !shiftVertically;

//  MISC
// --------------------------------

// Viewing window size (regardless of image size)
int maxDisplaySize = 800;

// ================================================================
// CONFIG END
// ================================================================


PImage sourceImg;
PImage targetImg;

int maxDisplayWidth;
int maxDisplayHeight;

int horizontalShift;
int verticalShift;

boolean glitchComplete = false;
boolean glitchSaved = false;
boolean glitchCompleteMsg = false;


String INDENT = "   ";

void setup() {
  // load images into PImage variables
  targetImg = loadImage(imgDir + imgFileName+"."+fileType);
  sourceImg = loadImage(imgDir + imgFileName+"."+fileType);

  glitchComplete = false;
  glitchSaved = false;
  glitchCompleteMsg = false; 

  // use only numbers (not variables) for the size() command, Processing 3
  size(1, 1);

  // allow resize 
  surface.setResizable(true);
  // calculate window size
  float ratio = (float)targetImg.width/(float)targetImg.height;
  if(ratio < 1.0) {
    maxDisplayWidth = (int)(maxDisplaySize * ratio);
    maxDisplayHeight = maxDisplaySize;
  } else {
    maxDisplayWidth = maxDisplaySize;
    maxDisplayHeight = (int)(maxDisplaySize / ratio);
  }
  surface.setSize(maxDisplayWidth, maxDisplayHeight);
  // load image onto surface
  image(sourceImg, 0, 0, maxDisplayWidth, maxDisplayHeight);
}


void draw() { 
  if (!glitchComplete) {
    processImage();
    // load updated image onto surface
    image(targetImg, 0, 0, maxDisplayWidth, maxDisplayHeight);
  } 
  else if (!glitchCompleteMsg) {
    printGlitchCompleteMsg();
  }
}


void processImage() {
  // load pixels
  sourceImg.loadPixels();
  targetImg.loadPixels();

  // repeat the process according to the iterations variable
  for(int i = 0; i < iterations; i++) {
    // generate random numbers for which channels to shift
    int sourceChannel = int(random(3));
    // pick a random channel to swap with if swapChannels
    int targetChannel = swapChannels ? int(random(3)) : sourceChannel;

    // Set horizontal and vertical shift values
    horizontalShift = shiftHorizontally ? 
      int(random(targetImg.width * shiftThreshold)) : 0;
    verticalShift = shiftVertically ? 
      int(random(targetImg.height * shiftThreshold)) : 0;

    // shift the channel
    copyChannel(sourceImg.pixels, targetImg.pixels, verticalShift, horizontalShift, sourceChannel, targetChannel);

    // use the target as the new source for the next iteration
    if(recursiveIterations)
      sourceImg.pixels = targetImg.pixels;
  }

  // update the target pixels
  targetImg.updatePixels();

  glitchComplete = true;
}


/**
 * Generate output file name and save result
 */
void saveResult() {
  println("Saving result...");
  // Append suffix with unique identifier
  String outputSuffix = hex((int)random(0xffff),4);

  // Append config details if verboseFilename is set
  if (verboseFilename) { 
    outputSuffix += "_" + iterations + "it";
    if (swapChannels)
      outputSuffix += "-swap";
    if (recursiveIterations)
      outputSuffix += "-recursive";
    if (shiftVertically)
      outputSuffix += "-vert" + verticalShift;
    if (shiftHorizontally)
      outputSuffix += "-hori" + horizontalShift;
  }
  // save surface
  String outputFile = outputDir + imgFileName + outputSuffix + ".png";
  targetImg.save(outputFile);
  glitchSaved = true;
  println("Result saved:");
  println(INDENT + outputFile);
  println("");
}

/**
 * Print "glitch complete" message to console
 */
void printGlitchCompleteMsg() { 
  println("GLITCH COMPLETE.");
  println(INDENT + "SPACEBAR: Save result and run again");
  println(INDENT + "X: Discard result and run again");
  println(INDENT + "CLICK: Save result and quit");
  println(INDENT + "ESC: Discard result and quit");
  println("");
  glitchCompleteMsg = true;
}

void keyPressed() {
  // TODO: check glitchComplete is true
  switch (key) {
    // Re-run sketch
    case ' ':
      if (!glitchSaved) {
        saveResult();
      }
    case 'x':
    case 'X':
      println("Re-running sketch...");
      setup();
      draw();
      break;
    case ESC:
      System.exit(0);
      break;
    default:
      break;
  }
}

void mouseClicked() {
  if (glitchComplete) {
    if (!glitchSaved)
      saveResult();
    System.exit(0);
  }
}


/* Shift Functions */

/**
 * Shift the channel
 * @param sourcePixels Pixels from the source image
 * @param targetPixels Pixels from the target image
 * @param sourceY Vertical shift amount
 * @param sourceX Horizontal shift amount
 * @param sourceChannel Channel from the source image
 * @param targetChannel Channel from the target image
 */
void copyChannel(color[] sourcePixels, color[] targetPixels, int sourceY, int sourceX, int sourceChannel, int targetChannel)
{
  // starting at the sourceY and pointerY loop through the rows
  for(int y = 0; y < targetImg.height; y++) {   
    // Calculate y offset
    int sourceYOffset = calculateOffset(sourceY, y, targetImg.height);

    // starting at the sourceX and pointerX loop through the pixels in this row
    for(int x = 0; x < targetImg.width; x++) {
      // Calculate x offset
      int sourceXOffset = calculateOffset(sourceX, x, targetImg.width);

      // get the color of the source pixel
      color sourcePixel = sourcePixels[sourceYOffset * targetImg.width + sourceXOffset];

      // get the RGB values of the source pixel
      float sourceRed = red(sourcePixel);
      float sourceGreen = green(sourcePixel);
      float sourceBlue = blue(sourcePixel);

      // get the color of the target pixel
      color targetPixel = targetPixels[y * targetImg.width + x]; 

      // get the RGB of the target pixel
      // two of the RGB channel values are required to create the new target color
      // the new target color is two of the target RGB channel values and one RGB channel value from the source
      float targetRed = red(targetPixel);
      float targetGreen = green(targetPixel);
      float targetBlue = blue(targetPixel);

      // create a variable to hold the new source RGB channel value
      float sourceChannelValue = 0;

      // assigned the source channel value based on sourceChannel random number passed in
      switch(sourceChannel)
      {
        case 0:
          // use red channel from source
          sourceChannelValue = sourceRed;
          break;
        case 1:
          // use green channel from source
          sourceChannelValue = sourceGreen;
          break;
        case 2:
          // use blue channel from source
          sourceChannelValue = sourceBlue;
          break;
      }

      // assigned the source channel value to a target channel based on targetChannel random number passed in
      switch(targetChannel)
      {
        case 0:
          // assign source channel value to target red channel
          targetPixels[y * targetImg.width + x] =  color(sourceChannelValue, targetGreen, targetBlue);
          break;
        case 1:
          // assign source channel value to target green channel
          targetPixels[y * targetImg.width + x] =  color(targetRed, sourceChannelValue, targetBlue);
          break;
        case 2:
          // assign source channel value to target blue channel
          targetPixels[y * targetImg.width + x] =  color(targetRed, targetGreen, sourceChannelValue);
          break;
      }

    }
  }
}


// TODO: doc
int calculateOffset(int shiftAmount, int coordinate, int imgDimension) {
  // TODO: account for different shift types
  int offset = shiftAmount + coordinate;
  // Wrap around if offset is greater than the image dimension
  if (offset >= imgDimension)
    offset -= imgDimension;
  return offset;
}



