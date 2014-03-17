//
//  DLGLView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/26/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLView.h"

#import <AppKit/NSOpenGL.h>
#import <AppKit/NSWindow.h>

#import "DLGLUtilities.h"


@implementation DLGLView
{
    NSSet *supportedExtensions;
    GLuint colorConversionLUT;
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
    //
    // Determine supported extensions
    //
    
    GLint numExtensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
    NSMutableArray *extensionNames = [NSMutableArray arrayWithCapacity:numExtensions];
    
    for (GLuint i = 0; i < numExtensions; i++) {
        [extensionNames addObject:[NSString stringWithUTF8String:(const char *)glGetStringi(GL_EXTENSIONS, i)]];
    }
    
    supportedExtensions = [NSSet setWithArray:extensionNames];
    
    //
    // Create color conversion lookup table
    //
    
    ColorSyncTransformRef transform = DLGLCreateColorSyncTransform([NSColorSpace sRGBColorSpace],
                                                                   [[self window] colorSpace]);
    
    static const GLint numGridPoints = 32;
    NSDictionary *options =
        @{ (__bridge NSString *)kColorSyncConversionGridPoints: [NSNumber numberWithInt:numGridPoints] };
    NSArray *properties = (__bridge_transfer NSArray *)
        ColorSyncTransformCopyProperty(transform,
                                       kColorSyncTransformSimplifiedConversionData,
                                       (__bridge CFDictionaryRef)options);
    NSData *colorConversionLUTData =
        [(NSDictionary *)[properties firstObject] objectForKey:(__bridge NSString *)kColorSyncConversion3DLut];
    NSAssert(colorConversionLUTData, @"Unable to obtain color conversion lookup table data");
    
    glGenTextures(1, &colorConversionLUT);
    glBindTexture(GL_TEXTURE_3D, colorConversionLUT);
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, numGridPoints);
    glPixelStorei(GL_PACK_IMAGE_HEIGHT, numGridPoints);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage3D(GL_TEXTURE_3D,
                 0,
                 GL_RGB16,
                 numGridPoints,
                 numGridPoints,
                 numGridPoints,
                 0,
                 GL_RGB,
                 GL_UNSIGNED_SHORT,
                 [colorConversionLUTData bytes]);
    
    glBindTexture(GL_TEXTURE_3D, 0);
    
    CFRelease(transform);
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




























