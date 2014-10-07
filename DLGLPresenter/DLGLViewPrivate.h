//
//  DLGLViewPrivate.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 10/7/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "DLGLView.h"


@interface DLGLView ()

- (void)startDisplayLink;
- (void)stopDisplayLink;
- (void)drawForTime:(const CVTimeStamp *)outputTime;
- (void)drawFramebuffer:(GLuint)framebuffer fromView:(DLGLView *)sourceView inView:(DLGLView *)destView;

@end
