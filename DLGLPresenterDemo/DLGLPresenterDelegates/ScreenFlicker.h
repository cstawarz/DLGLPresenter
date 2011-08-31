//
//  ScreenFlicker.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/31/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DLGLPresenter/DLGLPresenterView.h>


@interface ScreenFlicker : NSObject <DLGLPresenterDelegate> {
    BOOL highFrame;
}

- (void)presenterView:(DLGLPresenterView *)presenterView willPresentFrameForTime:(const CVTimeStamp *)outputTime;

@end
