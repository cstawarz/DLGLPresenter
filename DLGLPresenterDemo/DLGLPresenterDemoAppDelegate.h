//
//  DLGLPresenterDemoAppDelegate.h
//  DLGLPresenterDemo
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <DLGLPresenter/DLGLPresenter.h>


@interface DLGLPresenterDemoAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSWindow *fullScreenWindow;
    DLGLPresenterView *presenterView;
    DLGLMirrorView *mirrorView;
    id <DLGLPresenterDelegate> presenterDelegate;
}

@property (assign) IBOutlet NSWindow *window;

@end
