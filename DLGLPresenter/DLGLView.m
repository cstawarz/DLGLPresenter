//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"

#import <AppKit/NSOpenGL.h>


@implementation DLGLView
{
    NSSet *supportedExtensions;
}


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


- (void)prepareOpenGL
{
    GLint numExtensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
    NSMutableArray *extensionNames = [NSMutableArray arrayWithCapacity:numExtensions];
    
    for (GLuint i = 0; i < numExtensions; i++) {
        [extensionNames addObject:[NSString stringWithUTF8String:(const char *)glGetStringi(GL_EXTENSIONS, i)]];
    }
    
    supportedExtensions = [NSSet setWithArray:extensionNames];
}


- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    
    NSSize size = [self convertRectToBacking:[self bounds]].size;
    
    _viewportWidth = (GLsizei)(size.width);
    _viewportHeight = (GLsizei)(size.height);
    
    glViewport(0, 0, self.viewportWidth, self.viewportHeight);
}


- (BOOL)supportsExtension:(NSString *)name
{
    return [supportedExtensions containsObject:name];
}


@end




























