//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import <AppKit/NSOpenGL.h>

#import "DLGLUtilities.h"
#import "NSOpenGLView+DLGLPresenterAdditions.h"


@interface DLGLMirrorView ()

- (void)prepareProgram;
- (void)prepareTextures;
- (void)allocateBufferStorage;
- (void)storeFrontBuffer;
- (void)drawStoredBuffer;
- (void)drawTexture:(GLuint)texture;

@end


@implementation DLGLMirrorView
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexPositionBufferObject, texCoordsBufferObject;
    GLuint vertexArrayObject;
    
    GLuint framebuffer;
    GLuint sourceTexture, mirrorTexture;
}


@synthesize sourceView;


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
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
    
    sourceView = newSourceView;
}


- (void)prepareOpenGL
{
    [self prepareProgram];
    glGenFramebuffers(1, &framebuffer);
    [self prepareTextures];
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


static const GLchar *vertexShaderSource =
"#version 150\n"
"in vec4 vertexPosition;\n"
"in vec2 texCoords;\n"
"smooth out vec2 varyingTexCoords;\n"
"void main()\n"
"{\n"
"   gl_Position = vertexPosition;\n"
"   varyingTexCoords = texCoords;\n"
"}\n";

static const GLchar *fragmentShaderSource =
"#version 150\n"
"uniform sampler2D colorMap;\n"
"in vec2 varyingTexCoords;\n"
"out vec4 fragColor;\n"
"void main()\n"
"{\n"
"   fragColor = texture(colorMap, varyingTexCoords);\n"
"}\n";

static const GLfloat vertexPosition[] = {
    -1.0f, -1.0f,
     1.0f, -1.0f,
    -1.0f,  1.0f,
     1.0f,  1.0f,
};

static const GLfloat texCoords[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};


- (void)prepareProgram
{
    vertexShader = DLGLCreateShader(GL_VERTEX_SHADER, vertexShaderSource);
    fragmentShader = DLGLCreateShader(GL_FRAGMENT_SHADER, fragmentShaderSource);
    
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    glUseProgram(program);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    glGenBuffers(1, &vertexPositionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexPositionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPosition), vertexPosition, GL_STATIC_DRAW);
    GLint vertexPositionAttribLocation = glGetAttribLocation(program, "vertexPosition");
    glEnableVertexAttribArray(vertexPositionAttribLocation);
    glVertexAttribPointer(vertexPositionAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    glGenBuffers(1, &texCoordsBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordsBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    GLint texCoordsAttribLocation = glGetAttribLocation(program, "texCoords");
    glEnableVertexAttribArray(texCoordsAttribLocation);
    glVertexAttribPointer(texCoordsAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    GLint colorMapUniformLocation = glGetUniformLocation(program, "colorMap");
    glUniform1i(colorMapUniformLocation, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}


- (void)prepareTextures
{
    glGenTextures(1, &sourceTexture);
    glBindTexture(GL_TEXTURE_2D, sourceTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glGenTextures(1, &mirrorTexture);
    glBindTexture(GL_TEXTURE_2D, mirrorTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)allocateBufferStorage
{
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    glBindTexture(GL_TEXTURE_2D, mirrorTexture);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 self.viewportWidth,
                 self.viewportHeight,
                 0,
                 GL_RGBA,
                 GL_FLOAT,
                 NULL);
    glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mirrorTexture, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
    NSAssert((GL_FRAMEBUFFER_COMPLETE == status), @"GL framebuffer is not complete (status = %d)", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
}


- (void)storeFrontBuffer
{
    glBindTexture(GL_TEXTURE_2D, sourceTexture);
    glReadBuffer(GL_FRONT_LEFT);
    
    glCopyTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA,
                     0,
                     0,
                     sourceView.viewportWidth,
                     sourceView.viewportHeight,
                     0);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
    GLenum drawBuffers[] = { GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(1, drawBuffers);
    
    glViewport(0, 0, self.viewportWidth, self.viewportHeight);
    [self drawTexture:sourceTexture];
    glViewport(0, 0, sourceView.viewportWidth, sourceView.viewportHeight);
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)drawStoredBuffer
{
    glBindTexture(GL_TEXTURE_2D, mirrorTexture);
    [self drawTexture:mirrorTexture];
    glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)drawTexture:(GLuint)texture
{
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
}


@end


























