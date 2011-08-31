//
//  HelloTriangle.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <DLGLPresenter/DLGLPresenterView.h>


@interface HelloTriangle : NSObject <DLGLPresenterDelegate> {
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
}

@end
