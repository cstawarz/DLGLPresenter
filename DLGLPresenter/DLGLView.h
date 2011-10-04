//
//  DLGLView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <OpenGL/gl3.h>


@interface DLGLView : NSOpenGLView

@property(nonatomic, readonly) GLsizei viewportWidth, viewportHeight;

- (void)performBlockOnGLContext:(dispatch_block_t)block;

@end
