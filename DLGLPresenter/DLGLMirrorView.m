//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import "DLGLUtilities.h"

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

- (void)prepareForRendering;
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
    
    sourceView = newSourceView;
}


- (void)prepareOpenGL
{
    [self performBlockOnGLContext:^{
        [self prepareForRendering];
    }];
}


- (void)reshape
{
    [self performBlockOnGLContext:^{
        NSRect rect = [self bounds];
        mirrorWidth = (GLsizei)(rect.size.width);
        mirrorHeight = (GLsizei)(rect.size.height);
        
        glViewport(0, 0, mirrorWidth, mirrorHeight);
    }];
}


- (void)drawRect:(NSRect)dirtyRect
{
    [self performBlockOnGLContext:^{
        [self drawStoredBuffer];
        [[self openGLContext] flushBuffer];
    }];
}


static NSString *vertexShaderSource =
@"#version 150\n"
"in vec4 vertexPosition;\n"
"in vec2 texCoords;\n"
"smooth out vec2 varyingTexCoords;\n"
"void main()\n"
"{\n"
"   varyingTexCoords = texCoords;\n"
"   gl_Position = vertexPosition;\n"
"}\n";

static NSString *fragmentShaderSource =
@"#version 150\n"
"uniform sampler2D colorMap;\n"
"out vec4 fragColor;\n"
"in vec2 varyingTexCoords;\n"
"void main()\n"
"{\n"
"   fragColor = texture(colorMap, varyingTexCoords.st);\n"
"}\n";

static const GLfloat vertexPosition[] = {
     1.0f,  1.0f, 0.0f, 1.0f,
    -1.0f, -1.0f, 0.0f, 1.0f,
     1.0f, -1.0f, 0.0f, 1.0f,
    
     1.0f,  1.0f, 0.0f, 1.0f,
    -1.0f,  1.0f, 0.0f, 1.0f,
    -1.0f, -1.0f, 0.0f, 1.0f,
};

static const GLfloat texCoords[] = {
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
    
    1.0f, 1.0f,
    0.0f, 1.0f,
    0.0f, 0.0f,
};


- (void)prepareForRendering
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
    glVertexAttribPointer(vertexPositionAttribLocation, 4, GL_FLOAT, GL_FALSE, 0, 0);
    
    glGenBuffers(1, &texCoordsBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordsBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    GLint texCoordsAttribLocation = glGetAttribLocation(program, "texCoords");
    glEnableVertexAttribArray(texCoordsAttribLocation);
    glVertexAttribPointer(texCoordsAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    GLint colorMapUniformLocation = glGetUniformLocation(program, "colorMap");
    glUniform1i(colorMapUniformLocation, 0);
    
    glGenTextures(1, &texture);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}


- (void)storeFrontBuffer
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glReadBuffer(GL_FRONT_LEFT);
    
    NSSize sourceSize = [sourceView bounds].size;
    glCopyTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA,
                     0,
                     0,
                     (GLsizei)(sourceSize.width),
                     (GLsizei)(sourceSize.height),
                     0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)drawStoredBuffer
{
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}


@end


























