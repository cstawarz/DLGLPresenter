//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"


@implementation DLGLView


@synthesize viewportWidth, viewportHeight;


- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
}


- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    if ((self = [super initWithFrame:frameRect pixelFormat:format])) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}


- (void)updateViewport
{
    NSSize size = [self convertRectToBacking:[self bounds]].size;
    viewportWidth = (GLsizei)(size.width);
    viewportHeight = (GLsizei)(size.height);
    glViewport(0, 0, viewportWidth, viewportHeight);
}


@end




























