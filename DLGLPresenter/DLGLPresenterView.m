//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"

#import <AppKit/NSOpenGL.h>
#import <CoreVideo/CVHostTime.h>
#import <CoreVideo/CVDisplayLink.h>
#import <OpenGL/gl3ext.h>

#import "DLGLUtilities.h"
#import "NSOpenGLView+DLGLPresenterAdditions.h"


@implementation DLGLPresenterView
{
    CVDisplayLinkRef displayLink;
    uint64_t startHostTime, currentHostTime, previousHostTime;
    int64_t previousVideoTime;
    BOOL shouldDraw;
    
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexPositionBufferObject, texCoordsBufferObject;
    GLuint vertexArrayObject;
    
    GLuint framebuffer;
    GLuint texture;
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAMultisample,
        NSOpenGLPFASampleBuffers, 1,
        NSOpenGLPFASamples, 4,
        NSOpenGLPFASampleAlpha,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}


+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen
{
    NSRect screenRect = [screen frame];
    NSRect windowRect = NSMakeRect(0.0, 0.0, screenRect.size.width, screenRect.size.height);
    
    NSWindow *fullScreenWindow = [[NSWindow alloc] initWithContentRect:windowRect
                                                             styleMask:NSBorderlessWindowMask
                                                               backing:NSBackingStoreBuffered
                                                                 defer:YES
                                                                screen:screen];
    [fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
    [fullScreenWindow setOpaque:YES];
    [fullScreenWindow setHidesOnDeactivate:NO];
    
    DLGLPresenterView *presenterView = [[self alloc] initWithFrame:windowRect];
    [fullScreenWindow setContentView:presenterView];
    
    return fullScreenWindow;
}


- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
    if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat])) {
        CVReturn error;
        
        error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to create display link (error = %d)", error);
        
        error = CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void *)(self));
        NSAssert((kCVReturnSuccess == error), @"Unable to set display link output callback (error = %d)", error);
    }
    
    return self;
}


static const GLchar *vertexShaderSource =
"#version 150\n"
"in vec4 vertexPosition;\n"
"in vec2 texCoords;\n"
"smooth out vec2 varyingTexCoords;\n"
"void main()\n"
"{\n"
"   gl_Position = vertexPosition;\n"
"   varyingTexCoords = texCoords;\n"
"}\n";

static const GLchar *fragmentShaderSource =
"#version 150\n"
"uniform sampler2D colorMap;\n"
"in vec2 varyingTexCoords;\n"
"out vec4 fragColor;\n"
"void main()\n"
"{\n"
"   fragColor = texture(colorMap, varyingTexCoords);\n"
"}\n";

static const GLfloat vertexPosition[] = {
    -1.0f, -1.0f,
     1.0f, -1.0f,
    -1.0f,  1.0f,
     1.0f,  1.0f,
};

static const GLfloat texCoords[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};


- (void)prepareOpenGL
{
    [self DLGLPerformBlockWithContextLock:^{
        [super prepareOpenGL];
        
        GLint swapInterval = 1;
        [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
        
        glEnable(GL_MULTISAMPLE);
        
        //
        // Prepare program
        //
        
        vertexShader = DLGLCreateShader(GL_VERTEX_SHADER, vertexShaderSource);
        fragmentShader = DLGLCreateShader(GL_FRAGMENT_SHADER, fragmentShaderSource);
        
        program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
        glUseProgram(program);
        
        glGenVertexArrays(1, &vertexArrayObject);
        glBindVertexArray(vertexArrayObject);
        
        glGenBuffers(1, &vertexPositionBufferObject);
        glBindBuffer(GL_ARRAY_BUFFER, vertexPositionBufferObject);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPosition), vertexPosition, GL_STATIC_DRAW);
        GLint vertexPositionAttribLocation = glGetAttribLocation(program, "vertexPosition");
        glEnableVertexAttribArray(vertexPositionAttribLocation);
        glVertexAttribPointer(vertexPositionAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
        
        glGenBuffers(1, &texCoordsBufferObject);
        glBindBuffer(GL_ARRAY_BUFFER, texCoordsBufferObject);
        glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
        GLint texCoordsAttribLocation = glGetAttribLocation(program, "texCoords");
        glEnableVertexAttribArray(texCoordsAttribLocation);
        glVertexAttribPointer(texCoordsAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
        
        GLint colorMapUniformLocation = glGetUniformLocation(program, "colorMap");
        glUniform1i(colorMapUniformLocation, 0);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        glUseProgram(0);
        
        //
        // Prepare framebuffer
        //
        
        glGenFramebuffers(1, &framebuffer);
        
        //
        // Prepare texture
        //
        
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        NSAssert([self supportsExtension:@"GL_EXT_texture_sRGB_decode"],
                 @"Missing required extension GL_EXT_texture_sRGB_decode");
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SRGB_DECODE_EXT, GL_SKIP_DECODE_EXT);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    }];
}


