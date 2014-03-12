//
//  HelloImage.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 3/10/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "HelloImage.h"


@implementation HelloImage
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexArrayObject;
    GLuint vertexPositionBufferObject;
    GLuint texCoordsBufferObject;
    
    GLuint texture;
    
    BOOL didDraw;
}


static const GLfloat vertexPosition[] = {
    -0.75f, -0.75f,
     0.75f, -0.75f,
     0.75f,  0.75f,
    -0.75f,  0.75f,
};


static const GLfloat texCoords[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    1.0f, 0.0f,
    0.0f, 0.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = [self loadShader:GL_VERTEX_SHADER fromResource:@"HelloImage" withExtension:@"vert"];
    fragmentShader = [self loadShader:GL_FRAGMENT_SHADER fromResource:@"HelloImage" withExtension:@"frag"];
    
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
    
    //NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"car" withExtension:@"jpg"];
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"grayscale_gradient" withExtension:@"png"];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, NULL);
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    size_t imageWidth = CGImageGetWidth(image);
    size_t imageHeight = CGImageGetHeight(image);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       imageWidth,
                                                       imageHeight,
                                                       8,
                                                       imageWidth * 4,
                                                       colorSpace,
                                                       kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    
    CGContextSetBlendMode(bitmapContext, kCGBlendModeCopy);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)imageWidth);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_SRGB8_ALPHA8,
                 (GLsizei)imageWidth,
                 (GLsizei)imageHeight,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8_REV,
                 CGBitmapContextGetData(bitmapContext));
    
    // NOTE: Because the image is both premultiplied and stored in sRGB format, blending is going to be
    // incorrect for images with translucency:  The source components are multiplied with the source alpha
    // *before* converting from sRGB to linear, whereas they should be multiplied after.  If we want to fix
    // this, we'll need to either undo the premultiplication or store the image in a linear color space.  (The
    // latter will require more than 8 bits per channel in order to avoid banding.)
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(image);
    CFRelease(imageSource);
    
    didDraw = NO;
}


- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime
{
    return !didDraw;
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    NSLog(@"Drawing in %s", __PRETTY_FUNCTION__);
    
    glEnable(GL_FRAMEBUFFER_SRGB);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
    glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
    glEnable(GL_BLEND);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisable(GL_BLEND);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
    glUseProgram(0);
    
    glDisable(GL_FRAMEBUFFER_SRGB);
}


- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime
{
    didDraw = YES;
}


- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView
{
    glDeleteTextures(1, &texture);
    
    glDeleteBuffers(1, &texCoordsBufferObject);
    glDeleteBuffers(1, &vertexPositionBufferObject);
    glDeleteVertexArrays(1, &vertexArrayObject);
    
    glDeleteProgram(program);
    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);
}


@end



























