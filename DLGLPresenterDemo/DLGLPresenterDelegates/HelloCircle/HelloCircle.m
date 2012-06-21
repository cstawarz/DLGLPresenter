//
//  HelloCircle.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 6/20/12.
//  Copyright (c) 2012 MIT. All rights reserved.
//

#import "HelloCircle.h"


@implementation HelloCircle
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint positionBufferObject;
    GLuint vertexArrayObject;
    
    GLint screenWidthUniformLocation;
    GLint screenHeightUniformLocation;
    
    BOOL didDraw;
}


static const float vertexPositions[] = {
     0.75f, -0.75f,
     0.75f,  0.75f,
    -0.75f, -0.75f,
    -0.75f,  0.75f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = [self loadShader:GL_VERTEX_SHADER fromResource:@"HelloCircle" withExtension:@"vert"];
    fragmentShader = [self loadShader:GL_FRAGMENT_SHADER fromResource:@"HelloCircle" withExtension:@"frag"];
    
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STATIC_DRAW);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    GLint positionAttribLocation = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    screenWidthUniformLocation = glGetUniformLocation(program, "screenWidth");
    screenHeightUniformLocation = glGetUniformLocation(program, "screenHeight");
    
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
    
    glClearColor(0.2f, 0.2f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    glUniform1f(screenWidthUniformLocation, (GLfloat)(presenterView.viewportWidth));
    glUniform1f(screenHeightUniformLocation, (GLfloat)(presenterView.viewportHeight));
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_BLEND);
    
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



























