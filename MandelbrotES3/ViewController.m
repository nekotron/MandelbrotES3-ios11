//
//  ViewController.m
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//
//For the most part this is just a customized version of the boilerplate opengl es game code.

//Remove this to have debug output upon openglES problems
//#ifdef DEBUG
//  #undef DEBUG
//#endif

#import "ViewController.h"
#import <sys/time.h>

#import <Availability.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/ES2/glext.h>


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#define INVERT   0
#define SWAPRB   1
#define SWAPRG   2
#define ORIGINAL 3
#define RETURN   4

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

typedef struct {
  float Position[3];
  float Color[4];
  float Normal[3];
  float TexCoord[2];
} Vertex;

Vertex testVert[] =
{
  //Position             Color(notused) Normal                Texture
  {{ 0.9f, -1.0f, 0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {1 ,0}}, //<
  {{ 0.9f, 1.0f,  0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {1 ,1}},
  {{-0.9f, -1.0f, 0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {0 ,0}},
  {{-0.9f, -1.0f, 0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {0 ,0}},
  {{-0.9f, 1.0f,  0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {0 ,1}},
  {{ 0.9f, 1.0f,  0.125f},  {1,1,1,1},   {0.0f, 0.0f, 1.0f}, {1 ,1}}
};

const GLubyte Indices[]=
{
  0, 1, 2,
  3, 4, 5
};

GLfloat twoPolygons[] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ
   -1.0f, -1.0f,  0.0f,
    1.0f, -1.0f,  0.0f,
   -1.0f,  1.0f,  0.0f,
   -1.0f,  1.0f,  0.0f,
    1.0f,  1.0f,  0.0f,
    1.0f, -1.0f,  0.0f
};

@interface ViewController ()
{
  GLuint _programM;
  GLuint _programJ;
  GLuint _programC;
  
  GLKMatrix4 _modelViewProjectionMatrix;
  GLKMatrix3 _normalMatrix;
  float _rotation;
  
  GLuint _vertexArray;
  GLuint _vertexBuffer;
  
  GLuint _faceTexture;
  GLuint _textureUniform;
  
  
  GLfloat _moveParams;
  
  //Pans in mandlebrot, changes julia's C
  float initialX;
  float initialY;
  
  //Pans in julia, not used in mandlebrot
  float juliaX;
  float juliaY;
  
  float beginningScaleFactor;
  float scaleFactor;
  float juliaScaleFactor;
  
  BOOL useMandlebrot;
  BOOL useJulia;
  BOOL seenJulia;
  
  BOOL changingProgram;
  
  GLubyte * mandlebrotTexture;
  GLubyte * juliaTexture;
  GLubyte * rearrangeBuffer;
  
  BOOL flippyFloppy;
  
  CGFloat screenScale;
  CGFloat screenScaleSquared;
  
  float tapY;
  BOOL saveMandlebrot;
  
  float aspect;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShadersMandlebrot;
- (BOOL)loadShadersJulia;
- (BOOL)loadShadersCube;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
- (UIImage *) glToUIImageWithPixelBuffer: (GLubyte *) pBuffer andScaledWidth: (int) scWidth andScaledHeight: (int) scHeight withFlag: (int) flag;
@end

@implementation ViewController

#pragma mark Picture Conversion
//original at www.bit-101.com/blog/?p=1861 but was modified to perform the different inversions

// callback for CGDataProviderCreateWithData
void releaseData(void *info, const void *data, size_t dataSize)
{
  NSLog(@"releaseData\n");
  free((void*)data);	 // free the
}

-(UIImage *) glToUIImageWithPixelBuffer: (GLubyte *) pBuffer andScaledWidth: (int) scWidth andScaledHeight: (int) scHeight withFlag: (int) flag
{
  
  
  NSInteger myDataLength = scWidth * scHeight * 4;
  
  // allocate array and read pixels into it.
  //GLubyte *buffer = (GLubyte *) malloc(myDataLength);
  //glReadPixels(0, 0, 320, 480, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
  
  
  
  // gl renders "upside down" so swap top to bottom into new array.
  // there's gotta be a better way, but this works.
  //rearrangeBuffer = (GLubyte *) malloc(myDataLength);
  
  --scHeight;
  --scWidth;
  if (flag == ORIGINAL)
    for(int y = 0; y < scHeight; y++)
    {
      for(int x = 0; x < (scWidth ) * 4; x+=4)
      {
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+0)] = pBuffer[y * 4 * (scWidth ) + (x+0)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+1)] = pBuffer[y * 4 * (scWidth ) + (x+1)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+2)] = pBuffer[y * 4 * (scWidth ) + (x+2)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+3)] = pBuffer[y * 4 * (scWidth ) + (x+3)];
      }
    }
  
  
  
  if (flag == INVERT)
  {
    for(int y = 0; y < scHeight; y++)
    {
      for(int x = 0; x < (scWidth ) * 4; x+=4)
      {
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+0)] = 255-pBuffer[y * 4 * (scWidth ) + (x+0)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+1)] = 255-pBuffer[y * 4 * (scWidth ) + (x+1)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+2)] = 255-pBuffer[y * 4 * (scWidth ) + (x+2)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+3)] = pBuffer[y * 4 * (scWidth ) + (x+3)];
      }
    }
  }
  
  
  if (flag == SWAPRB)
  {
    for(int y = 0; y < scHeight; y++)
    {
      for(int x = 0; x < (scWidth ) * 4; x+=4)
      {
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+0)] = pBuffer[y * 4 * (scWidth ) + (x+2)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+1)] = pBuffer[y * 4 * (scWidth ) + (x+1)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+2)] = pBuffer[y * 4 * (scWidth ) + (x+0)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+3)] = pBuffer[y * 4 * (scWidth ) + (x+3)];
      }
    }
  }
  
  if (flag == SWAPRG)
  {
    for(int y = 0; y < scHeight; y++)
    {
      for(int x = 0; x < (scWidth ) * 4; x+=4)
      {
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+0)] = pBuffer[y * 4 * (scWidth ) + (x+1)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+1)] = pBuffer[y * 4 * (scWidth ) + (x+0)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+2)] = pBuffer[y * 4 * (scWidth ) + (x+2)];
        rearrangeBuffer[((scHeight - 1) - y) * (scWidth  ) * 4 + (x+3)] = pBuffer[y * 4 * (scWidth ) + (x+3)];
      }
    }
  }
  
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rearrangeBuffer, myDataLength, releaseData);
  int bitsPerComponent = 8;
  int bitsPerPixel = 32;
  int bytesPerRow = 4 * scWidth;
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
  CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
  CGImageRef imageRef = CGImageCreate(scWidth-1, scHeight-1, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
  
  CGColorSpaceRelease(colorSpaceRef);	 // YOU CAN RELEASE THIS NOW
  CGDataProviderRelease(provider);	 // YOU CAN RELEASE THIS NOW
  
  UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];	// change this to manual alloc/init instead of autorelease

  return image;
}


