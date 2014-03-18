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

#import "DLGLUtilities.h"


@implementation DLGLView
{
    NSSet *supportedExtensions;
    
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexPositionBufferObject, texCoordsBufferObject;
    GLuint vertexArrayObject;
    
    GLuint colorConversionLUT;
}


- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    if ((self = [super initWithFrame:frameRect pixelFormat:format])) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
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

"uniform sampler2D inputTexture;\n"
"uniform sampler3D colorLUT;\n"
"uniform float colorScale;\n"
"uniform float colorOffset;\n"

"in vec2 varyingTexCoords;\n"

"out vec4 fragColor;\n"

"void main()\n"
"{\n"
"   vec4 rawColor = texture(inputTexture, varyingTexCoords);\n"
"   fragColor.rgb = texture(colorLUT, rawColor.rgb * colorScale + colorOffset).rgb;\n"
"   fragColor.a = rawColor.a;\n"
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


- (void)prepareOpenGL
{
    //
    // Determine supported extensions
    //
    
    GLint numExtensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
    NSMutableArray *extensionNames = [NSMutableArray arrayWithCapacity:numExtensions];
    
    for (GLuint i = 0; i < numExtensions; i++) {
        [extensionNames addObject:[NSString stringWithUTF8String:(const char *)glGetStringi(GL_EXTENSIONS, i)]];
    }
    
    supportedExtensions = [NSSet setWithArray:extensionNames];
    
    //
    // Prepare program
    //
    
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
    
    glUniform1i(glGetUniformLocation(program, "inputTexture"), 0);
    glUniform1i(glGetUniformLocation(program, "colorLUT"), 1);
    
    static const GLint numGridPoints = 32;
    glUniform1f(glGetUniformLocation(program, "colorScale"), ((GLfloat)numGridPoints - 1.0f) / (GLfloat)numGridPoints);
    glUniform1f(glGetUniformLocation(program, "colorOffset"), 1.0f / (2.0f * (GLfloat)numGridPoints));
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
    
    //
    // Create color conversion lookup table
    //
    
    ColorSyncTransformRef transform = DLGLCreateColorSyncTransform([NSColorSpace sRGBColorSpace],
                                                                   [[self window] colorSpace]);
    
    NSDictionary *options =
        @{ (__bridge NSString *)kColorSyncConversionGridPoints: [NSNumber numberWithInt:numGridPoints] };
    NSArray *properties = (__bridge_transfer NSArray *)
        ColorSyncTransformCopyProperty(transform,
                                       kColorSyncTransformSimplifiedConversionData,
                                       (__bridge CFDictionaryRef)options);
    NSData *colorConversionLUTData =
        [(NSDictionary *)[properties firstObject] objectForKey:(__bridge NSString *)kColorSyncConversion3DLut];
    NSAssert(colorConversionLUTData, @"Unable to obtain color conversion lookup table data");
    
    glGenTextures(1, &colorConversionLUT);
    glBindTexture(GL_TEXTURE_3D, colorConversionLUT);
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, numGridPoints);
    glPixelStorei(GL_UNPACK_IMAGE_HEIGHT, numGridPoints);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage3D(GL_TEXTURE_3D,
                 0,
                 GL_RGB16,
                 numGridPoints,
                 numGridPoints,
                 numGridPoints,
                 0,
                 GL_BGR,
                 GL_UNSIGNED_SHORT,
                 [colorConversionLUTData bytes]);
    
    glBindTexture(GL_TEXTURE_3D, 0);
    
    CFRelease(transform);
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


- (void)drawTextureWithColorMatching:(GLuint)texture
{
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    glBindTexture(GL_TEXTURE_2D, texture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_3D, colorConversionLUT);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindTexture(GL_TEXTURE_3D, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glBindVertexArray(0);
    glUseProgram(0);
}


@end




























