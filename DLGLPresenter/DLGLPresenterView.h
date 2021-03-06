//
//  DLGLPresenterView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/NSScreen.h>
#import <AppKit/NSWindow.h>

#import <DLGLPresenter/DLGLView.h>


@protocol DLGLPresenterDelegate;  // Forward declaration


@interface DLGLPresenterView : DLGLView

@property(nonatomic, weak) id <DLGLPresenterDelegate> delegate;
@property(nonatomic, readonly) NSTimeInterval elapsedTime;

+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen;
+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen pixelFormat:(NSOpenGLPixelFormat *)format;

@end


@protocol DLGLPresenterDelegate <NSObject>

- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView;

- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime;
- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime;
- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime;

- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView;

- (void)presenterView:(DLGLPresenterView *)presenterView skippedFrames:(double)skippedFrameCount;

@end

