#pragma mark - UIStuff
- (void)pinchy:(UIPinchGestureRecognizer *)recognizer
{
  
  if([recognizer state] == UIGestureRecognizerStateBegan)
  {
    //NSLog(@"PINCH START!");
    if (useMandlebrot)
      beginningScaleFactor = scaleFactor;
    else if (useJulia)
      beginningScaleFactor = juliaScaleFactor;
  }

  //NSLog(@"Pinch scale: %f", recognizer.scale);
  if (useMandlebrot)
    scaleFactor = 1/(sqrtf(recognizer.scale))*beginningScaleFactor;
  else if (useJulia)
    juliaScaleFactor = 1/(sqrtf(recognizer.scale))*beginningScaleFactor;
  
  if([recognizer state] == UIGestureRecognizerStateEnded)
  {
    //NSLog(@"PINCH OVER!");
    if (useMandlebrot)
      scaleFactor = 1/(sqrtf(recognizer.scale))*beginningScaleFactor;
    else if (useJulia)
      juliaScaleFactor = 1/(sqrtf(recognizer.scale))*beginningScaleFactor;
  }
}

-(void)mrResetti
{
  if (useMandlebrot)
  {
    initialX = initialY = 0;
    scaleFactor = 1.0;
  }
  else if (useJulia)
  {
    juliaX = juliaY = 0;
    juliaScaleFactor = 1.0;
  }
}

