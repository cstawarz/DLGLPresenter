//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"

#import <CoreVideo/CVHostTime.h>
#import <CoreVideo/CVDisplayLink.h>

#import "DLGLUtilities.h"


@interface DLGLPresenterView ()

- (void)allocateBufferStorage;
- (void)storeBackBuffer;
- (void)drawStoredBuffer;
- (void)checkForSkippedFrames:(const CVTimeStamp *)outputTime;
- (void)presentFrameForTime:(const CVTimeStamp *)outputTime;

@end


static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext)
{
    DLGLPresenterView *presenterView = (__bridge DLGLPresenterView *)displayLinkContext;
    
    @autoreleasepool {
        [presenterView checkForSkippedFrames:outputTime];
        [presenterView presentFrameForTime:outputTime];
    }
    
    return kCVReturnSuccess;
}


@implementation DLGLPresenterView
{
    CVDisplayLinkRef displayLink;
    uint64_t startHostTime, currentHostTime;
    int64_t previousVideoTime;
    BOOL shouldDraw;
    
    GLuint framebuffer, renderbuffer;
}


@synthesize delegate, presenting, elapsedTime;


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFAMinimumPolicy,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
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


- (void)prepareOpenGL
{
    [self performBlockOnGLContext:^{
        GLint swapInterval = 1;
        [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
        
        glGenFramebuffers(1, &framebuffer);
        glGenRenderbuffers(1, &renderbuffer);
    }];
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        [self updateViewport];
        [self allocateBufferStorage];  // Resize the renderbuffer
        
        if (presenting) {
            shouldDraw = YES;
        } else {
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            [[self openGLContext] flushBuffer];
        }
    }];
}


- (void)allocateBufferStorage
{
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, self.viewportWidth, self.viewportHeight);
    glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
    NSAssert((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}


- (void)storeBackBuffer
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    glReadBuffer(GL_BACK_LEFT);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    GLenum drawBuffers[] = { GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, self.viewportWidth, self.viewportHeight,
                      0, 0, self.viewportWidth, self.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
}


- (void)drawStoredBuffer
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    GLenum drawBuffers[] = { GL_BACK_LEFT };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, self.viewportWidth, self.viewportHeight,
                      0, 0, self.viewportWidth, self.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}


- (void)setPresenting:(BOOL)shouldPresent
{
    CVReturn error;
    
    if (shouldPresent && !presenting) {
        
        [self performBlockOnGLContext:^{
            [delegate presenterViewWillStartPresentation:self];
        }];
        
        shouldDraw = YES;
        presenting = YES;
        startHostTime = currentHostTime = 0ull;
        previousVideoTime = 0ll;
        
        error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                  [[self openGLContext] CGLContextObj],
                                                                  [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
        
    } else if (!shouldPresent && presenting) {
        
        error = CVDisplayLinkStop(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
        
        presenting = NO;
        
        [self performBlockOnGLContext:^{
            [delegate presenterViewDidStopPresentation:self];
        }];
        
    }
}


- (void)checkForSkippedFrames:(const CVTimeStamp *)outputTime
{
    NSAssert((outputTime->flags & kCVTimeStampVideoTimeValid),
             @"Video time is invalid (%lld)", outputTime->videoTime);
    NSAssert((outputTime->flags & kCVTimeStampVideoRefreshPeriodValid),
             @"Video refresh period is invalid (%lld)", outputTime->videoRefreshPeriod);
    
    if (previousVideoTime) {
        int64_t delta = (outputTime->videoTime - previousVideoTime) - outputTime->videoRefreshPeriod;
        if (delta) {
            double skippedFrameCount = (double)delta / (double)(outputTime->videoRefreshPeriod);
            [delegate presenterView:self skippedFrames:skippedFrameCount];
        }
    }
    
    previousVideoTime = outputTime->videoTime;
}


- (void)presentFrameForTime:(const CVTimeStamp *)outputTime
{
    NSAssert((outputTime->flags & kCVTimeStampHostTimeValid),
             @"Host time is invalid (%llu)", outputTime->hostTime);
    
    if (!startHostTime) {
        startHostTime = outputTime->hostTime;
    }
    currentHostTime = outputTime->hostTime;
    
    [self performBlockOnGLContext:^{
        if (!shouldDraw && [delegate presenterView:self shouldDrawForTime:outputTime]) {
            shouldDraw = YES;
        }
        
        if (!shouldDraw) {
            [self drawStoredBuffer];
        } else {
            [delegate presenterView:self willDrawForTime:outputTime];
            [self storeBackBuffer];
        }
        
        [[self openGLContext] flushBuffer];
        
        if (shouldDraw) {
            [delegate presenterView:self didDrawForTime:outputTime];
            shouldDraw = NO;
        }
    }];
}


- (double)elapsedTime
{
    if (!presenting) {
        return 0.0;
    }
    
    return (double)(currentHostTime - startHostTime) / CVGetHostClockFrequency();
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
}


@end


























