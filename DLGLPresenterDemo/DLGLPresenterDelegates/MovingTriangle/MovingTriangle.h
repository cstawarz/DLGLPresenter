//
//  MovingTriangle.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/8/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <DLGLPresenter/DLGLPresenter.h>


@interface MovingTriangle : NSObject <DLGLPresenterDelegate> {
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint positionBufferObject;
    GLuint vertexArrayObject;
    
    GLint timeUniformLocation;
}

@end
