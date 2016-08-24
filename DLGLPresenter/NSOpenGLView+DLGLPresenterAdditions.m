//
//  NSOpenGLView+DLGLPresenterAdditions.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 5/2/12.
//  Copyright (c) 2012 MIT. All rights reserved.
//

#import "NSOpenGLView+DLGLPresenterAdditions.h"

#import <AppKit/NSOpenGL.h>
#import <OpenGL/OpenGL.h>


@implementation NSOpenGLView (DLGLPresenterAdditions)


- (void)DLGLPerformBlockWithContextLock:(dispatch_block_t)block
{
    CGLContextObj contextObj = self.openGLContext.CGLContextObj;
    CGLError error = CGLLockContext(contextObj);
    NSAssert((kCGLNoError == error), @"Unable to acquire GL context lock (error = %d)", error);
    
    @try {
        block();
    }
    @finally {
        error = CGLUnlockContext(contextObj);
        NSAssert((kCGLNoError == error), @"Unable to release GL context lock (error = %d)", error);
    }
}


@end