- (void)reshape
{
    [self DLGLPerformBlockWithContextLock:^{
        [super reshape];
        
        //
        // Resize the framebuffer texture
        //
        
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
        glBindTexture(GL_TEXTURE_2D, texture);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_SRGB8_ALPHA8,
                     self.viewportWidth,
                     self.viewportHeight,
                     0,
                     GL_BGRA,
                     GL_UNSIGNED_INT_8_8_8_8,
                     NULL);
        glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
        
        GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
        NSAssert((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
        
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        
        //
        // Redraw
        //
        
        if (self.presenting) {
            shouldDraw = YES;
        } else {
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            [[self openGLContext] flushBuffer];
        }
    }];
}


- (void)update
{
    [self DLGLPerformBlockWithContextLock:^{
        [super update];
    }];
}


- (void)drawStoredBuffer
{
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}


- (void)setPresenting:(BOOL)shouldPresent
{
    [[self openGLContext] makeCurrentContext];
    
    CVReturn error;
    
    if (shouldPresent && !self.presenting) {
        
        [self DLGLPerformBlockWithContextLock:^{
            [self.delegate presenterViewWillStartPresentation:self];
        }];
        
        shouldDraw = YES;
        _presenting = YES;
        startHostTime = currentHostTime = previousHostTime = 0ull;
        previousVideoTime = 0ll;
        
        error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                  [[self openGLContext] CGLContextObj],
                                                                  [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
        
    } else if (!shouldPresent && self.presenting) {
        
        error = CVDisplayLinkStop(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
        
        _presenting = NO;
        
        [self DLGLPerformBlockWithContextLock:^{
            [self.delegate presenterViewDidStopPresentation:self];
        }];
        
    }
}


static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext)
{
    NSCAssert((outputTime->flags & kCVTimeStampVideoTimeValid),
              @"Video time is invalid (%lld)", outputTime->videoTime);
    NSCAssert((outputTime->flags & kCVTimeStampHostTimeValid),
              @"Host time is invalid (%llu)", outputTime->hostTime);
    NSCAssert((outputTime->flags & kCVTimeStampVideoRefreshPeriodValid),
              @"Video refresh period is invalid (%lld)", outputTime->videoRefreshPeriod);
    
    DLGLPresenterView *presenterView = (__bridge DLGLPresenterView *)displayLinkContext;
    
    @autoreleasepool {
        [presenterView checkForSkippedFrames:outputTime];
        [presenterView presentFrameForTime:outputTime];
    }
    
    return kCVReturnSuccess;
}


- (void)checkForSkippedFrames:(const CVTimeStamp *)outputTime
{
    double expectedInterval = 1.0;
    
    if (previousVideoTime) {
        int64_t delta = (outputTime->videoTime - previousVideoTime) - outputTime->videoRefreshPeriod;
        if (delta) {
            double skippedFrameCount = (double)delta / (double)(outputTime->videoRefreshPeriod);
            [self.delegate presenterView:self skippedFrames:skippedFrameCount];
            expectedInterval += skippedFrameCount;
        }
    }
    
    if (previousHostTime) {
        double interval = DLGLGetTimeInterval(previousHostTime, outputTime->hostTime) / self.actualRefreshPeriod;
        // FIXME: The tolerance should be configurable, and the delegate should be notified when the test fails
        if (fabs(interval - expectedInterval) / expectedInterval > 0.01) {
            NSLog(@"interval = %g", interval);
        }
    }
}


- (void)presentFrameForTime:(const CVTimeStamp *)outputTime
{
    currentHostTime = outputTime->hostTime;
    if (!startHostTime) {
        startHostTime = currentHostTime;
    }
    
    [[self openGLContext] makeCurrentContext];
    [self DLGLPerformBlockWithContextLock:^{
        if (!shouldDraw && [self.delegate presenterView:self shouldDrawForTime:outputTime]) {
            shouldDraw = YES;
        }
        
        if (shouldDraw) {
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
            GLenum drawBuffers[] = { GL_COLOR_ATTACHMENT0 };
            glDrawBuffers(1, drawBuffers);
            
            glEnable(GL_FRAMEBUFFER_SRGB);
            
            [self.delegate presenterView:self willDrawForTime:outputTime];
            
            glDisable(GL_FRAMEBUFFER_SRGB);
            
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        }
        
        [self drawStoredBuffer];
        [[self openGLContext] flushBuffer];
        
        if (shouldDraw) {
            [self.delegate presenterView:self didDrawForTime:outputTime];
            shouldDraw = NO;
        }
    }];
    
    previousHostTime = currentHostTime;
    previousVideoTime = outputTime->videoTime;
}


- (CVTime)nominalRefreshPeriod
{
    return CVDisplayLinkGetNominalOutputVideoRefreshPeriod(displayLink);
}


- (NSTimeInterval)actualRefreshPeriod
{
    return CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink);
}


- (CVTime)nominalLatency
{
    return CVDisplayLinkGetOutputVideoLatency(displayLink);
}


- (NSTimeInterval)elapsedTime
{
    if (!self.presenting) {
        return 0.0;
    }
    
    return DLGLGetTimeInterval(startHostTime, currentHostTime);
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
}


@end


























