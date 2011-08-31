//
//  DLGLPresenterDemoAppDelegate.m
//  DLGLPresenterDemo
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterDemoAppDelegate.h"

#import "ScreenFlicker.h"


@implementation DLGLPresenterDemoAppDelegate


@synthesize window;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    presenterDelegate = [[ScreenFlicker alloc] init];
    
    presenterView = [[DLGLPresenterView alloc] initWithFrame:[window frame]];
    presenterView.delegate = presenterDelegate;
    
    [window setContentView:presenterView];
    
    [presenterView startPresentation];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [presenterView stopPresentation];
}


- (void)dealloc
{
    [presenterView release];
    [presenterDelegate release];
    [super dealloc];
}


@end


