//Action sheet taken from www.makemegeek.com/uiactionsheet-example-ios/
-(void)saveMenu:(UILongPressGestureRecognizer *)recognizer
{
  if (!(useMandlebrot||useJulia)&&(recognizer.state==UIGestureRecognizerStateBegan))
  {
    CGPoint point = [recognizer locationInView:self.view];
    
    tapY   = point.y;
    float height = self.view.frame.size.height;
    float width  = self.view.frame.size.width;
    
    UIActionSheet *saveSheet;
    
    float threshold;
    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation))
    {
      threshold = height/2;
    }
    else
    {
      threshold = width/2;
    }
    
    
    if (tapY > threshold)
    {
      saveMandlebrot = NO;
      saveSheet = [[UIActionSheet alloc] initWithTitle:@"Save julia with inversion type" delegate:self cancelButtonTitle:@"Cancel"  destructiveButtonTitle:nil otherButtonTitles: @"{R',G',B'}={1-R,1-G,1-B}", @"{R',G',B'}={B,G,R}", @"{R',G',B'}={G,R,B}", @"No Inversion", nil];
    }
    else
    {
      saveMandlebrot = YES;
      saveSheet = [[UIActionSheet alloc] initWithTitle:@"Save mandlebrot with inversion type" delegate:self cancelButtonTitle:@"Cancel"  destructiveButtonTitle:nil otherButtonTitles: @"{R',G',B'}={1-R,1-G,1-B}", @"{R',G',B'}={B,G,R}", @"{R',G',B'}={G,R,B}", @"No Inversion", nil];
    }
    
    saveSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [saveSheet showInView:self.view];
  }
}


