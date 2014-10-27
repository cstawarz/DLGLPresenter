//
//  RefreshTally.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 10/27/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "RefreshTally.h"

#define TALLY_WIDTH  40
#define TALLY_HEIGHT 25
#define COUNTER_MAX  (TALLY_WIDTH * TALLY_HEIGHT)


@implementation RefreshTally {
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexPositionBufferObject;
    GLuint vertexArrayObject;
    
    GLint xMinUniformLocation;
    GLint xMaxUniformLocation;
    GLint yMinUniformLocation;
    GLint yMaxUniformLocation;
    
    int counter;
    int64_t previousVideoTime;
}


static const GLfloat vertexPosition[] = {
    -1.0f, -1.0f,
     1.0f, -1.0f,
    -1.0f,  1.0f,
     1.0f,  1.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = [self loadShader:GL_VERTEX_SHADER fromResource:@"RefreshTally" withExtension:@"vert"];
    fragmentShader = [self loadShader:GL_FRAGMENT_SHADER fromResource:@"RefreshTally" withExtension:@"frag"];
    
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    glUseProgram(program);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    glGenBuffers(1, &vertexPositionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexPositionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPosition), vertexPosition, GL_STATIC_DRAW);
    GLint vertexPositionAttribLocation = glGetAttribLocation(program, "vertexPosition");
    glEnableVertexAttribArray(vertexPositionAttribLocation);
    glVertexAttribPointer(vertexPositionAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    xMinUniformLocation = glGetUniformLocation(program, "xMin");
    xMaxUniformLocation = glGetUniformLocation(program, "xMax");
    yMinUniformLocation = glGetUniformLocation(program, "yMin");
    yMaxUniformLocation = glGetUniformLocation(program, "yMax");
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
    
    counter = COUNTER_MAX;
    previousVideoTime = 0;
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    if (previousVideoTime) {
        int64_t delta = outputTime->videoTime - previousVideoTime;
        counter += round((double)delta / (double)(outputTime->videoRefreshPeriod));
    }
    
    if (counter >= COUNTER_MAX) {
        glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        counter = 0;
    }
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    
    {
        int row = counter / TALLY_HEIGHT;
        int col = counter % TALLY_HEIGHT;
        
        GLfloat deltaRow = 2.0f / (GLfloat)TALLY_WIDTH;
        GLfloat deltaCol = 2.0f / (GLfloat)TALLY_HEIGHT;
        
        glUniform1f(xMinUniformLocation, -1.0f + col*deltaCol);
        glUniform1f(xMaxUniformLocation, -1.0f + (col + 1)*deltaCol);
        glUniform1f(yMaxUniformLocation,  1.0f - row*deltaRow);
        glUniform1f(yMinUniformLocation,  1.0f - (row + 1)*deltaRow);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
    
    previousVideoTime = outputTime->videoTime;
}


- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView
{
    glDeleteBuffers(1, &vertexPositionBufferObject);
    glDeleteVertexArrays(1, &vertexArrayObject);
    
    glDeleteProgram(program);
    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);
}


@end



























