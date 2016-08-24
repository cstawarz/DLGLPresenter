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
    
    return DLGLCreateShader(shaderType, shaderSource.UTF8String);
}


@end


























