//
//  DLGLPresenterMirrorView.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "DLGLMirrorView.h"

#import "DLGLMirrorViewLayer.h"


@implementation DLGLMirrorView {
    DLGLPresenterView * __weak sourceView;
}


- (instancetype)initWithFrame:(NSRect)frameRect presenterView:(DLGLPresenterView *)presenterView
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        sourceView = presenterView;
        [self setWantsLayer:YES];
    }
    
    return self;
}


- (CALayer *)makeBackingLayer
{
    return [[DLGLMirrorViewLayer alloc] initWithPresenterView:sourceView];
}


@end


























