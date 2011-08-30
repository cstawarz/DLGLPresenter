//
//  DLGLPresentable.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CVBase.h>


@protocol DLGLPresentable <NSObject>

- (void)drawForTime:(const CVTimeStamp *)outputTime;

@end
