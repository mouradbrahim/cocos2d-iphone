//
// RenderTexture Demo
// a cocos2d example
//
// Example by Jason Booth (slipster216)

// cocos import
#import "RenderTextureTest.h"

static int sceneIdx=-1;
static NSString *tests[] = {	
	@"RenderTextureSave",
	@"RenderTextureIssue937",
};

Class nextAction()
{
	
	sceneIdx++;
	sceneIdx = sceneIdx % ( sizeof(tests) / sizeof(tests[0]) );
	NSString *r = tests[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class backAction()
{
	sceneIdx--;
	int total = ( sizeof(tests) / sizeof(tests[0]) );
	if( sceneIdx < 0 )
		sceneIdx += total;	
	
	NSString *r = tests[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class restartAction()
{
	NSString *r = tests[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}


#pragma mark -
#pragma mark RenderTextureTest

@implementation RenderTextureTest
-(id) init
{
	if( (self = [super init]) ) {
		
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		CCLabel* label = [CCLabel labelWithString:[self title] fontName:@"Arial" fontSize:26];
		[self addChild: label z:1];
		[label setPosition: ccp(s.width/2, s.height-50)];
		
		NSString *subtitle = [self subtitle];
		if( subtitle ) {
			CCLabel* l = [CCLabel labelWithString:subtitle fontName:@"Thonburi" fontSize:16];
			[self addChild:l z:1];
			[l setPosition:ccp(s.width/2, s.height-80)];
		}
		
		
		CCMenuItemImage *item1 = [CCMenuItemImage itemFromNormalImage:@"b1.png" selectedImage:@"b2.png" target:self selector:@selector(backCallback:)];
		CCMenuItemImage *item2 = [CCMenuItemImage itemFromNormalImage:@"r1.png" selectedImage:@"r2.png" target:self selector:@selector(restartCallback:)];
		CCMenuItemImage *item3 = [CCMenuItemImage itemFromNormalImage:@"f1.png" selectedImage:@"f2.png" target:self selector:@selector(nextCallback:)];
		
		CCMenu *menu = [CCMenu menuWithItems:item1, item2, item3, nil];
		
		menu.position = CGPointZero;
		item1.position = ccp( s.width/2 - 100,30);
		item2.position = ccp( s.width/2, 30);
		item3.position = ccp( s.width/2 + 100,30);
		[self addChild: menu z:1];	
	}
	return self;
}

-(void) dealloc
{
	[super dealloc];
}

-(void) restartCallback: (id) sender
{
	CCScene *s = [CCScene node];
	[s addChild: [restartAction() node]];
	[[CCDirector sharedDirector] replaceScene: s];
}

-(void) nextCallback: (id) sender
{
	CCScene *s = [CCScene node];
	[s addChild: [nextAction() node]];
	[[CCDirector sharedDirector] replaceScene: s];
}

-(void) backCallback: (id) sender
{
	CCScene *s = [CCScene node];
	[s addChild: [backAction() node]];
	[[CCDirector sharedDirector] replaceScene: s];
}

-(NSString*) title
{
	return @"No title";
}

-(NSString*) subtitle
{
	return @"";
}
@end

#pragma mark -
#pragma mark RenderTextureSave

@implementation RenderTextureSave
-(id) init
{
	if( (self = [super init]) ) {
		
		CGSize s = [[CCDirector sharedDirector] winSize];	
		
		// create a render texture, this is what we're going to draw into
		target = [[CCRenderTexture renderTextureWithWidth:s.width height:s.height] retain];
		[target setPosition:ccp(s.width/2, s.height/2)];
		
		
		// It's possible to modify the RenderTexture blending function by
//		[[target sprite] setBlendFunc:(ccBlendFunc) {GL_ONE, GL_ONE_MINUS_SRC_ALPHA}];
		
		// note that the render texture is a cocosnode, and contains a sprite of it's texture for convience,
		// so we can just parent it to the scene like any other cocos node
		[self addChild:target z:1];
		
		// create a brush image to draw into the texture with
		brush = [[CCSprite spriteWithFile:@"fire.png"] retain];
		[brush setOpacity:20];
		self.isTouchEnabled = YES;
		
		// Save Image menu
		[CCMenuItemFont setFontSize:16];
		CCMenuItem *item = [CCMenuItemFont itemFromString:@"Save Image" target:self selector:@selector(saveImage:)];
		CCMenu *menu = [CCMenu menuWithItems:item, nil];
		[self addChild:menu];
		[menu setPosition:ccp(s.width-80, s.height-30)];
	}
	return self;
}

-(NSString*) title
{
	return @"Touch the screen";
}

-(NSString*) subtitle
{
	return @"Press 'Save Image' to create an snapshot of the render texture";
}

-(void) saveImage:(id)sender
{
	static int counter=0;
	
	NSString *str = [NSString stringWithFormat:@"image-%d.png", counter];
	[target saveBuffer:str format:kCCImageFormatPNG];
	NSLog(@"Image saved: %@", str);
	
	counter++;
}

-(void) dealloc
{
	[brush release];
	[target release];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[super dealloc];
	
}


-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint start = [touch locationInView: [touch view]];	
	start = [[CCDirector sharedDirector] convertToGL: start];
	CGPoint end = [touch previousLocationInView:[touch view]];
	end = [[CCDirector sharedDirector] convertToGL:end];
	
	// begin drawing to the render texture
	[target begin];
	
	// for extra points, we'll draw this smoothly from the last position and vary the sprite's
	// scale/rotation/offset
	float distance = ccpDistance(start, end);
	if (distance > 1)
	{
		int d = (int)distance;
		for (int i = 0; i < d; i++)
		{
			float difx = end.x - start.x;
			float dify = end.y - start.y;
			float delta = (float)i / distance;
			[brush setPosition:ccp(start.x + (difx * delta), start.y + (dify * delta))];
			[brush setRotation:rand()%360];
			float r = ((float)(rand()%50)/50.f) + 0.25f;
			[brush setScale:r];
			// Call visit to draw the brush, don't call draw..
			[brush visit];
		}
	}
	// finish drawing and return context back to the screen
	[target end];
}
@end

#pragma mark -
#pragma mark RenderTextureIssue937

@implementation RenderTextureIssue937

-(id) init
{
	/*
	 *     1    2
	 * A: A1   A2
	 *
	 * B: B1   B2
	 *
	 *  A1: premulti sprite
	 *  A2: premulti render
	 *
	 *  B1: non-premulti sprite
	 *  B2: non-premulti render
	 */
	if( (self=[super init]) ) {
		
		CCColorLayer *background = [CCColorLayer layerWithColor:ccc4(200,200,200,255)];
		[self addChild:background];
		
		CCSprite *spr_premulti = [CCSprite spriteWithFile:@"fire.png"];
		[spr_premulti setPosition:ccp(16,48)];

		CCSprite *spr_nonpremulti = [CCSprite spriteWithFile:@"fire_rgba8888.pvr"];
		[spr_nonpremulti setPosition:ccp(16,16)];


		/* A2 & B2 setup */
		CCRenderTexture *rend = [CCRenderTexture renderTextureWithWidth:32 height:64];
		
		// It's possible to modify the RenderTexture blending function by
//		[[rend sprite] setBlendFunc:(ccBlendFunc) {GL_ONE, GL_ONE_MINUS_SRC_ALPHA}];

		[rend begin];
		[spr_premulti visit];
		[spr_nonpremulti visit];
		[rend end]; 
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		/* A1: setup */
		[spr_premulti setPosition:ccp(s.width/2-16, s.height/2+16)];
		/* B1: setup */
		[spr_nonpremulti setPosition:ccp(s.width/2-16, s.height/2-16)];
		
		[rend setPosition:ccp(s.width/2+16, s.height/2)];
		
		[self addChild:spr_nonpremulti];
		[self addChild:spr_premulti];
		[self addChild:rend];
	}
	
	return self;
}
-(NSString*) title
{
	return @"Testing issue #937";
}

-(NSString*) subtitle
{
	return @"All images should be equal...";
}

@end

#pragma mark -
#pragma mark AppDelegate

// CLASS IMPLEMENTATIONS
@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// must be called before any othe call to the director
	[CCDirector setDirectorType:kCCDirectorTypeDisplayLink];
	
	// before creating any layer, set the landscape mode
	CCDirector *director = [CCDirector sharedDirector];
	
	// landscape orientation
	[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
	
	// set FPS at 60
	[director setAnimationInterval:1.0/60];
	
	// Display FPS: yes
	[director setDisplayFPS:YES];
	
	// Create an EAGLView with a RGB8 color buffer, and a depth buffer of 24-bits
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565
								   depthFormat:GL_DEPTH_COMPONENT24_OES
							preserveBackbuffer:NO];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
	// 2D projection
//	[director setProjection:kCCDirectorProjection2D];
	
	// To use High-Res un comment the following line
//	[director setContentScaleFactor:2];	
	
	// make the OpenGLView a child of the main window
	[window addSubview:glView];
	
	// make main window visible
	[window makeKeyAndVisible];	
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];		
	
	CCScene *scene = [CCScene node];
	[scene addChild: [nextAction() node]];
	
	[director runWithScene: scene];
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
	[[CCDirector sharedDirector] startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{	
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void) dealloc
{
	[window release];
	[super dealloc];
}
@end
