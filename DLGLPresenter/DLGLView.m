//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLViewPrivate.h"

#import <AppKit/NSOpenGL.h>
#import <CoreVideo/CVDisplayLink.h>

#import "NSOpenGLView+DLGLPresenterAdditions.h"


@implementation DLGLView
{
    CVDisplayLinkRef displayLink;
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    if ((self = [super initWithFrame:frameRect pixelFormat:format])) {
        [self setWantsBestResolutionOpenGLSurface:YES];
        
        CVReturn error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to create display link (error = %d)", error);
        
        error = CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void *)(self));
        NSAssert((kCVReturnSuccess == error), @"Unable to set display link output callback (error = %d)", error);
    }
    
    return self;
}


- (void)prepareOpenGL
{
    [self DLGLPerformBlockWithContextLock:^{
        GLint swapInterval = 1;
        [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    }];
}


- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    [self DLGLPerformBlockWithContextLock:^{
        NSSize size = [self convertRectToBacking:[self bounds]].size;
        
        _viewportWidth = (GLsizei)(size.width);
        _viewportHeight = (GLsizei)(size.height);
        
        glViewport(0, 0, self.viewportWidth, self.viewportHeight);
    }];
}


- (void)update
{
    [self DLGLPerformBlockWithContextLock:^{
        [super update];
    }];
}


- (void)drawRect:(NSRect)dirtyRect
{
    if (!CVDisplayLinkIsRunning(displayLink)) {
        [self DLGLPerformBlockWithContextLock:^{
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            [[self openGLContext] flushBuffer];
        }];
    }
}


- (void)startDisplayLink
{
    CVReturn error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                       [[self openGLContext] CGLContextObj],
                                                                       [[self pixelFormat] CGLPixelFormatObj]);
    NSAssert((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
    
    error = CVDisplayLinkStart(displayLink);
    NSAssert((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
}


- (void)stopDisplayLink
{
    CVReturn error = CVDisplayLinkStop(displayLink);
    NSAssert((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
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
    
    DLGLView *view = (__bridge DLGLView *)displayLinkContext;
    
    @autoreleasepool {
        [view drawForTime:outputTime];
    }
    
    return kCVReturnSuccess;
}


- (void)drawForTime:(const CVTimeStamp *)outputTime
{
    // Default implementation does nothing
}


- (void)drawFramebuffer:(GLuint)framebuffer fromView:(DLGLView *)sourceView inView:(DLGLView *)destView
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    GLenum drawBuffers[] = { GL_BACK_LEFT };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, sourceView.viewportWidth, sourceView.viewportHeight,
                      0, 0, destView.viewportWidth, destView.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
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


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
}


@end




























