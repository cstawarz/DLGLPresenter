//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"

#import "DLGLUtilities.h"


@implementation DLGLView


@synthesize viewportWidth, viewportHeight;


- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (void)performBlockOnGLContext:(dispatch_block_t)block
{
    NSOpenGLContext *previousContext = [NSOpenGLContext currentContext];
    NSOpenGLContext *context = [self openGLContext];
    CGLContextObj contextObj = [context CGLContextObj];
    
    CGLError error = CGLLockContext(contextObj);
    NSAssert((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
    
    @try {
        if (previousContext != context) {
            [context makeCurrentContext];
        }
        
        block();
        DLGLLogErrors();
        
        if (previousContext && (previousContext != context)) {
            [previousContext makeCurrentContext];
        }
    }
    @finally {
        error = CGLUnlockContext(contextObj);
        NSAssert((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
    }
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        NSSize size = [self bounds].size;
        viewportWidth = (GLsizei)(size.width);
        viewportHeight = (GLsizei)(size.height);
        glViewport(0, 0, viewportWidth, viewportHeight);
    }];
}


- (void)update
{
    [self performBlockOnGLContext:^{
        [super update];
    }];
}


@end




























