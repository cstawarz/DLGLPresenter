//
//  DLGLPresenterView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <CoreVideo/CVDisplayLink.h>

#import <DLGLPresenter/DLGLPresentable.h>


@interface DLGLPresenterView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    id <DLGLPresentable> presentable;
}

- (void)startPresentation:(id <DLGLPresentable>)newPresentable;
- (void)stopPresentation;

@end
