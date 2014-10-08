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

@property(nonatomic, assign, getter=isRunning) BOOL running;
@property(nonatomic, readonly) GLsizei viewportWidth, viewportHeight;
@property(nonatomic, readonly) NSTimeInterval refreshPeriod;

@end
