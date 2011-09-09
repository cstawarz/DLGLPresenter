//
//  MovingTriangle.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "MovingTriangle.h"


@implementation MovingTriangle


static const float vertexPositions[] = {
    0.25f, 0.25f, 0.0f, 1.0f,
    0.25f, -0.25f, 0.0f, 1.0f,
    -0.25f, -0.25f, 0.0f, 1.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    NSURL *vertexShaderURL = [[NSBundle mainBundle] URLForResource:@"calcOffset" withExtension:@"vert"];
    NSAssert(vertexShaderURL, @"Cannot obtain URL for vertex shader");
    
    vertexShader = DLGLLoadShaderFromURL(GL_VERTEX_SHADER, vertexShaderURL, nil);
    NSAssert(vertexShader, @"Vertex shader creation failed");

    NSURL *fragmentShaderURL = [[NSBundle mainBundle] URLForResource:@"calcColor" withExtension:@"frag"];
    NSAssert(fragmentShaderURL, @"Cannot obtain URL for fragment shader");
    
    fragmentShader = DLGLLoadShaderFromURL(GL_FRAGMENT_SHADER, fragmentShaderURL, nil);
    NSAssert(fragmentShader, @"Fragment shader creation failed");
    
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    glUseProgram(program);
    
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STATIC_DRAW);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    GLint positionAttribLocation = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);
    
    timeUniformLocation = glGetUniformLocation(program, "time");
    startTime = 0ull;
    
    GLint loopDurationUniformLocation = glGetUniformLocation(program, "loopDuration");
    glUniform1f(loopDurationUniformLocation, 5.0f);
    
    GLint fragLoopDurationUniformLocation = glGetUniformLocation(program, "fragLoopDuration");
    glUniform1f(fragLoopDurationUniformLocation, 10.0f);
    
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glUseProgram(0);
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    if (!startTime) {
        startTime = DLGLConvertHostTimeToNanos(outputTime->hostTime);
    }
    uint64_t elapsedTime = DLGLConvertHostTimeToNanos(outputTime->hostTime) - startTime;
    glUniform1f(timeUniformLocation, (float)elapsedTime / 1.0e9f);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glBindVertexArray(0);
    glUseProgram(0);
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


























