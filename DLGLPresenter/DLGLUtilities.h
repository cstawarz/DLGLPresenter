//
//  DLGLUtilities.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <OpenGL/gl3.h>

#if DEBUG
#define DLGLLogGLErrors() _DLGLLogGLErrors()
#else
#define DLGLLogGLErrors() do {} while (0)
#endif


void _DLGLLogGLErrors(void);

uint64_t DLGLConvertHostTimeToNanos(uint64_t hostTime);

GLuint DLGLCreateShader(GLenum shaderType, const GLchar *shaderSource);
GLuint DLGLCreateProgramWithShaders(GLuint shader, ...);
