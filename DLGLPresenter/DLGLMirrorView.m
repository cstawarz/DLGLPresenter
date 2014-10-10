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


- (void)setSourceView:(DLGLPresenterView *)newSourceView
{
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:[self pixelFormat]
                                                          shareContext:[newSourceView openGLContext]];
    NSAssert(context, @"Could not create GL context for mirror view");

    [self setOpenGLContext:context];
    [context setView:self];
    
    [self.sourceView removeObserver:self forKeyPath:@"running"];
    [newSourceView addObserver:self forKeyPath:@"running" options:0 context:NULL];
    
    _sourceView = newSourceView;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ((object == self.sourceView) && [keyPath isEqualToString:@"running"]) {
        self.running = self.sourceView.running;
    }
}


- (void)drawForTime:(const CVTimeStamp *)outputTime
{
    [self drawFramebuffer:self.sourceView.sceneFramebuffer fromView:self.sourceView inView:self];
    [[self openGLContext] flushBuffer];
}


- (void)dealloc
{
    [self.sourceView removeObserver:self forKeyPath:@"running"];
}


@end


























