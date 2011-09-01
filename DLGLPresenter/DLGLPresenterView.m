//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"


//#define TRACE_METHOD_CALLS

#ifdef TRACE_METHOD_CALLS
#  define BEGIN_METHOD  NSLog(@"Entered %s", __PRETTY_FUNCTION__);
#  define END_METHOD    NSLog(@"Exiting %s", __PRETTY_FUNCTION__);
#else
#  define BEGIN_METHOD
#  define END_METHOD
#endif


@interface DLGLPresenterView ()

- (void)lockContext;
- (void)unlockContext;
- (void)presentFrameForTime:(const CVTimeStamp *)outputTime;

@end


@implementation DLGLPresenterView


@synthesize delegate;


static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext)
{
    NSCAssert1((outputTime->flags & kCVTimeStampVideoTimeValid),
               @"Video time is invalid (%lld)", outputTime->videoTime);
    NSCAssert1((outputTime->flags & kCVTimeStampHostTimeValid),
               @"Host time is invalid (%llu)", outputTime->hostTime);
    NSCAssert1((outputTime->flags & kCVTimeStampVideoRefreshPeriodValid),
              @"Video refresh period is invalid (%lld)", outputTime->videoRefreshPeriod);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [(DLGLPresenterView *)displayLinkContext presentFrameForTime:outputTime];
    [pool drain];
    
    return kCVReturnSuccess;
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        0
    };
    
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}


- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
    if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat])) {
        CVReturn error;
        
        error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to create display link (error = %d)", error);
        
        error = CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, self);
        NSAssert1((kCVReturnSuccess == error), @"Unable to set display link output callback (error = %d)", error);
    }
    
    return self;
}


- (void)lockContext
{
    CGLError error = CGLLockContext([[self openGLContext] CGLContextObj]);
    NSAssert1((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
}


- (void)unlockContext
{
    CGLError error = CGLUnlockContext([[self openGLContext] CGLContextObj]);
    NSAssert1((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
}


- (void)prepareOpenGL
{
    BEGIN_METHOD
    
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    
    END_METHOD
}


- (void)reshape
{
    BEGIN_METHOD
    
    [self lockContext];
    
    [[self openGLContext] makeCurrentContext];
    
    NSRect rect = [self bounds];
    glViewport(0, 0, (GLsizei)(rect.size.width), (GLsizei)(rect.size.height));
    
    [self unlockContext];
    
    END_METHOD
}


- (void)update
{
    BEGIN_METHOD
    
    [self lockContext];
    [super update];
    [self unlockContext];
    
    END_METHOD
}


- (void)presentFrameForTime:(const CVTimeStamp *)outputTime
{
    [self lockContext];
    
    [[self openGLContext] makeCurrentContext];
    
    [delegate presenterView:self willPresentFrameForTime:outputTime];
    
    [[self openGLContext] flushBuffer];
    
    [self unlockContext];
}


- (void)startPresentation
{
    BEGIN_METHOD
    
    if (!CVDisplayLinkIsRunning(displayLink)) {
        if ([delegate respondsToSelector:@selector(presenterViewWillStartPresentation:)]) {
            [self lockContext];
            [[self openGLContext] makeCurrentContext];
            [delegate presenterViewWillStartPresentation:self];
            [self unlockContext];
        }
        
        CVReturn error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                           [[self openGLContext] CGLContextObj],
                                                                           [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert1((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
    }
    
    END_METHOD
}


- (void)stopPresentation
{
    BEGIN_METHOD
    
    if (CVDisplayLinkIsRunning(displayLink)) {
        CVReturn error = CVDisplayLinkStop(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
        
        if ([delegate respondsToSelector:@selector(presenterViewDidStopPresentation:)]) {
            [self lockContext];
            [[self openGLContext] makeCurrentContext];
            [delegate presenterViewDidStopPresentation:self];
            [self unlockContext];
        }
    }
    
    END_METHOD
}


- (GLuint)createShader:(GLenum)shaderType withSource:(NSString *)shaderSource
{
    GLuint shader = glCreateShader(shaderType);
    
    const char *shaderSourceUTF8 = [shaderSource UTF8String];
    glShaderSource(shader, 1, &shaderSourceUTF8, NULL);
    
    glCompileShader(shader);
    
    GLint infoLogLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLog[infoLogLength];
        glGetShaderInfoLog(shader, infoLogLength, NULL, infoLog);
        NSLog(@"In %s: Shader compilation produced the following information log:\n%s", __PRETTY_FUNCTION__, infoLog);
    }

    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    NSAssert((GL_TRUE == compileStatus), @"Shader compilation failed");
    
    return shader;
}


- (GLuint)createProgramFromShaders:(GLuint)shader, ...
{
    GLuint program = glCreateProgram();
    
    va_list shaderList;
    va_start(shaderList, shader);
    
    while (shader) {
        glAttachShader(program, shader);
        shader = va_arg(shaderList, GLuint);
    }
    
    va_end(shaderList);
    
    glLinkProgram(program);
    
    GLint infoLogLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLog[infoLogLength];
        glGetProgramInfoLog(program, infoLogLength, NULL, infoLog);
        NSLog(@"In %s: Program linking produced the following information log:\n%s", __PRETTY_FUNCTION__, infoLog);
    }
    
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    NSAssert((GL_TRUE == linkStatus), @"Program linking failed");
    
    return program;
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}


@end


























