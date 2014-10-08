//
//  DLGLUtilities.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLUtilities.h"


void DLGLErrorBreak(GLenum error);


void _DLGLLogGLErrors(void)
{
    GLenum error;
    while (GL_NO_ERROR != (error = glGetError())) {
        DLGLErrorBreak(error);
    }
}


void DLGLErrorBreak(GLenum error)
{
    NSLog(@"GL error = 0x%04X (set a breakpoint in %s to debug)", error, __func__);
}


GLuint DLGLCreateShader(GLenum shaderType, const GLchar *shaderSource)
{
    GLuint shader = glCreateShader(shaderType);
    NSCAssert(shader, @"Shader creation failed (GL error = %d)", glGetError());
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint infoLogLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLog[infoLogLength];
        glGetShaderInfoLog(shader, infoLogLength, NULL, infoLog);
        NSLog(@"In %s: Shader compilation produced the following information log:\n%s", __func__, infoLog);
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
        NSLog(@"In %s: Program linking produced the following information log:\n%s", __func__, infoLog);
    }
    
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    NSCAssert((GL_TRUE == linkStatus), @"Program linking failed");
    
    return program;
}


ColorSyncTransformRef DLGLCreateColorSyncTransform(NSColorSpace *srcColorSpace, NSColorSpace *dstColorSpace)
{
    ColorSyncProfileRef srcProfile = [srcColorSpace colorSyncProfile];
    NSCAssert(srcProfile, @"Unable to obtain source ColorSync profile");
    
    ColorSyncProfileRef dstProfile = [dstColorSpace colorSyncProfile];
    NSCAssert(dstProfile, @"Unable to obtain destination ColorSync profile");
    
    const void *keys[] = { kColorSyncProfile, kColorSyncRenderingIntent, kColorSyncTransformTag };
    const void *srcVals[] = { srcProfile, kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformDeviceToPCS };
    const void *dstVals[] = { dstProfile, kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformPCSToDevice };
    
    CFDictionaryRef srcDict = CFDictionaryCreate(kCFAllocatorDefault,
                                                 keys,
                                                 srcVals,
                                                 3,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    
    CFDictionaryRef dstDict = CFDictionaryCreate(kCFAllocatorDefault,
                                                 keys,
                                                 dstVals,
                                                 3,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    
    const void *arrayVals[] = { srcDict, dstDict };
    CFArrayRef profileSequence = CFArrayCreate(kCFAllocatorDefault, arrayVals, 2, &kCFTypeArrayCallBacks);
    
    ColorSyncTransformRef transform = ColorSyncTransformCreate(profileSequence, NULL);
    NSCAssert(transform, @"Unable to create ColorSync transform");
    
    CFRelease(profileSequence);
    CFRelease(dstDict);
    CFRelease(srcDict);
    
    return transform;
}


























