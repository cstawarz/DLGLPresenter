//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import <AppKit/NSOpenGL.h>

#import "DLGLPresenterViewPrivate.h"
#import "DLGLViewPrivate.h"
#import "NSOpenGLView+DLGLPresenterAdditions.h"


@implementation DLGLMirrorView


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}


- (void)setSourceView:(DLGLPresenterView *)newSourceView
{
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:[self pixelFormat]
                                                          shareContext:[newSourceView openGLContext]];
    NSAssert(context, @"Could not create GL context for mirror view");

    [self setOpenGLContext:context];
    [context setView:self];
    
    if (self.sourceView) {
        [self.sourceView removeObserver:self forKeyPath:@"presenting"];
    }
    [newSourceView addObserver:self forKeyPath:@"presenting" options:0 context:NULL];
    
    _sourceView = newSourceView;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ((object == self.sourceView) && [keyPath isEqualToString:@"presenting"]) {
        if (self.sourceView.presenting) {
            [self startDisplayLink];
        } else {
            [self stopDisplayLink];
        }
    }
}


- (void)drawForTime:(const CVTimeStamp *)outputTime
{
    [[self openGLContext] makeCurrentContext];
    [self DLGLPerformBlockWithContextLock:^{
        [self drawFramebuffer:self.sourceView.sceneFramebuffer fromView:self.sourceView inView:self];
        glFlush();
    }];
}


@end


























