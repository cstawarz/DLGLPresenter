//
//  SceneKitAnimation.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 11/21/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "SceneKitAnimation.h"


@implementation SceneKitAnimation {
    SCNRenderer *renderer;
    SCNScene *scene;
    SCNNode *boxNode;
    NSTimeInterval elapsedTime;
}


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    renderer = [SCNRenderer rendererWithContext:[NSOpenGLContext currentContext].CGLContextObj options:nil];
    renderer.delegate = self;
    
    scene = [SCNScene scene];
    renderer.scene = scene;
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(0, 15, 30);
    cameraNode.transform = CATransform3DRotate(cameraNode.transform, -M_PI/7.0, 1, 0, 0);
    
    [scene.rootNode addChildNode:cameraNode];
    
    SCNLight *spotLight = [SCNLight light];
    spotLight.type = SCNLightTypeSpot;
    spotLight.color = [NSColor redColor];
    SCNNode *spotLightNode = [SCNNode node];
    spotLightNode.light = spotLight;
    spotLightNode.position = SCNVector3Make(-2, 1, 0);
    
    [cameraNode addChildNode:spotLightNode];
    
    CGFloat boxSide = 15.0;
    SCNBox *box = [SCNBox boxWithWidth:boxSide height:boxSide length:boxSide chamferRadius:0];
    boxNode = [SCNNode nodeWithGeometry:box];
    
    [scene.rootNode addChildNode:boxNode];
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    elapsedTime = presenterView.elapsedTime;
    [renderer render];
}


- (void)renderer:(id<SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time
{
    boxNode.transform = CATransform3DMakeRotation(M_PI_2/3 - 2.0 * M_PI * elapsedTime / 10.0, 0, 1, 0);
}


@end



























