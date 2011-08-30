//
//  DLGLPresentable.h
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 8/30/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DLGLPresentable <NSObject>

- (void)drawForTime:(uint64_t)outputTime;

@end
