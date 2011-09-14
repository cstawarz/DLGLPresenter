//
//  DLGLPresenterView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <CoreVideo/CVDisplayLink.h>


@protocol DLGLPresenterDelegate;  // Forward declaration


@interface DLGLPresenterView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    uint64_t startHostTime, currentHostTime;
    int64_t previousVideoTime;
    BOOL shouldDraw;
}

@property(nonatomic, assign) id <DLGLPresenterDelegate> delegate;
@property(nonatomic, assign, getter=isPresenting) BOOL presenting;
@property(nonatomic, readonly) uint64_t elapsedTime;

+ (NSWindow *)presenterViewInFullScreenWindow:(NSScreen *)screen;

- (void)performBlockOnGLContext:(dispatch_block_t)block;

@end


@protocol DLGLPresenterDelegate <NSObject>

@optional
- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView;
- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime;

@required
- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime;

@optional
- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime;
- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView;

@optional
- (void)presenterView:(DLGLPresenterView *)presenterView skippedFrames:(double)skippedFrameCount;

@end

























