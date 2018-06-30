/**
 * ChannelShift Glitch
 * Based on: 
 *   http://datamoshing.com/2016/06/16/how-to-glitch-images-using-processing-scripts/
 * 
 * @author Connor de la Cruz
 */


///// FILE SETUP

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


///// SKETCH CONFIGURATIONS

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

///// MISC

// Viewing window size (regardless of image size)
int maxDisplaySize = 800;

// (FOR TESTING) If true, don't save the file and just display it
boolean discardResult = false;

///// END


PImage sourceImg;
PImage targetImg;

int maxDisplayWidth;
int maxDisplayHeight;

int horizontalShift;
int verticalShift;

boolean glitchComplete = false;
boolean glitchSaved = false;


void setup() {
  // load images into PImage variables
  targetImg = loadImage(imgDir + imgFileName+"."+fileType);
  sourceImg = loadImage(imgDir + imgFileName+"."+fileType);

  // Set to 0 by default, assigned a random value if the corresponding boolean is true
  horizontalShift = 0;
  verticalShift = 0;
  
  glitchComplete = false;
  glitchSaved = false;

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

  background(#ffffff);
  // load image onto surface
  image(sourceImg, 0, 0, maxDisplayWidth, maxDisplayHeight);
}


void draw() { 

  if (!glitchComplete) {
    processImage();

    // load updated image onto surface
    image(targetImg, 0, 0, maxDisplayWidth, maxDisplayHeight);
  }

  // Save file
  if (glitchComplete && !glitchSaved) {
    if (!discardResult) {
      saveResult();
      println("Glitched image saved");
    }
    // If discardResult, set glitchSaved = true to avoid repeating console output
    else {
      glitchSaved = true;
    }
    println("Press spacebar to run sketch again");
    println("Click or press any other key to exit...");
  }
}


void processImage() {
  // load pixels
  sourceImg.loadPixels();
  targetImg.loadPixels();

  // repeat the process according to the iterations variable
  for(int i = 0; i < iterations; i++)
  {
    // generate random numbers for which channels to shift
    int sourceChannel = int(random(3));
    // pick a random channel to swap with if swapChannels
    int targetChannel = swapChannels ? int(random(3)) : sourceChannel;


    // if shiftHorizontally is true, generate a random number to shift horizontally by
    if(shiftHorizontally)
      horizontalShift = int(random(targetImg.width * shiftThreshold));

    // if shiftVertically is true, generate a random number to shift vertically by
    if(shiftVertically)
      verticalShift = int(random(targetImg.height * shiftThreshold));

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
  targetImg.save(outputDir + imgFileName + outputSuffix + ".png");
  glitchSaved = true;
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

void keyPressed() {
  if (key == ' ' && glitchSaved) {
    println("Re-running sketch...");
    setup();
    draw();
  }
  else {
    System.exit(0);
  }
}

void mouseClicked() {
  if (glitchSaved)
  {
    System.exit(0);
  }
}
