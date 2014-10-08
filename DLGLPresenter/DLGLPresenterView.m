//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterViewPrivate.h"

#import <AppKit/NSOpenGL.h>
#import <CoreVideo/CVHostTime.h>

#import "DLGLViewPrivate.h"
#import "NSOpenGLView+DLGLPresenterAdditions.h"


@implementation DLGLPresenterView
{
    uint64_t startHostTime, currentHostTime;
    int64_t previousVideoTime;
    BOOL shouldDraw;
    
    GLuint framebuffer;
    GLuint renderbuffer;
}


+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen
{
    return [self presenterViewInFullScreenWindow:screen pixelFormat:[self defaultPixelFormat]];
}


+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen pixelFormat:(NSOpenGLPixelFormat *)format
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
    
    DLGLPresenterView *presenterView = [[self alloc] initWithFrame:windowRect pixelFormat:format];
    [fullScreenWindow setContentView:presenterView];
    
    return fullScreenWindow;
}


- (void)prepareOpenGL
{
    [self DLGLPerformBlockWithContextLock:^{
        [super prepareOpenGL];
        
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
        // Trigger redraw
        //
        
        if (self.running) {
            shouldDraw = YES;
        }
    }];
}


- (void)setRunning:(BOOL)running
{
    if (self.running == running) {
        return;
    }
    
    [[self openGLContext] makeCurrentContext];
    
    if (running) {
        
        [self DLGLPerformBlockWithContextLock:^{
            [self.delegate presenterViewWillStartPresentation:self];
        }];
        
        shouldDraw = YES;
        startHostTime = currentHostTime = 0ull;
        previousVideoTime = 0ll;
        
        [super setRunning:YES];
        
    } else {
        
        [super setRunning:NO];
        
        [self DLGLPerformBlockWithContextLock:^{
            [self.delegate presenterViewDidStopPresentation:self];
        }];
        
    }
}


- (void)drawForTime:(const CVTimeStamp *)outputTime
{
    if (previousVideoTime) {
        int64_t delta = (outputTime->videoTime - previousVideoTime) - outputTime->videoRefreshPeriod;
        if (delta) {
            double skippedFrameCount = (double)delta / (double)(outputTime->videoRefreshPeriod);
            [self.delegate presenterView:self skippedFrames:skippedFrameCount];
        }
    }
    
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
    
    previousVideoTime = outputTime->videoTime;
}


- (GLuint)sceneFramebuffer
{
    return framebuffer;
}


- (NSTimeInterval)elapsedTime
{
    if (!self.running) {
        return 0.0;
    }
    
    return (double)(currentHostTime - startHostTime) / CVGetHostClockFrequency();
}


@end


























