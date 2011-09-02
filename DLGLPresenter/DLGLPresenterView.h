//
//  DLGLPresenterView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <CoreVideo/CVDisplayLink.h>
#import <OpenGL/gl3.h>


@protocol DLGLPresenterDelegate;  // Forward declaration


@interface DLGLPresenterView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    int64_t previousVideoTime;
    BOOL shouldDraw;
}

@property(nonatomic, assign) id <DLGLPresenterDelegate> delegate;

- (void)startPresentation;
- (void)stopPresentation;

- (GLuint)loadShader:(GLenum)shaderType fromURL:(NSURL *)url error:(NSError **)error;
- (GLuint)createShader:(GLenum)shaderType withSource:(NSString *)shaderSource;
- (GLuint)createProgramWithShaders:(GLuint)shader, ...;

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

























