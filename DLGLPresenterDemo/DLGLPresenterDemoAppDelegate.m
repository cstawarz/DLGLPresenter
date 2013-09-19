//
//  DLGLPresenterDemoAppDelegate.m
//  DLGLPresenterDemo
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterDemoAppDelegate.h"

#import <DLGLPresenter/DLGLPresenter.h>

#import "ScreenFlicker.h"
#import "HelloTriangle.h"
#import "HelloCircle.h"
#import "MovingTriangle.h"

#define FULLSCREEN

#define MIRROR_UPDATE_INTERVAL  (33ull * NSEC_PER_MSEC)  // Update ~30 times per second
#define MIRROR_UPDATE_LEEWAY    ( 5ull * NSEC_PER_MSEC)  // with a leeway of 5ms


@implementation DLGLPresenterDemoAppDelegate
{
    NSWindow *fullScreenWindow;
    DLGLPresenterView *presenterView;
    id <DLGLPresenterDelegate> presenterDelegate;
    
    DLGLMirrorView *mirrorView;
    dispatch_source_t mirrorViewTimer;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    presenterDelegate = [[MovingTriangle alloc] init];
    
#ifdef FULLSCREEN
    fullScreenWindow = [DLGLPresenterView presenterViewInFullScreenWindow:[[NSScreen screens] lastObject]];
    presenterView = [fullScreenWindow contentView];
    mirrorView = [[DLGLMirrorView alloc] initWithFrame:[self.window frame]];
#else
    presenterView = [[DLGLPresenterView alloc] initWithFrame:[self.window frame]];
#endif
    presenterView.delegate = presenterDelegate;
    
#ifdef FULLSCREEN
    [fullScreenWindow makeKeyAndOrderFront:self];
    [self.window setContentView:mirrorView];
    
    NSSize aspectRatio = presenterView.bounds.size;
    [self.window setContentAspectRatio:presenterView.bounds.size];
    CGFloat windowHeight = [self.window frame].size.height;
    [self.window setContentSize:NSMakeSize(windowHeight * aspectRatio.width / aspectRatio.height, windowHeight)];
    
    mirrorView.sourceView = presenterView;
    [self startMirrorViewUpdates];
#else
    [self.window setContentView:presenterView];
#endif
    
    presenterView.presenting = YES;
    [self logDisplayInfo];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    presenterView.presenting = NO;
#ifdef FULLSCREEN
    [fullScreenWindow orderOut:nil];
#endif
}


- (void)startMirrorViewUpdates
{
    mirrorViewTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    NSAssert(mirrorViewTimer, @"Unable to create dispatch timer");
    
    dispatch_source_set_timer(mirrorViewTimer, DISPATCH_TIME_NOW, MIRROR_UPDATE_INTERVAL, MIRROR_UPDATE_LEEWAY);
    
    dispatch_source_set_event_handler(mirrorViewTimer, ^{
        [mirrorView setNeedsDisplay:YES];
    });
    
    dispatch_resume(mirrorViewTimer);
}


- (void)logDisplayInfo
{
    CVTime nominalRefreshPeriod = [presenterView nominalRefreshPeriod];
    if (nominalRefreshPeriod.flags & kCVTimeIsIndefinite) {
        NSLog(@"nominalRefreshPeriod is indefinite");
    } else {
        NSLog(@"nominalRefreshPeriod: %lld/%d", nominalRefreshPeriod.timeValue, nominalRefreshPeriod.timeScale);
    }
    
    NSLog(@"actualRefreshPeriod: %g", [presenterView actualRefreshPeriod]);
    
    CVTime nominalLatency = [presenterView nominalLatency];
    if (nominalLatency.flags & kCVTimeIsIndefinite) {
        NSLog(@"nominalLatency is indefinite");
    } else {
        NSLog(@"nominalLatency: %lld/%d", nominalLatency.timeValue, nominalLatency.timeScale);
    }
}


@end


























