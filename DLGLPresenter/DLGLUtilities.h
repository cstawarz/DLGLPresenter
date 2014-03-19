//
//  DLGLUtilities.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/NSColorSpace.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import <OpenGL/gl3.h>

#if DEBUG
#define DLGLLogGLErrors() _DLGLLogGLErrors()
#else
#define DLGLLogGLErrors() do {} while (0)
#endif

#define DLGL_SHADER_SOURCE(...) "#version 150\n" #__VA_ARGS__


void _DLGLLogGLErrors(void);

GLuint DLGLCreateShader(GLenum shaderType, const GLchar *shaderSource);
GLuint DLGLCreateProgramWithShaders(GLuint shader, ...);

ColorSyncTransformRef DLGLCreateColorSyncTransform(NSColorSpace *srcColorSpace, NSColorSpace *dstColorSpace);

NSTimeInterval DLGLGetTimeInterval(uint64_t startHostTime, uint64_t endHostTime);
