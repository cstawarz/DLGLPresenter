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
}

@property(nonatomic, assign) id <DLGLPresenterDelegate> delegate;

- (void)startPresentation;
- (void)stopPresentation;

@end


@protocol DLGLPresenterDelegate <NSObject>

- (void)presenterView:(DLGLPresenterView *)presenterView willPresentFrameForTime:(const CVTimeStamp *)outputTime;

@optional
- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldPresentFrameForTime:(const CVTimeStamp *)outputTime;
- (void)presenterView:(DLGLPresenterView *)presenterView didPresentFrameForTime:(const CVTimeStamp *)outputTime;

@end