//Action sheet taken from www.makemegeek.com/uiactionsheet-example-ios/
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
  
  
  
  float scaledHeight;
  float scaledWidth;
  
  if (UIDeviceOrientationIsPortrait(self.interfaceOrientation))
  {
  float width  = self.view.frame.size.width;
  float height = self.view.frame.size.height;
  scaledWidth  = width  * (int)screenScale;
  scaledHeight = height * (int)screenScale;
  }
  else
  {
    float width  = self.view.frame.size.height;
    float height = self.view.frame.size.width;
    scaledWidth  = width  * (int)screenScale;
    scaledHeight = height * (int)screenScale;
  }
  
  
  if(buttonIndex == 0)
  
  {
    
    if (saveMandlebrot)
    {
      //NSLog(@"{R',G',B'}={1-R,1-G,1-B} mandlebrot");
      UIImage *image = [self glToUIImageWithPixelBuffer:mandlebrotTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:INVERT];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
    else
    {
      //NSLog(@"{R',G',B'}={1-R,1-G,1-B} julia");
      UIImage *image = [self glToUIImageWithPixelBuffer:juliaTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:INVERT];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
  }
  
  else if(buttonIndex == 1)
  
  {
    
    if (saveMandlebrot)
    {
      //NSLog(@"{R',G',B'}={B,G,R} mandlebrot");
      UIImage *image = [self glToUIImageWithPixelBuffer:mandlebrotTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:SWAPRB];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
    else
    {
      //NSLog(@"{R',G',B'}={B,G,R} julia");
      UIImage *image = [self glToUIImageWithPixelBuffer:juliaTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:SWAPRB];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
  }

  else if(buttonIndex == 2)
  
  {
    
    if (saveMandlebrot)
    {
      //NSLog(@"{R',G',B'}={G,R,B} mandlebrot");
      UIImage *image = [self glToUIImageWithPixelBuffer:mandlebrotTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:SWAPRG];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
    else
    {
      //NSLog(@"{R',G',B'}={B,G,R} julia");
      UIImage *image = [self glToUIImageWithPixelBuffer:juliaTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:SWAPRG];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
  }
  
  
  else if(buttonIndex == 3)
  
  {
    if (saveMandlebrot)
    {
      //NSLog(@"No Inversion mandlebrot");
      UIImage *image = [self glToUIImageWithPixelBuffer:mandlebrotTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:ORIGINAL];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
    else
    {
      //NSLog(@"No Inversion julia");
      UIImage *image = [self glToUIImageWithPixelBuffer:juliaTexture andScaledWidth:scaledWidth andScaledHeight:scaledHeight withFlag:ORIGINAL];
      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
      NSLog(@"Saved the image!");
    }
  }
  else if(buttonIndex == 4)
  {
    //NSLog(@"Cancel Button Clicked");
  }
}

-(void)secondaryPan:(UIPanGestureRecognizer *)recognizer
{
  CGPoint speed = [recognizer velocityInView:[self view]];
  
  float width  = self.view.frame.size.width;
  float height = self.view.frame.size.height;
  
  if (useJulia)
  {
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]))
    {
    initialX-=(juliaScaleFactor)*(speed.x/width)/(5*width);
    initialY+=(juliaScaleFactor)*(speed.y/height)/(5*height)/aspect;
    }
    else
    {
      initialX-=(juliaScaleFactor)*(speed.x/width)/(3*width)/aspect;
      initialY+=(juliaScaleFactor)*(speed.y/height)/(3*height);
    }
  }
}


-(void)pan:(UIPanGestureRecognizer *)recognizer
{
  CGPoint speed = [recognizer velocityInView:[self view]];
  
  float width  = self.view.frame.size.width;
  float height = self.view.frame.size.height;
  
  if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]))
  {
  
    if (useMandlebrot)
    {
      initialX-=(scaleFactor)*(speed.x/width)/20;//*self.timeSinceLastUpdate;
      initialY+=(scaleFactor)*(speed.y/height)/20/aspect;//*self.timeSinceLastUpdate;//*aspect;
    }
    else if (useJulia)
    {
      juliaX-=(juliaScaleFactor)*(speed.x/width)/20;//aspect;
      juliaY+=(juliaScaleFactor)*(speed.y/height)/20/aspect;//*aspect;
    }
  }
  else
  {
  
    if (useMandlebrot)
    {
      initialX-=(scaleFactor)*(speed.x/width)/12/aspect;//*self.timeSinceLastUpdate*aspect;
      initialY+=(scaleFactor)*(speed.y/height)/12;///aspect;//*self.timeSinceLastUpdate/aspect;
    }
    else if (useJulia)
    {
      juliaX-=(juliaScaleFactor)*(speed.x/width)/12/aspect;//*self.timeSinceLastUpdate*aspect;
      juliaY+=(juliaScaleFactor)*(speed.y/height)/12; //*self.timeSinceLastUpdate/aspect;
    }
  }

}

