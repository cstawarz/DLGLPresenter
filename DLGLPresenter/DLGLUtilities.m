//
//  DLGLUtilities.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLUtilities.h"


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


























