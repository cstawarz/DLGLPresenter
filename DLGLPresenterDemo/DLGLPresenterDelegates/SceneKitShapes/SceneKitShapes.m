//
//  SceneKitShapes.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 11/24/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "SceneKitShapes.h"

#define SHAPE_SIZE    0.5
#define SHAPE_OFFSET  (1.25 * SHAPE_SIZE)


@implementation SceneKitShapes {
    SCNRenderer *renderer;
    SCNScene *scene;
    NSMutableArray *shapes;
    NSTimeInterval elapsedTime;
}


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    renderer = [SCNRenderer rendererWithContext:[[NSOpenGLContext currentContext] CGLContextObj] options:nil];
    renderer.delegate = self;
    
    scene = [SCNScene scene];
    renderer.scene = scene;
    
    shapes = [NSMutableArray array];
    
    // Camera
    {
        SCNCamera *camera = [SCNCamera camera];
        camera.usesOrthographicProjection = YES;
        
        SCNNode *node = [SCNNode node];
        node.camera = camera;
        node.position = SCNVector3Make(0, 0, 100);
        
        renderer.pointOfView = node;
    }
    
    // Square
    {
        SCNGeometry *shape = [SCNBox boxWithWidth:SHAPE_SIZE height:SHAPE_SIZE length:SHAPE_SIZE chamferRadius:0];
        
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor redColor];
        shape.materials = @[ material ];
        
        SCNNode *node = [SCNNode nodeWithGeometry:shape];
        [scene.rootNode addChildNode:node];
        [shapes addObject:node];
    }
    
    // Circle
    {
        SCNGeometry *shape = [SCNSphere sphereWithRadius:(SHAPE_SIZE / 2.0)];
        
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor greenColor];
        shape.materials = @[ material ];
        
        SCNNode *node = [SCNNode nodeWithGeometry:shape];
        [scene.rootNode addChildNode:node];
        [shapes addObject:node];
    }
    
    // Triangle
    {
        SCNGeometry *shape = [SCNCone coneWithTopRadius:0
                                           bottomRadius:(SHAPE_SIZE / 2.0)
                                                 height:(sqrt(3.0) * SHAPE_SIZE / 2.0)];
        
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor blueColor];
        shape.materials = @[ material ];
        
        SCNNode *node = [SCNNode nodeWithGeometry:shape];
        [scene.rootNode addChildNode:node];
        [shapes addObject:node];
    }
    
    // Ellipse
    {
        NSSize viewportSizeInPoints = presenterView.bounds.size;
        double scale = fmin(viewportSizeInPoints.width, viewportSizeInPoints.height);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-SHAPE_SIZE / 2.0,
                                                                               -SHAPE_SIZE / 2.0,
                                                                               SHAPE_SIZE,
                                                                               SHAPE_SIZE / 2.0)];
        
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform scaleBy:scale];
        [path transformUsingAffineTransform:transform];
        
        SCNGeometry *shape = [SCNShape shapeWithPath:path extrusionDepth:0];
        
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor whiteColor];
        shape.materials = @[ material ];
        
        SCNNode *node = [SCNNode nodeWithGeometry:shape];
        node.scale = SCNVector3Make(1.0/scale, 1.0/scale, 1.0/scale);
        
        [scene.rootNode addChildNode:node];
        [shapes addObject:node];
    }
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    elapsedTime = presenterView.elapsedTime;
    [renderer render];
}


- (void)renderer:(id<SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time
{
    double phase = 2.0 * M_PI * elapsedTime / 5.0;  // Period is 5 seconds
    NSUInteger numShapes = shapes.count;
    
    for (NSUInteger index = 0; index < numShapes; index++) {
        double offset = (double)index * (2.0 * M_PI) / (double)numShapes;
        double x = SHAPE_OFFSET * cos(phase + offset);
        double y = SHAPE_OFFSET * sin(phase + offset);
        
        SCNNode *node = shapes[index];
        node.position = SCNVector3Make(x, y, 0);
    }
}


@end



























