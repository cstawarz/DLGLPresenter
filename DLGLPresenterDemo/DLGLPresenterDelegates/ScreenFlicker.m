//
//  ScreenFlicker.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "ScreenFlicker.h"

#import <OpenGL/gl3.h>


@implementation ScreenFlicker


- (void)presenterView:(DLGLPresenterView *)presenterView willPresentFrameForTime:(const CVTimeStamp *)outputTime
{
    if (highFrame) {
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    } else {
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    }
    glClear(GL_COLOR_BUFFER_BIT);
    
    highFrame = !highFrame;
}


@end
