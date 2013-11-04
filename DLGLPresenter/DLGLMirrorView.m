//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import <AppKit/NSOpenGL.h>

#import "NSOpenGLView+DLGLPresenterAdditions.h"


@implementation DLGLMirrorView
{
    GLuint framebuffer, renderbuffer;
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAMinimumPolicy,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        0
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}


- (void)setSourceView:(DLGLPresenterView *)newSourceView
{
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:[self pixelFormat]
                                                          shareContext:[newSourceView openGLContext]];
    NSAssert(context, @"Could not create GL context for mirror view");

    [self setOpenGLContext:context];
    [context setView:self];
    
    _sourceView = newSourceView;
}


- (void)prepareOpenGL
{
    glGenFramebuffers(1, &framebuffer);
    glGenRenderbuffers(1, &renderbuffer);
    glFlush();
}


- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    [self updateViewport];
    [self allocateBufferStorage];
    glFlush();
}


- (void)drawRect:(NSRect)dirtyRect
{
    [[self.sourceView openGLContext] makeCurrentContext];
    [self.sourceView DLGLPerformBlockWithContextLock:^{
        [self storeFrontBuffer];
        glFlush();
    }];
    
    [[self openGLContext] makeCurrentContext];
    [self drawStoredBuffer];
    glFlush();
}


- (void)allocateBufferStorage
{
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, self.viewportWidth, self.viewportHeight);
    glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
    NSAssert((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
}


- (void)storeFrontBuffer
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    glReadBuffer(GL_FRONT_LEFT);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    GLenum drawBuffers[] = { GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, self.sourceView.viewportWidth, self.sourceView.viewportHeight,
                      0, 0, self.viewportWidth, self.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
}


- (void)drawStoredBuffer
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    GLenum drawBuffers[] = { GL_BACK_LEFT };
    glDrawBuffers(1, drawBuffers);
    
    glBlitFramebuffer(0, 0, self.viewportWidth, self.viewportHeight,
                      0, 0, self.viewportWidth, self.viewportHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}


@end


























