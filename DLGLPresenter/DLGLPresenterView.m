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
    
    GLuint framebuffer;
    GLuint renderbuffer;
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


- (void)prepareOpenGL
{
    [self DLGLPerformBlockWithContextLock:^{
        [super prepareOpenGL];
        
        GLint swapInterval = 1;
        [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
        
        glGenFramebuffers(1, &framebuffer);
        glGenRenderbuffers(1, &renderbuffer);
    }];
}


- (void)reshape
{
    [self DLGLPerformBlockWithContextLock:^{
        [super reshape];
        
        //
        // Resize the renderbuffer
        //
        
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, self.viewportWidth, self.viewportHeight);
        glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
        NSAssert((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
        
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
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
            
            [self.delegate presenterView:self willDrawForTime:outputTime];
            
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        }
        
        [self drawFramebuffer:framebuffer fromView:self inView:self];
        [[self openGLContext] flushBuffer];
        
        if (shouldDraw) {
            [self.delegate presenterView:self didDrawForTime:outputTime];
            shouldDraw = NO;
        }
    }];
    
    previousHostTime = currentHostTime;
    previousVideoTime = outputTime->videoTime;
}


- (GLuint)sceneFramebuffer {
    return framebuffer;
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


























