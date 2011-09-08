//
//  HelloTriangle.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "HelloTriangle.h"


@implementation HelloTriangle


static NSString *vertexShaderSource =
@"#version 150\n"
"in vec4 position;\n"
"void main()\n"
"{\n"
"   gl_Position = position;\n"
"}\n";

static NSString *fragmentShaderSource =
@"#version 150\n"
"out vec4 outputColor;\n"
"void main()\n"
"{\n"
"   outputColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);\n"
"}\n";

static const float vertexPositions[] = {
    0.75f, 0.75f, 0.0f, 1.0f,
    0.75f, -0.75f, 0.0f, 1.0f,
    -0.75f, -0.75f, 0.0f, 1.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = DLGLCreateShader(GL_VERTEX_SHADER, vertexShaderSource);
    fragmentShader = DLGLCreateShader(GL_FRAGMENT_SHADER, fragmentShaderSource);
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STATIC_DRAW);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    GLint positionAttribLocation = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    didDraw = NO;
}


- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime
{
    return !didDraw;
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    NSLog(@"Drawing in %s", __PRETTY_FUNCTION__);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glBindVertexArray(0);
    glUseProgram(0);
}


- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime
{
    didDraw = YES;
}


- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView
{
    glDeleteVertexArrays(1, &vertexArrayObject);
    glDeleteBuffers(1, &positionBufferObject);
    
    glDeleteProgram(program);
    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);
}


@end



























