//
//  DLGLMirrorViewLayer.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 10/10/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import <QuartzCore/CAOpenGLLayer.h>

#import "DLGLPresenterView.h"


@interface DLGLMirrorViewLayer : CAOpenGLLayer

- (instancetype)initWithPresenterView:(DLGLPresenterView *)presenterView;

@end
