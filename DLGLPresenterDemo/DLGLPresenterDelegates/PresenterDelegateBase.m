//
//  PresenterDelegateBase.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 2/6/12.
//  Copyright (c) 2012 MIT. All rights reserved.
//

#import "PresenterDelegateBase.h"


@implementation PresenterDelegateBase


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    // Do nothing
}


- (void)presenterViewDidStartPresentation:(DLGLPresenterView *)presenterView
{
    CVTime nominalRefreshPeriod = [presenterView nominalRefreshPeriod];
    if (nominalRefreshPeriod.flags & kCVTimeIsIndefinite) {
        NSLog(@"nominalRefreshPeriod is indefinite");
    } else {
        NSLog(@"nominalRefreshPeriod: %lld/%d", nominalRefreshPeriod.timeValue, nominalRefreshPeriod.timeScale);
    }
    
    NSLog(@"actualRefreshPeriod: %g", [presenterView actualRefreshPeriod]);
    
    CVTime nominalLatency = [presenterView nominalLatency];
    if (nominalLatency.flags & kCVTimeIsIndefinite) {
        NSLog(@"nominalLatency is indefinite");
    } else {
        NSLog(@"nominalLatency: %lld/%d", nominalLatency.timeValue, nominalLatency.timeScale);
    }
}


- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime
{
    return YES;
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    // Do nothing
}


- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime
{
    // Do nothing
}


- (void)presenterViewWillStopPresentation:(DLGLPresenterView *)presenterView
{
    // Do nothing
}


- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView
{
    // Do nothing
}


- (void)presenterView:(DLGLPresenterView *)presenterView skippedFrames:(double)skippedFrameCount
{
    NSLog(@"Display link skipped %g frame%s", skippedFrameCount, ((skippedFrameCount == 1.0) ? "" : "s"));
}


- (GLuint)loadShader:(GLenum)shaderType fromResource:(NSString *)name withExtension:(NSString *)extension
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:extension];
    NSAssert(url, @"Cannot obtain URL for shader source");
    
    NSStringEncoding encoding;
    NSString *shaderSource = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:nil];
    NSAssert(shaderSource, @"Cannot load shader source");
    
    return DLGLCreateShader(shaderType, [shaderSource UTF8String]);
}


- (GLuint)createTexture:(GLenum)target fromImage:(NSImage *)image
{
    NSRect imageRect;
    imageRect.origin = NSZeroPoint;
    imageRect.size = [image size];
    
    [image lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:imageRect];
    [image unlockFocus];
    
    GLint samplesPerPixel = (GLint)[bitmap samplesPerPixel];
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)[bitmap bytesPerRow] / samplesPerPixel);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(target, texture);
    
    NSAssert((![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4)), @"Unsupported bitmap data");
    
    glTexImage2D(target,
                 0,
                 samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                 (GLsizei)[bitmap pixelsWide],
                 (GLsizei)[bitmap pixelsHigh],
                 0,
                 samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                 GL_UNSIGNED_BYTE,
                 [bitmap bitmapData]);
    
    glBindTexture(target, 0);
    
    return texture;
}


@end


























