//
//  NSOpenGLView+DLGLPresenterAdditions.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 5/2/12.
//  Copyright (c) 2012 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSOpenGLView (DLGLPresenterAdditions)

- (void)DLGLPerformBlockWithContextLock:(dispatch_block_t)block;

@end
