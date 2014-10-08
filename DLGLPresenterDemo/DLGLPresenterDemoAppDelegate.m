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
    
    presenterView.running = YES;
    
    NSLog(@"refreshPeriod: %g", [presenterView refreshPeriod]);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    presenterView.running = NO;
#ifdef FULLSCREEN
    [fullScreenWindow orderOut:nil];
#endif
}


@end


























