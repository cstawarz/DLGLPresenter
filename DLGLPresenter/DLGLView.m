//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"

#import <AppKit/NSOpenGL.h>
#import <AppKit/NSWindow.h>


@implementation DLGLView
{
    NSSet *supportedExtensions;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    if ((self = [super initWithFrame:frameRect pixelFormat:format])) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}


- (void)prepareOpenGL
{
    //
    // Determine supported extensions
    //
    
    GLint numExtensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
    NSMutableArray *extensionNames = [NSMutableArray arrayWithCapacity:numExtensions];
    
    for (GLuint i = 0; i < numExtensions; i++) {
        [extensionNames addObject:@((const char *)glGetStringi(GL_EXTENSIONS, i))];
    }
    
    supportedExtensions = [NSSet setWithArray:extensionNames];
}


- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    
    NSSize size = [self convertRectToBacking:[self bounds]].size;
    
    _viewportWidth = (GLsizei)(size.width);
    _viewportHeight = (GLsizei)(size.height);
    
    glViewport(0, 0, self.viewportWidth, self.viewportHeight);
}


- (BOOL)supportsExtension:(NSString *)name
{
    return [supportedExtensions containsObject:name];
}


- (void)drawFramebuffer:(GLuint)framebuffer fromView:(DLGLView *)sourceView inView:(DLGLView *)destView
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    GLenum drawBuffers[] = { GL_BACK_LEFT };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, sourceView.viewportWidth, sourceView.viewportHeight,
                      0, 0, destView.viewportWidth, destView.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}


@end




