-(void)changeSets:(UITapGestureRecognizer *)recognizer
{
//  struct timeval t0, t1;
//  gettimeofday(&t0, NULL);
//  gettimeofday(&t1, NULL);
  
  if (useMandlebrot ) //looking at mandlebrot
  {
    useMandlebrot = NO;             //Switch to julia
    useJulia = YES;
    changingProgram = YES;
  }
  else if(useJulia)  //looking at julia
  {
    useMandlebrot = NO;
    useJulia = NO;                  //Switch to cube
    changingProgram = YES;
  }
  else               //looking at cubes
  {

    useMandlebrot = YES;            //Swith to mandlebrot
    useJulia = NO;
  }
  
  if (!seenJulia && useJulia)
  {
    seenJulia = YES;
    
    //This alert slows down debugging.
   /* UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Julia Usage" message:@"This is the portion of a Julia set relating to the centerered portion of the Mandlebrot set.\nYou can two finger drag to move the Mandlebrot set in this view." delegate:nil
                          cancelButtonTitle:nil otherButtonTitles:@"Gotcha", nil];
    [alert show];*/
  }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
  
#ifdef DEBUG
  NSLog(@"DEBUG is defined, output of opengl compilation/linking issues will display");
#endif
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60; //If we want to modify the frame rate here is where to play with it.
  
  screenScale = [[UIScreen mainScreen] scale];
  screenScaleSquared = screenScale * screenScale;
  
  //UITapGestureRecognizer *oneFingerOneTap =
  //[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappa:)];
  //[[self view] addGestureRecognizer:oneFingerOneTap];
  
  UITapGestureRecognizer *oneFingerTwoTap =
  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeSets:)];
  [oneFingerTwoTap setNumberOfTapsRequired:2];
  [[self view] addGestureRecognizer:oneFingerTwoTap];
  
  UIPanGestureRecognizer *pan =
  [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  [pan setMinimumNumberOfTouches:1];
	[pan setMaximumNumberOfTouches:1];
  [[self view] addGestureRecognizer:pan];
  
  UIPanGestureRecognizer *secondaryPan =
  [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(secondaryPan:)];
  [secondaryPan setMinimumNumberOfTouches:2];
	[secondaryPan setMaximumNumberOfTouches:3];
  [[self view] addGestureRecognizer:secondaryPan];
  
  // attach long press gesture to collectionView
  UILongPressGestureRecognizer *lpgr
  = [[UILongPressGestureRecognizer alloc]
     initWithTarget:self action:@selector(saveMenu:)];
  lpgr.minimumPressDuration = .5; //seconds
  [[self view] addGestureRecognizer:lpgr];
  
  
  UITapGestureRecognizer * twoTapSalute = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mrResetti)];
  [twoTapSalute setNumberOfTouchesRequired:2];
  //[twoTapSalute setNumberOfTapsRequired:2];
  [[self view] addGestureRecognizer:twoTapSalute];
  
  UIPinchGestureRecognizer * pinchy = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchy:)];
   [[self view] addGestureRecognizer:pinchy];

  juliaX = juliaY = 0;
  initialX = initialY = 0;
  juliaScaleFactor = scaleFactor = 1.0;
  useMandlebrot = YES;
  useJulia = NO;
  seenJulia = NO;
  changingProgram = NO;
  
  
  flippyFloppy = YES;
  
  
  int width  = (int)self.view.frame.size.width;
  int height = (int)self.view.frame.size.height;

  //int bytesPerPixel = 12; //GL_FLOAT: GL_RGB:
  int bytesPerPixel = 4; //GL_UNSIGNED_BYTE GL_RGBA
  
  juliaTexture = ( GLubyte* ) malloc( width * height * bytesPerPixel * (int)(screenScaleSquared) * 2 );
  //glReadPixels ( 0, 0, windowWidth, windowHeight, GL_RGB, GL_FLOAT, pixels );
  mandlebrotTexture = ( GLubyte* ) malloc( width * height * bytesPerPixel * (int)(screenScaleSquared) );
  //glReadPixels ( 0, 0, windowWidth, windowHeight, GL_RGB, GL_FLOAT, pixels );
  rearrangeBuffer = ( GLubyte* ) malloc( width * height * bytesPerPixel * (int)(screenScaleSquared) );

  
  //UIAlertView *alert = [[UIAlertView alloc]
  //                      initWithTitle:@"Usage" message:@"One finger pan to move\nPinch to zoom\nTwo finger tap to reset\n Double tap for something different" delegate:nil
  //                      cancelButtonTitle:nil otherButtonTitles:@"Gotcha", nil];
  //[alert show];
  
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
  
  
  
    [self loadShadersMandlebrot];
    [self loadShadersJulia];
    [self loadShadersCube];
  
    //Remove or define to verify 3.0
    //When running on my phone it says "Version after compiling shaders: OpenGL ES 3.0 Apple A7 GPU - 27.23"
