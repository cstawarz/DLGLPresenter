//
//  DLGLView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/NSOpenGLView.h>
#import <CoreVideo/CVBase.h>
#import <OpenGL/gl3.h>


@interface DLGLView : NSOpenGLView

@property(nonatomic, readonly) GLsizei viewportWidth, viewportHeight;

@property(nonatomic, readonly) CVTime nominalRefreshPeriod;
@property(nonatomic, readonly) NSTimeInterval actualRefreshPeriod;
@property(nonatomic, readonly) CVTime nominalLatency;

@end
