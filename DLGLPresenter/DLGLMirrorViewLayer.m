//
//  DLGLMirrorViewLayer.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 10/10/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "DLGLMirrorViewLayer.h"

#import <AppKit/NSColor.h>
#import <AppKit/NSOpenGL.h>

#import "DLGLPresenterViewPrivate.h"
#import "DLGLUtilities.h"


@implementation DLGLMirrorViewLayer {
    DLGLPresenterView * __weak sourceView;
}


- (instancetype)initWithPresenterView:(DLGLPresenterView *)presenterView;
{
    self = [super init];
    
    if (self) {
        sourceView = presenterView;
        self.asynchronous = YES;
        self.backgroundColor = [[NSColor lightGrayColor] CGColor];
        self.opaque = YES;
    }
    
    return self;
}


- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    return CGLRetainPixelFormat([[sourceView pixelFormat] CGLPixelFormatObj]);
}


- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pixelFormat
{
    CGLContextObj ctx;
    CGLError error = CGLCreateContext(pixelFormat, [[sourceView openGLContext] CGLContextObj] , &ctx);
    
    NSAssert((kCGLNoError == error), @"Could not create GL context for mirror view (error = %d)", error);
    
    return ctx;
}


- (BOOL)canDrawInCGLContext:(CGLContextObj)glContext
                pixelFormat:(CGLPixelFormatObj)pixelFormat
               forLayerTime:(CFTimeInterval)timeInterval
                displayTime:(const CVTimeStamp *)timeStamp
{
    return (sourceView.running &&
            sourceView.viewportWidth != 0 &&
            sourceView.viewportHeight != 0);
}


- (void)drawInCGLContext:(CGLContextObj)glContext
             pixelFormat:(CGLPixelFormatObj)pixelFormat
            forLayerTime:(CFTimeInterval)timeInterval
             displayTime:(const CVTimeStamp *)timeStamp
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, sourceView.sceneFramebuffer);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    glBlitFramebuffer(0, 0, sourceView.viewportWidth, sourceView.viewportHeight,
                      0, 0, viewport[2], viewport[3],
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    
    DLGLLogGLErrors();
    
    [super drawInCGLContext:glContext pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];
}


@end


























