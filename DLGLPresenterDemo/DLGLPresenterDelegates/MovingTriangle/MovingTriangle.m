//
//  MovingTriangle.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "MovingTriangle.h"


@implementation MovingTriangle
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint positionBufferObject;
    GLuint vertexArrayObject;
    
    GLint timeUniformLocation;
}


static const float vertexPositions[] = {
    0.25f, 0.25f, 0.0f, 1.0f,
    0.25f, -0.25f, 0.0f, 1.0f,
    -0.25f, -0.25f, 0.0f, 1.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = [self loadShader:GL_VERTEX_SHADER fromResource:@"calcOffset" withExtension:@"vert"];
    fragmentShader = [self loadShader:GL_FRAGMENT_SHADER fromResource:@"calcColor" withExtension:@"frag"];
    
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
    
    glUniform1f(timeUniformLocation, (float)(presenterView.elapsedTime) / 1.0e9f);
    
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


























