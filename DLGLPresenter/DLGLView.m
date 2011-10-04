//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"


@implementation DLGLView


@synthesize viewportWidth, viewportHeight;


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFAMinimumPolicy,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAMultisample,
        NSOpenGLPFASampleBuffers, 1,
        NSOpenGLPFASamples, 4,
        NSOpenGLPFASampleAlpha,
        0
    };
    
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}


- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (void)performBlockOnGLContext:(dispatch_block_t)block
{
    NSOpenGLContext *context = [self openGLContext];
    CGLContextObj contextObj = [context CGLContextObj];
    
    CGLError error = CGLLockContext(contextObj);
    NSAssert1((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
    
    @try {
        [context makeCurrentContext];
        block();
    }
    @finally {
        error = CGLUnlockContext(contextObj);
        NSAssert1((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
    }
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        NSRect rect = [self bounds];
        viewportWidth = (GLsizei)(rect.size.width);
        viewportHeight = (GLsizei)(rect.size.height);
        
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




























