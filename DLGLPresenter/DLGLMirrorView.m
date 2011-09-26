//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#define MIRROR_UPDATE_INTERVAL  (33ull * NSEC_PER_MSEC)  // Update ~30 times per second
#define MIRROR_UPDATE_LEEWAY    ( 5ull * NSEC_PER_MSEC)  // with a leeway of 5ms


static void checkGLError(const char *msg)
{
    GLenum error = glGetError();
    if (GL_NO_ERROR != error) {
        NSLog(@"%s: GL error = 0x%X", msg, error);
    }
}


@interface DLGLMirrorView ()

- (void)allocateBufferStorage;
- (void)storeFrontBuffer;
- (void)drawStoredBuffer;

@end


@implementation DLGLMirrorView


@synthesize sourceView;


- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
    if ((self = [super initWithFrame:frameRect pixelFormat:pixelFormat])) {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        NSAssert(timer, @"Unable to create dispatch timer");
        
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, MIRROR_UPDATE_INTERVAL, MIRROR_UPDATE_LEEWAY);
        
        dispatch_source_set_event_handler(timer, ^{
            if (self.sourceView) {
                [self.sourceView performBlockOnGLContext:^{ [self storeFrontBuffer]; }];
                [self setNeedsDisplay:YES];
            }
        });
        
        dispatch_resume(timer);
    }
    
    return self;
}


- (void)setSourceView:(DLGLView *)newSourceView
{
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:[self pixelFormat]
                                                          shareContext:[newSourceView openGLContext]];
    NSAssert(context, @"Could not create GL context for mirror view");

    [self setOpenGLContext:context];
    [context setView:self];
    [context release];
    
    [self performBlockOnGLContext:^{ [self allocateBufferStorage]; }];
    
    sourceView = newSourceView;
}


- (void)prepareOpenGL
{
    [self performBlockOnGLContext:^{
        glGenFramebuffers(1, &framebuffer);
        glGenRenderbuffers(1, &renderbuffer);
    }];
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        NSRect rect = [self bounds];
        mirrorWidth = (GLsizei)(rect.size.width);
        mirrorHeight = (GLsizei)(rect.size.height);
        
        glViewport(0, 0, mirrorWidth, mirrorHeight);
        
        [self allocateBufferStorage];  // Resize the renderbuffer
    }];
}


- (void)drawRect:(NSRect)dirtyRect
{
    [self performBlockOnGLContext:^{
        [self drawStoredBuffer];
        [[self openGLContext] flushBuffer];
    }];
}


- (void)allocateBufferStorage
{
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, mirrorWidth, mirrorHeight);  // Deletes any existing storage
    glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
    NSAssert1((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
    
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
    
    NSSize sourceSize = [sourceView bounds].size;
    glBlitFramebuffer(0, 0, (GLsizei)(sourceSize.width), (GLsizei)(sourceSize.height),
                      0, 0, mirrorWidth, mirrorHeight,
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
    
    glBlitFramebuffer(0, 0, mirrorWidth, mirrorHeight,
                      0, 0, mirrorWidth, mirrorHeight,
                      GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
}


@end


























