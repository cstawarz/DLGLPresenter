//
//  DLGLPresenterMirrorView.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 9/23/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <DLGLPresenter/DLGLView.h>
#import <DLGLPresenter/DLGLPresenterView.h>


@interface DLGLMirrorView : DLGLView

@property(nonatomic, weak) DLGLPresenterView *sourceView;

@end
