//
//  DLGLPresenterView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterView.h"

#import "DLGLUtilities.h"


@interface DLGLPresenterView ()

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
    NSCAssert1((outputTime->flags & kCVTimeStampVideoTimeValid),
               @"Video time is invalid (%lld)", outputTime->videoTime);
    NSCAssert1((outputTime->flags & kCVTimeStampHostTimeValid),
               @"Host time is invalid (%llu)", outputTime->hostTime);
    NSCAssert1((outputTime->flags & kCVTimeStampVideoRefreshPeriodValid),
               @"Video refresh period is invalid (%lld)", outputTime->videoRefreshPeriod);
    
    DLGLPresenterView *presenterView = (DLGLPresenterView *)displayLinkContext;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        [presenterView checkForSkippedFrames:outputTime];
        [presenterView presentFrameForTime:outputTime];
    }
    @finally {
        [pool drain];
    }
    
    return kCVReturnSuccess;
}


@implementation DLGLPresenterView


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
    
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}


+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen
{
    NSRect screenRect = [screen frame];
    NSRect windowRect = NSMakeRect(0.0, 0.0, screenRect.size.width, screenRect.size.height);
    
    NSWindow *fullScreenWindow = [[[NSWindow alloc] initWithContentRect:windowRect
                                                              styleMask:NSBorderlessWindowMask
                                                                backing:NSBackingStoreBuffered
                                                                  defer:YES
                                                                 screen:screen] autorelease];
    [fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
    [fullScreenWindow setOpaque:YES];
    [fullScreenWindow setHidesOnDeactivate:NO];
    
    DLGLPresenterView *presenterView = [[self alloc] initWithFrame:windowRect];
    [fullScreenWindow setContentView:presenterView];
    [presenterView release];
    
    return fullScreenWindow;
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
        [super reshape];
        
        if (presenting) {
            shouldDraw = YES;
        } else {
            glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            [[self openGLContext] flushBuffer];
        }
    }];
}


- (void)setPresenting:(BOOL)shouldPresent
{
    CVReturn error;
    
    if (shouldPresent && !presenting) {
        
        if ([delegate respondsToSelector:@selector(presenterViewWillStartPresentation:)]) {
            [self performBlockOnGLContext:^{
                [delegate presenterViewWillStartPresentation:self];
            }];
        }
        
        shouldDraw = YES;
        presenting = YES;
        startHostTime = currentHostTime = 0ull;
        previousVideoTime = 0ll;
        
        error = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink,
                                                                  [[self openGLContext] CGLContextObj],
                                                                  [[self pixelFormat] CGLPixelFormatObj]);
        NSAssert1((kCVReturnSuccess == error), @"Unable to set display link current display (error = %d)", error);
        
        error = CVDisplayLinkStart(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to start display link (error = %d)", error);
        
    } else if (!shouldPresent && presenting) {
        
        error = CVDisplayLinkStop(displayLink);
        NSAssert1((kCVReturnSuccess == error), @"Unable to stop display link (error = %d)", error);
        
        presenting = NO;
        
        if ([delegate respondsToSelector:@selector(presenterViewDidStopPresentation:)]) {
            [self performBlockOnGLContext:^{
                [delegate presenterViewDidStopPresentation:self];
            }];
        }
        
    }
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
    if (!startHostTime) {
        startHostTime = outputTime->hostTime;
    }
    currentHostTime = outputTime->hostTime;
    
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


- (uint64_t)elapsedTime
{
    if (!presenting) {
        return 0ull;
    }
    
    return DLGLConvertHostTimeToNanos(currentHostTime - startHostTime);
}


- (void)dealloc
{
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}


@end


























