//
//  DLGLUtilities.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLUtilities.h"

#import <CoreAudio/HostTime.h>


uint64_t DLGLConvertHostTimeToNanos(uint64_t hostTime)
{
    return AudioConvertHostTimeToNanos(hostTime);
}


GLuint DLGLLoadShaderFromURL(GLenum shaderType, NSURL *url, NSError **error)
{
    GLuint shader = 0;
    
    NSStringEncoding encoding;
    NSString *shaderSource = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:error];
    
    if (shaderSource) {
        shader = DLGLCreateShader(shaderType, shaderSource);
    }
    
    return shader;
}


GLuint DLGLCreateShader(GLenum shaderType, NSString *shaderSource)
{
    GLuint shader = glCreateShader(shaderType);
    NSCAssert1(shader, @"Shader creation failed (GL error = %d)", glGetError());
    
    const char *shaderSourceUTF8 = [shaderSource UTF8String];
    glShaderSource(shader, 1, &shaderSourceUTF8, NULL);
    
    glCompileShader(shader);
    
    GLint infoLogLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLog[infoLogLength];
        glGetShaderInfoLog(shader, infoLogLength, NULL, infoLog);
        NSLog(@"In %s: Shader compilation produced the following information log:\n%s", __PRETTY_FUNCTION__, infoLog);
    }
    
    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    NSCAssert((GL_TRUE == compileStatus), @"Shader compilation failed");
    
    return shader;
}


GLuint DLGLCreateProgramWithShaders(GLuint shader, ...)
{
    GLuint program = glCreateProgram();
    NSCAssert(program, @"Program creation failed");
    
    va_list shaderList;
    va_start(shaderList, shader);
    
    while (shader) {
        glAttachShader(program, shader);
        shader = va_arg(shaderList, GLuint);
    }
    
    va_end(shaderList);
    
    glLinkProgram(program);
    
    GLint infoLogLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLog[infoLogLength];
        glGetProgramInfoLog(program, infoLogLength, NULL, infoLog);
        NSLog(@"In %s: Program linking produced the following information log:\n%s", __PRETTY_FUNCTION__, infoLog);
    }
    
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    NSCAssert((GL_TRUE == linkStatus), @"Program linking failed");
    
    return program;
}


GLuint DLGLCreateTextureFromImage(GLenum target, NSImage *image)
{
    NSRect imageRect;
    imageRect.origin = NSZeroPoint;
    imageRect.size = [image size];
    
    [image lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:imageRect];
    [image unlockFocus];
    
    GLint samplesPerPixel = (GLint)[bitmap samplesPerPixel];
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)[bitmap bytesPerRow] / samplesPerPixel);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(target, texture);
    
    NSCAssert((![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4)), @"Unsupported bitmap data");
    
    glTexImage2D(target,
                 0,
                 samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                 (GLsizei)[bitmap pixelsWide],
                 (GLsizei)[bitmap pixelsHigh],
                 0,
                 samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                 GL_UNSIGNED_BYTE,
                 [bitmap bitmapData]);
    
    glBindTexture(target, 0);
    [bitmap release];
    
    return texture;
}


























