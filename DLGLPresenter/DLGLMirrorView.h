//
//  DLGLPresenterMirrorView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <AppKit/AppKit.h>

#import <DLGLPresenter/DLGLView.h>


@interface DLGLMirrorView : DLGLView

@property(nonatomic, weak) DLGLView *sourceView;

@end
