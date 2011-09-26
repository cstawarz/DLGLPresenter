//
//  DLGLPresenterMirrorView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <OpenGL/gl3.h>

#import <DLGLPresenter/DLGLView.h>


@interface DLGLMirrorView : DLGLView {
    dispatch_source_t timer;
    
    GLuint framebuffer, renderbuffer;
    GLsizei mirrorWidth, mirrorHeight;
}

@property(nonatomic, assign) DLGLView *sourceView;

@end