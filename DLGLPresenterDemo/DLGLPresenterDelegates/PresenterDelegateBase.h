//
//  PresenterDelegateBase.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 2/6/12.
//  Copyright (c) 2012 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <OpenGL/gl3.h>

#import <DLGLPresenter/DLGLPresenter.h>


@interface PresenterDelegateBase : NSObject <DLGLPresenterDelegate>

- (GLuint)loadShader:(GLenum)shaderType fromResource:(NSString *)name withExtension:(NSString *)extension;

@end
