//
//  DLGLPresenterView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <CoreVideo/CVDisplayLink.h>

#import <DLGLPresenter/DLGLPresenterDelegate.h>


@interface DLGLPresenterView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    id <DLGLPresenterDelegate> presentable;
}

- (void)startPresentation:(id <DLGLPresenterDelegate>)newPresentable;
- (void)stopPresentation;

@end
