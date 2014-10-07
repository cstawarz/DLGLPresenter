//
//  DLGLView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/NSOpenGLView.h>
#import <OpenGL/gl3.h>


@interface DLGLView : NSOpenGLView

@property(nonatomic, readonly) GLsizei viewportWidth, viewportHeight;

- (BOOL)supportsExtension:(NSString *)name;
- (void)drawFramebuffer:(GLuint)framebuffer fromView:(DLGLView *)sourceView inView:(DLGLView *)destView;

@end
