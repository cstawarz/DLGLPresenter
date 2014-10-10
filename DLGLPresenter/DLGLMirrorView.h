//
//  DLGLPresenterMirrorView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <DLGLPresenter/DLGLPresenterView.h>


@interface DLGLMirrorView : NSView

@property(nonatomic, weak) DLGLPresenterView *sourceView;

@end
