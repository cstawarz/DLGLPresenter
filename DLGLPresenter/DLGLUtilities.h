//
//  DLGLUtilities.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gl3.h>

#if DEBUG
#define DLGLLogGLErrors() _DLGLLogGLErrors()
#else
#define DLGLLogGLErrors() do {} while (0)
#endif


void _DLGLLogGLErrors(void);

GLuint DLGLCreateShader(GLenum shaderType, const GLchar *shaderSource);
GLuint DLGLCreateProgramWithShaders(GLuint shader, ...);

NSTimeInterval DLGLGetTimeInterval(uint64_t startHostTime, uint64_t endHostTime);
