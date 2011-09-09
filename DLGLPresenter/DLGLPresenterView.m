//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"

#import <OpenGL/gl3.h>


//#define TRACE_METHOD_CALLS

#ifdef TRACE_METHOD_CALLS
#  define BEGIN_METHOD  NSLog(@"Entered %s", __PRETTY_FUNCTION__);
#  define END_METHOD    NSLog(@"Exiting %s", __PRETTY_FUNCTION__);
#else
#  define BEGIN_METHOD
#  define END_METHOD
#endif


@interface DLGLPresenterView ()

- (void)performBlockOnGLContext:(dispatch_block_t)block;
- (void)checkForSkippedFrames:(const CVTimeStamp *)outputTime;
- (void)presentFrameForTime:(const CVTimeStamp *)outputTime;
- (void)startDisplayLink;
- (void)stopDisplayLink;

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
    DLGLPresenterView *presenterView = (DLGLPresenterView *)displayLinkContext;
    
    @try {
        [presenterView checkForSkippedFrames:outputTime];
        [presenterView presentFrameForTime:outputTime];
    }
    @finally {
        [pool drain];
    }
    
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


- (void)performBlockOnGLContext:(dispatch_block_t)block
{
    NSOpenGLContext *context = [self openGLContext];
    CGLContextObj contextObj = [context CGLContextObj];
    
    CGLError error = CGLLockContext(contextObj);
    NSAssert1((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
    
    @try {
        [context makeCurrentContext];
        block();
    }
    @finally {
        error = CGLUnlockContext(contextObj);
        NSAssert1((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
    }
}


- (void)prepareOpenGL
{
    [self performBlockOnGLContext:^{
        GLint swapInterval = 1;
        [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    }];
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        NSRect rect = [self bounds];
        glViewport(0, 0, (GLsizei)(rect.size.width), (GLsizei)(rect.size.height));
        
        if (presenting && ![self inLiveResize]) {
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
    [self performBlockOnGLContext:^{
        [super update];
    }];
}


- (void)checkForSkippedFrames:(const CVTimeStamp *)outputTime
{
    if (previousVideoTime) {
        int64_t delta = (outputTime->videoTime - previousVideoTime) - outputTime->videoRefreshPeriod;
        if (delta) {
            double skippedFrameCount = (double)delta / (double)(outputTime->videoRefreshPeriod);
            if ([delegate respondsToSelector:@selector(presenterView:skippedFrames:)]) {
                [delegate presenterView:self skippedFrames:skippedFrameCount];
            } else {
                NSLog(@"In %s: Display link skipped %g frame%s", __PRETTY_FUNCTION__, skippedFrameCount,
                      ((skippedFrameCount == 1.0) ? "" : "s"));
            }
        }
    }
    
    previousVideoTime = outputTime->videoTime;
}


- (void)presentFrameForTime:(const CVTimeStamp *)outputTime
{
    [self performBlockOnGLContext:^{
        if (shouldDraw ||
            ![delegate respondsToSelector:@selector(presenterView:shouldDrawForTime:)] ||
            [delegate presenterView:self shouldDrawForTime:outputTime])
        {
            [delegate presenterView:self willDrawForTime:outputTime];
            
            [[self openGLContext] flushBuffer];
            
            if ([delegate respondsToSelector:@selector(presenterView:didDrawForTime:)]) {
                [delegate presenterView:self didDrawForTime:outputTime];
            }
            
            shouldDraw = NO;
        }
    }];
}


- (void)startPresentation
{
    if (!presenting) {
        if ([delegate respondsToSelector:@selector(presenterViewWillStartPresentation:)]) {
            [self performBlockOnGLContext:^{
                [delegate presenterViewWillStartPresentation:self];
            }];
        }
        
        presenting = YES;
        
        [self startDisplayLink];
    }
}


- (void)stopPresentation
{
    if (presenting) {
        [self stopDisplayLink];
        
        presenting = NO;
        
        if ([delegate respondsToSelector:@selector(presenterViewDidStopPresentation:)]) {
            [self performBlockOnGLContext:^{
                [delegate presenterViewDidStopPresentation:self];
            }];
        }
    }
}


- (void)startDisplayLink
{
    if (!CVDisplayLinkIsRunning(displayLink)) {
        previousVideoTime = 0ll;
        
        CVReturn error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                           [[self openGLContext] CGLContextObj],
                                                                           [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert1((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
    }
}


- (void)stopDisplayLink
{
    if (CVDisplayLinkIsRunning(displayLink)) {
        CVReturn error = CVDisplayLinkStop(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
    }
}


- (void)viewWillStartLiveResize
{
    if (presenting) {
        [self stopDisplayLink];
    }
}


- (void)viewDidEndLiveResize
{
    if (presenting) {
        [self startDisplayLink];
    }
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}


@end


























