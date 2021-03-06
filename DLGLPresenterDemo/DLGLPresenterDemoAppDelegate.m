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
#import "RefreshTally.h"
#import "SceneKitAnimation.h"
#import "SceneKitShapes.h"

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
    presenterDelegate = [[SceneKitShapes alloc] init];
    
#ifdef FULLSCREEN
    fullScreenWindow = [DLGLPresenterView presenterViewInFullScreenWindow:[NSScreen screens].lastObject];
    presenterView = fullScreenWindow.contentView;
    mirrorView = [[DLGLMirrorView alloc] initWithFrame:(self.window).frame];
#else
    presenterView = [[DLGLPresenterView alloc] initWithFrame:[self.window frame]];
#endif
    presenterView.delegate = presenterDelegate;
    
#ifdef FULLSCREEN
    [fullScreenWindow makeKeyAndOrderFront:self];
    (self.window).contentView = mirrorView;
    mirrorView.sourceView = presenterView;
    
    NSSize aspectRatio = presenterView.bounds.size;
    (self.window).contentAspectRatio = presenterView.bounds.size;
    CGFloat windowHeight = (self.window).frame.size.height;
    [self.window setContentSize:NSMakeSize(windowHeight * aspectRatio.width / aspectRatio.height, windowHeight)];
#else
    [self.window setContentView:presenterView];
#endif
    
    presenterView.running = YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    presenterView.running = NO;
#ifdef FULLSCREEN
    [fullScreenWindow orderOut:nil];
#endif
}


@end


























