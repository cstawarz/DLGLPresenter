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
#import "HelloImage.h"
#import "MovingTriangle.h"

#define FULLSCREEN


@implementation DLGLPresenterDemoAppDelegate
{
    NSWindow *fullScreenWindow;
    DLGLPresenterView *presenterView;
    id <DLGLPresenterDelegate> presenterDelegate;
    DLGLMirrorView *mirrorView;
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
    mirrorView.sourceView = presenterView;
    
    NSSize aspectRatio = presenterView.bounds.size;
    [self.window setContentAspectRatio:presenterView.bounds.size];
    CGFloat windowHeight = [self.window frame].size.height;
    [self.window setContentSize:NSMakeSize(windowHeight * aspectRatio.width / aspectRatio.height, windowHeight)];
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


























