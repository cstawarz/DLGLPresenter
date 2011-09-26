//
//  DLGLView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface DLGLView : NSOpenGLView

- (void)performBlockOnGLContext:(dispatch_block_t)block;

@end
