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


// --------------------------------
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


// --------------------------------
//  SKETCH CONFIGURATIONS
// --------------------------------

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

// --------------------------------
// SKETCH MODE
// --------------------------------
// TODO: doc
boolean manualMode = false;

// --------------------------------
//  MISC
// --------------------------------

// Viewing window size (regardless of image size)
int maxDisplaySize = 800;


///// END


PImage sourceImg;
PImage targetImg;

int maxDisplayWidth;
int maxDisplayHeight;

int horizontalShift;
int verticalShift;

boolean glitchComplete = false;
boolean glitchSaved = false;
boolean glitchCompleteMsg = false;


// CONSTANTS

// Indent string used in console output
public static final String INDENT = "   ";

// int representations of channels
public static final int CHANNEL_R = 0;
public static final int CHANNEL_G = 1;
public static final int CHANNEL_B = 2;


// CLASSES
// TODO: probably make more of these

public class RandomModeManager {
  // TODO: move random draw stuff here

  // METHODS

  // TODO: doc, extract all to functions so this just handles keys regardless of implementation
  // TODO: return something so we know what's going on when calling?
  public void keyHandler(char k) {
    // TODO: add 'm'/'M' case (switch to manual mode)
    // TODO: check glitchComplete is true
    switch (k) {
      // Re-run sketch
      case ' ':
        boolean saved = attemptSaveResult();
        if (!saved)
          break;
      case 'x':
      case 'X':
        restartSketch();
        break;
      case ESC:
        System.exit(0);
        break;
      default:
        break;
    }
  }
}

// TODO: doc
public class ManualModeManager {
  // CONSTANTS

  // Select - Choose an action
  public static final int MODE_SELECT = 0;
  // Swap - Switch the current channel with another
  public static final int MODE_SWAP = 1;
  // Horizontal Shift - Move current channel along x-axis
  public static final int MODE_H_SHIFT = 2;
  // Vertical Shift - Move current channel along y-axis
  public static final int MODE_V_SHIFT = 3;
  // Free Shift - Move current channel along either axis
  public static final int MODE_FREE_SHIFT = 4;

  // ATTRIBUTES

  // Currently selected channel
  int currentChannel;
  // Current action
  int currentAction;

  // METHODS

  public ManualModeManager() {
    currentChannel = CHANNEL_R;
    currentAction = MODE_SELECT;
  }

  // TODO: handle actions

}


// DRAWING

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
  for(int y = 0; y < targetImg.height; y++)
  {   
    // add y counter to sourceY
    int sourceYOffset = sourceY + y;

    // wrap around the top of the image if we've hit the bottom
    if(sourceYOffset >= targetImg.height)
      sourceYOffset -= targetImg.height;

    // starting at the sourceX and pointerX loop through the pixels in this row
    for(int x = 0; x < targetImg.width; x++)
    {
      // add x counter to sourceX
      int sourceXOffset = sourceX + x;

      // wrap around the left side of the image if we've hit the right side
      if(sourceXOffset >= targetImg.width)
        sourceXOffset -= targetImg.width;

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
        case CHANNEL_R:
          // use red channel from source
          sourceChannelValue = sourceRed;
          break;
        case CHANNEL_G:
          // use green channel from source
          sourceChannelValue = sourceGreen;
          break;
        case CHANNEL_B:
          // use blue channel from source
          sourceChannelValue = sourceBlue;
          break;
      }

      // assigned the source channel value to a target channel based on targetChannel random number passed in
      switch(targetChannel)
      {
        case CHANNEL_R:
          // assign source channel value to target red channel
          targetPixels[y * targetImg.width + x] =  color(sourceChannelValue, targetGreen, targetBlue);
          break;
        case CHANNEL_G:
          // assign source channel value to target green channel
          targetPixels[y * targetImg.width + x] =  color(targetRed, sourceChannelValue, targetBlue);
          break;
        case CHANNEL_B:
          // assign source channel value to target blue channel
          targetPixels[y * targetImg.width + x] =  color(targetRed, targetGreen, sourceChannelValue);
          break;
      }

    }
  }
}


// SAVING

// TODO: doc
// TODO: use random seed for filename so you can reproduce results?
String getOutputFilePath() {
  // Append suffix with unique identifier
  // TODO: make this configurable (suffix length, optional)
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
  return outputDir + imgFileName + outputSuffix + ".png";
}

/**
 * Generate output file name and save result
 */
void saveResult() {
  println("Saving result...");
  // save surface
  String outputFile = getOutputFilePath();
  targetImg.save(outputFile);
  glitchSaved = true;
  println("Result saved:");
  println(INDENT + outputFile);
  println("");
}

// TODO: doc
boolean attemptSaveResult() {
  if (!glitchSaved) {
    saveResult();
  }
  return glitchSaved;
} 


// OUTPUT

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


// INPUT

// Handlers

// TODO: doc, extract all to functions so this just handles keys regardless of implementation
void randomModeKeyHandler(char k) {
  // TODO: add 'm'/'M' case (switch to manual mode)
  // TODO: check glitchComplete is true
  switch (k) {
    // Re-run sketch
    case ' ':
      boolean saved = attemptSaveResult();
      if (!saved)
        break;
    case 'x':
    case 'X':
      restartSketch();
      break;
    case ESC:
      System.exit(0);
      break;
    default:
      break;
  }
}

void manualModeKeyHandler(char k) {
  switch(k) {
    case ESC:
      System.exit(0);
      break;
    default:
      break;
  }
}


// Processing

void keyPressed() {
  randomModeKeyHandler(key);
}

// TODO: extract to randomModeClickHandler
void mouseClicked() {
  if (glitchComplete) {
    boolean saved = attemptSaveResult();
    if (saved)
      System.exit(0);
  }
}


// UTILITIES

void restartSketch() {
  println("Re-running sketch...");
  setup();
  draw();
}


// TODO: document both
void toggleMode() {
  toggleMode(!manualMode);
}

void toggleMode(boolean enable) {
  manualMode = enable;
  // TODO: better output
  String msg = manualMode ? "Manual Mode" : "Random Mode";
  println(msg);
  println("");
}