#ifdef DEBUG
    NSLog(@"Version after compiling shaders: %s", glGetString(GL_VERSION));
#endif
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
  
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(twoPolygons), twoPolygons, GL_STATIC_DRAW);
  
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, BUFFER_OFFSET(0));
  
  glGenTextures(1, &_faceTexture);
  glBindTexture(GL_TEXTURE_2D, _faceTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  
  _textureUniform = glGetUniformLocation(_programC, "Texture");
  
  glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_programM) {
        glDeleteProgram(_programM);
        _programM = 0;
    }

  if (_programJ) {
    glDeleteProgram(_programJ);
    _programJ = 0;
  }


}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  
  if (changingProgram)
  {
  int width  = (int)self.view.frame.size.width;
  int height = (int)self.view.frame.size.height;
  
   if (useJulia)
    {
    glReadPixels(0, 0, width*(int)screenScale-1, height*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, mandlebrotTexture);
      if (UIDeviceOrientationIsPortrait(self.interfaceOrientation))
      {
        glReadPixels(0, 0, width*(int)screenScale-1, height*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, mandlebrotTexture);
        glReadPixels(0, 0, width*(int)screenScale-1, height*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture+((width*(int)screenScale-1) * (height*(int)screenScale-1) * 4 ));
      }
      else
      {
        glReadPixels(0, 0, height*(int)screenScale-1, width*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, mandlebrotTexture);
        glReadPixels(0, 0, height*(int)screenScale-1, width*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture+((width*(int)screenScale-1) * (height*(int)screenScale-1) * 4 ));
      }

    }
    else if (!useMandlebrot)
    {
      if (UIDeviceOrientationIsPortrait(self.interfaceOrientation))
      {
        glReadPixels(0, 0, width*(int)screenScale-1, height*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture);
      }
      else
      {
        glReadPixels(0, 0, height*(int)screenScale-1, width*(int)screenScale-1, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture);
      }
    }
    changingProgram = NO;
  }
  
  glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
  //NSLog(@"Clearing buffer");
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  glBindVertexArrayOES(_vertexArray);
  
  
  // Render the object with ES3
  if (useMandlebrot)
  {
    glBufferData(GL_ARRAY_BUFFER, sizeof(twoPolygons), twoPolygons, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, BUFFER_OFFSET(0));

    aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    
    glUseProgram(_programM);
    glUniform1f(glGetUniformLocation(_programM, "scaleFactor"), scaleFactor);
    glUniform1f(glGetUniformLocation(_programM, "aspectFactor"), aspect);
    glUniform2f(glGetUniformLocation(_programM, "moveParams"), initialX, initialY);
  }
  else if (useJulia)
  {
    glUseProgram(_programJ);
    glUniform1f(glGetUniformLocation(_programJ, "scaleFactor"), juliaScaleFactor);
    glUniform1f(glGetUniformLocation(_programJ, "aspectFactor"), fabsf(self.view.bounds.size.width / self.view.bounds.size.height));
    glUniform2f(glGetUniformLocation(_programJ, "setParams"), initialX, initialY);
    glUniform2f(glGetUniformLocation(_programJ, "moveParams"), juliaX, juliaY);
    
  }
  else
  {
   
    float width  = self.view.frame.size.width;
    float height = self.view.frame.size.height;

    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation))
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width*(int)screenScale-1, (height*(int)screenScale*2)-2, 0, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture);
    else
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, height*(int)screenScale-1, (width*(int)screenScale*2)-2, 0, GL_RGBA, GL_UNSIGNED_BYTE, juliaTexture);
    
    flippyFloppy = !flippyFloppy;
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _faceTexture);
    glUniform1i(_textureUniform, 0);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(testVert), testVert, GL_STATIC_DRAW);
    
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    //glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, BUFFER_OFFSET(0));
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Normal));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    
    glUseProgram(_programC);
  }
  
  
  glDrawArrays(GL_TRIANGLES, 0, 6);
}

