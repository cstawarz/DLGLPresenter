//
//  DLGLPresenterDemoAppDelegate.m
//  DLGLPresenterDemo
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLPresenterDemoAppDelegate.h"


@implementation DLGLPresenterDemoAppDelegate


@synthesize window;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    presenterView = [[DLGLPresenterView alloc] initWithFrame:[window frame]];
    [window setContentView:presenterView];
}


- (void)dealloc
{
    [presenterView release];
    [super dealloc];
}


@end
