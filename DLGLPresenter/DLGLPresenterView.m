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

@property(nonatomic, readonly) void *CGLContextObj;

- (void)lockContext;
- (void)unlockContext;
- (void)initGL;
- (void)initDisplayLink;
- (void)drawForTime:(const CVTimeStamp *)outputTime;

@end


@implementation DLGLPresenterView


static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [(DLGLPresenterView *)displayLinkContext drawForTime:outputTime];
    [pool drain];
    return kCVReturnSuccess;
}


- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    
    if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat])) {
    }
    
    [pixelFormat release];
    
    return self;
}


- (void *)CGLContextObj
{
    return [[self openGLContext] CGLContextObj];
}


- (void)lockContext
{
    CGLError error = CGLLockContext(self.CGLContextObj);
    NSAssert1((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
}


- (void)unlockContext
{
    CGLError error = CGLUnlockContext(self.CGLContextObj);
    NSAssert1((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
}


- (void)prepareOpenGL
{
    [self initGL];
    [self initDisplayLink];
}


- (void)initGL
{
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
}


- (void)initDisplayLink
{
    CVReturn error;
    
    error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    NSAssert1((kCVReturnSuccess == error), @"Unable to create display link (error = %d)", error);
    
    error = CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, self);
    NSAssert1((kCVReturnSuccess == error), @"Unable to set display link output callback (error = %d)", error);
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


- (void)drawForTime:(const CVTimeStamp *)outputTime
{
    NSAssert1((outputTime->flags & kCVTimeStampVideoTimeValid), @"Video time is invalid (%lld)", outputTime->videoTime);
    NSAssert1((outputTime->flags & kCVTimeStampHostTimeValid), @"Host time is invalid (%llu)", outputTime->hostTime);
    NSAssert1((outputTime->flags & kCVTimeStampVideoRefreshPeriodValid),
              @"Video refresh period is invalid (%lld)", outputTime->videoRefreshPeriod);
    
    [self lockContext];
    
    [[self openGLContext] makeCurrentContext];
    
    [presentable drawForTime:outputTime];
    
    [self unlockContext];
}


- (void)startPresentation:(id <DLGLPresentable>)newPresentable
{
    NSParameterAssert(newPresentable);
    NSAssert((presentable == nil), @"Presentation is already started");
    
    presentable = [newPresentable retain];
    
    CVReturn error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                       self.CGLContextObj,
                                                                       [[self pixelFormat] CGLPixelFormatObj]);
    NSAssert1((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
    
    error = CVDisplayLinkStart(displayLink);
    NSAssert1((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
}


- (void)stopPresentation
{
    NSAssert((presentable != nil), @"Presentation is not started");
    
    CVReturn error = CVDisplayLinkStop(displayLink);
    NSAssert1((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
    
    [presentable release];
    presentable = nil;
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
    [presentable release];
    [super dealloc];
}


@end


























