//
//  DLGLUtilities.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <OpenGL/gl3.h>


uint64_t DLGLConvertHostTimeToNanos(uint64_t hostTime);

GLuint DLGLLoadShaderFromURL(GLenum shaderType, NSURL *url, NSError **error);
GLuint DLGLCreateShader(GLenum shaderType, NSString *shaderSource);
GLuint DLGLCreateProgramWithShaders(GLuint shader, ...);

GLuint DLGLCreateTextureFromImage(GLenum target, NSImage *image);