#pragma mark -  OpenGL ES 3 shader compilation

- (BOOL)loadShadersMandlebrot
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _programM = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderM" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_programM, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_programM, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_programM, GLKVertexAttribPosition, "position");
  
    // Link program.
    if (![self linkProgram:_programM]) {
        NSLog(@"Failed to link program: %d", _programM);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_programM) {
            glDeleteProgram(_programM);
            _programM = 0;
        }
        
        return NO;
    }
  
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_programM, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_programM, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}


- (BOOL)loadShadersJulia
{
  GLuint vertShader, fragShader;
  NSString *vertShaderPathname, *fragShaderPathname;
  
  // Create shader program.
  _programJ = glCreateProgram();
  
  // Create and compile vertex shader.
  vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
  if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }
  
  // Create and compile fragment shader.
  fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderJ" ofType:@"fsh"];
  if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
    NSLog(@"Failed to compile fragment shader");
    return NO;
  }
  
  // Attach vertex shader to program.
  glAttachShader(_programJ, vertShader);
  
  // Attach fragment shader to program.
  glAttachShader(_programJ, fragShader);
  
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_programJ, GLKVertexAttribPosition, "position");
  
  // Link program.
  if (![self linkProgram:_programJ]) {
    NSLog(@"Failed to link program: %d", _programJ);
    
    if (vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }
    if (fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }
    if (_programJ) {
      glDeleteProgram(_programJ);
      _programJ = 0;
    }
    
    return NO;
  }
  
  // Release vertex and fragment shaders.
  if (vertShader) {
    glDetachShader(_programJ, vertShader);
    glDeleteShader(vertShader);
  }
  if (fragShader) {
    glDetachShader(_programJ, fragShader);
    glDeleteShader(fragShader);
  }
  
  return YES;
}


- (BOOL)loadShadersCube
{
  GLuint vertShader, fragShader;
  NSString *vertShaderPathname, *fragShaderPathname;
  
  // Create shader program.
  _programC = glCreateProgram();
  
  // Create and compile vertex shader.
  vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderC" ofType:@"vsh"];
  if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }
  
  // Create and compile fragment shader.
  fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderC" ofType:@"fsh"];
  if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
    NSLog(@"Failed to compile fragment shader");
    return NO;
  }
  
  // Attach vertex shader to program.
  glAttachShader(_programC, vertShader);
  
  // Attach fragment shader to program.
  glAttachShader(_programC, fragShader);
  
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_programC, GLKVertexAttribPosition , "position");
  glBindAttribLocation(_programC, GLKVertexAttribTexCoord0, "textureUV");
  
  
  //May need additional texture and flag to select texture uniform
  
  
  // Link program.
  if (![self linkProgram:_programC]) {
    NSLog(@"Failed to link program: %d", _programC);
    
    if (vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }
    if (fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }
    if (_programC) {
      glDeleteProgram(_programC);
      _programC = 0;
    }
    
    return NO;
  }
  
  // Release vertex and fragment shaders.
  if (vertShader) {
    glDetachShader(_programC, vertShader);
    glDeleteShader(vertShader);
  }
  if (fragShader) {
    glDetachShader(_programC, fragShader);
    glDeleteShader(fragShader);
  }
  
  return YES;
}



- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
  
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
