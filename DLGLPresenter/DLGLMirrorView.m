//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import <AppKit/NSOpenGL.h>
#import <QuartzCore/CAOpenGLLayer.h>

#import "DLGLPresenterViewPrivate.h"
#import "DLGLUtilities.h"


@interface DLGLMirrorViewLayer : CAOpenGLLayer

@property(nonatomic, weak) DLGLPresenterView *sourceView;

@end


@implementation DLGLMirrorViewLayer


- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.asynchronous = YES;
        self.opaque = YES;
    }
    
    return self;
}


- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    
    return CGLRetainPixelFormat([pixelFormat CGLPixelFormatObj]);
}


- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pixelFormat
{
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:[[NSOpenGLPixelFormat alloc]
                                                                        initWithCGLPixelFormatObj:pixelFormat]
                                                          shareContext:[self.sourceView openGLContext]];
    NSAssert(context, @"Could not create GL context for mirror view");
    
    return CGLRetainContext([context CGLContextObj]);
}


- (void)drawInCGLContext:(CGLContextObj)glContext
             pixelFormat:(CGLPixelFormatObj)pixelFormat
            forLayerTime:(CFTimeInterval)timeInterval
             displayTime:(const CVTimeStamp *)timeStamp
{
    if (!(self.sourceView.running) ||
        self.sourceView.viewportWidth == 0 ||
        self.sourceView.viewportHeight == 0)
    {
        
        glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
    } else {
        
        glBindFramebuffer(GL_READ_FRAMEBUFFER, self.sourceView.sceneFramebuffer);
        glReadBuffer(GL_COLOR_ATTACHMENT0);
        
        GLint viewport[4];
        glGetIntegerv(GL_VIEWPORT, viewport);
        
        glBlitFramebuffer(0, 0, self.sourceView.viewportWidth, self.sourceView.viewportHeight,
                          0, 0, viewport[2], viewport[3],
                          GL_COLOR_BUFFER_BIT,
                          GL_LINEAR);
        
        glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    }
    
    DLGLLogGLErrors();
    
    [super drawInCGLContext:glContext pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];
}


@end


@implementation DLGLMirrorView


- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        [self setWantsLayer:YES];
    }
    
    return self;
}


- (CALayer *)makeBackingLayer
{
    return [DLGLMirrorViewLayer layer];
}


- (void)setSourceView:(DLGLPresenterView *)newSourceView
{
    ((DLGLMirrorViewLayer *)[self layer]).sourceView = newSourceView;
    _sourceView = newSourceView;
}


@end


























