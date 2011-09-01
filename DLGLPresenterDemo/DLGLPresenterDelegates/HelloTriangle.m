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
    vertexShader = [presenterView createShader:GL_VERTEX_SHADER withSource:vertexShaderSource];
    fragmentShader = [presenterView createShader:GL_FRAGMENT_SHADER withSource:fragmentShaderSource];
    program = [presenterView createProgramFromShaders:vertexShader, fragmentShader, 0];
    
    positionAttribLocation = glGetAttribLocation(program, "position");
    
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
}


- (void)presenterView:(DLGLPresenterView *)presenterView willPresentFrameForTime:(const CVTimeStamp *)outputTime
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glEnableVertexAttribArray(positionAttribLocation);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glDisableVertexAttribArray(positionAttribLocation);
    glUseProgram(0);
}


@end



























