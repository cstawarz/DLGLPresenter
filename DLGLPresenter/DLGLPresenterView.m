//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"

#import <OpenGL/gl3.h>


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


- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    
    if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat])) {
        CVReturn error;
        
        error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to create display link (error = %d)", error);
        
        error = CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, self);
        NSAssert1((kCVReturnSuccess == error), @"Unable to set display link output callback (error = %d)", error);
    }
    
    [pixelFormat release];
    
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
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
}


- (void)reshape
{
    [self lockContext];
    
    [[self openGLContext] makeCurrentContext];
    
    NSRect rect = [self bounds];
    glViewport(0, 0, (GLsizei)(rect.size.width), (GLsizei)(rect.size.height));
    
    [self unlockContext];
}


- (void)update
{
    [self lockContext];
    [super update];
    [self unlockContext];
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
    if (CVDisplayLinkIsRunning(displayLink)) {
        return;
    }
    
    CVReturn error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                       [[self openGLContext] CGLContextObj],
                                                                       [[self pixelFormat] CGLPixelFormatObj]);
    NSAssert1((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
    
    error = CVDisplayLinkStart(displayLink);
    NSAssert1((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
}


- (void)stopPresentation
{
    if (!CVDisplayLinkIsRunning(displayLink)) {
        return;
    }
    
    CVReturn error = CVDisplayLinkStop(displayLink);
    NSAssert1((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}


@end


























