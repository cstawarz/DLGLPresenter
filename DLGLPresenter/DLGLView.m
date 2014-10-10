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
    BOOL shouldUpdate;
    BOOL shouldResize;
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
        [self prepareContext];
    }];
}


- (void)reshape
{
    [self DLGLPerformBlockWithContextLock:^{
        shouldResize = YES;
    }];
}


- (void)update
{
    [self DLGLPerformBlockWithContextLock:^{
        shouldUpdate = YES;
    }];
}


- (void)drawRect:(NSRect)dirtyRect
{
    if (!(self.running)) {
        [self DLGLPerformBlockWithContextLock:^{
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            [[self openGLContext] flushBuffer];
        }];
    }
}


- (void)setRunning:(BOOL)running
{
    if (self.running == running) {
        return;
    }
    
    CVReturn error;
    
    if (running) {
        
        _running = YES;
        
        error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                  [[self openGLContext] CGLContextObj],
                                                                  [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
        
    } else {
        
        error = CVDisplayLinkStop(displayLink);
        NSAssert((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
        
        _running = NO;
        
    }
}


static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext)
{
    DLGLView *view = (__bridge DLGLView *)displayLinkContext;
    
    @autoreleasepool {
        [view DLGLPerformBlockWithContextLock:^{
            if (view->shouldUpdate) {
                [[view openGLContext] update];
                view->shouldUpdate = NO;
            }
            
            [[view openGLContext] makeCurrentContext];
            
            if (view->shouldResize) {
                [view resizeContext];
                view->shouldResize = NO;
            }
            
            [view drawForTime:outputTime];
        }];
    }
    
    return kCVReturnSuccess;
}


- (void)prepareContext
{
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
}


- (void)resizeContext
{
    NSSize size = [self convertRectToBacking:[self bounds]].size;
    
    _viewportWidth = (GLsizei)(size.width);
    _viewportHeight = (GLsizei)(size.height);
    
    glViewport(0, 0, self.viewportWidth, self.viewportHeight);
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


- (NSTimeInterval)refreshPeriod
{
    return CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink);
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
}


@end




























