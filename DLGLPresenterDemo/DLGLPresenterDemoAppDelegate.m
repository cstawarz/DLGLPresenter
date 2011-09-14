//
//  DLGLPresenterDemoAppDelegate.m
//  DLGLPresenterDemo
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterDemoAppDelegate.h"

#import "ScreenFlicker.h"
#import "HelloTriangle.h"
#import "MovingTriangle.h"

#define FULLSCREEN


@implementation DLGLPresenterDemoAppDelegate


@synthesize window;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    presenterDelegate = [[MovingTriangle alloc] init];
    
#ifdef FULLSCREEN
    fullScreenWindow = [[DLGLPresenterView presenterViewInFullScreenWindow:[[NSScreen screens] lastObject]] retain];
    presenterView = [fullScreenWindow contentView];
#else
    presenterView = [[DLGLPresenterView alloc] initWithFrame:[window frame]];
#endif
    presenterView.delegate = presenterDelegate;
    
#ifdef FULLSCREEN
    [fullScreenWindow makeKeyAndOrderFront:self];
#else
    [window setContentView:presenterView];
#endif
    
    presenterView.presenting = YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    presenterView.presenting = NO;
#ifdef FULLSCREEN
    [fullScreenWindow orderOut:nil];
#endif
}


- (void)dealloc
{
#ifdef FULLSCREEN
    [fullScreenWindow release];
#else
    [presenterView release];
#endif
    [presenterDelegate release];
    [super dealloc];
}


@end


























