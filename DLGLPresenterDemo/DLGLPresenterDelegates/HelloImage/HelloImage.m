//
//  HelloImage.m
//  DLGLPresenter
//
//  Created by Christopher Stawarz on 3/10/14.
//  Copyright (c) 2014 MIT. All rights reserved.
//

#import "HelloImage.h"

#import <ApplicationServices/ApplicationServices.h>


@implementation HelloImage
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint program;
    
    GLuint vertexArrayObject;
    GLuint vertexPositionBufferObject;
    GLuint texCoordsBufferObject;
    
    GLuint texture;
    
    BOOL didDraw;
}


static const GLfloat vertexPosition[] = {
    -0.75f, -0.75f,
     0.75f, -0.75f,
     0.75f,  0.75f,
    -0.75f,  0.75f,
};


static const GLfloat texCoords[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    1.0f, 0.0f,
    0.0f, 0.0f,
};


- (void)presenterViewWillStartPresentation:(DLGLPresenterView *)presenterView
{
    vertexShader = [self loadShader:GL_VERTEX_SHADER fromResource:@"HelloImage" withExtension:@"vert"];
    fragmentShader = [self loadShader:GL_FRAGMENT_SHADER fromResource:@"HelloImage" withExtension:@"frag"];
    
    program = DLGLCreateProgramWithShaders(vertexShader, fragmentShader, 0);
    glUseProgram(program);
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    glGenBuffers(1, &vertexPositionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexPositionBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPosition), vertexPosition, GL_STATIC_DRAW);
    GLint vertexPositionAttribLocation = glGetAttribLocation(program, "vertexPosition");
    glEnableVertexAttribArray(vertexPositionAttribLocation);
    glVertexAttribPointer(vertexPositionAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    glGenBuffers(1, &texCoordsBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordsBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    GLint texCoordsAttribLocation = glGetAttribLocation(program, "texCoords");
    glEnableVertexAttribArray(texCoordsAttribLocation);
    glVertexAttribPointer(texCoordsAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    GLint colorMapUniformLocation = glGetUniformLocation(program, "colorMap");
    glUniform1i(colorMapUniformLocation, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
    
    //NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"car" withExtension:@"jpg"];
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"grayscale_gradient" withExtension:@"png"];
    [self createTextureFromImage:imageURL];
    
    didDraw = NO;
}


- (void)createTextureFromImage:(NSURL *)imageURL
{
    CGImageRef image = [self createCGImageFromImage:imageURL];
    ColorSyncTransformRef colorSyncTransform = [self createColorSyncTransform:CGImageGetColorSpace(image)];
    NSData *imageData = [self getDataFromCGImage:image usingTransform:colorSyncTransform];
    
    //
    // Create the texture
    //
    
    size_t imageWidth = CGImageGetWidth(image);
    size_t imageHeight = CGImageGetHeight(image);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)imageWidth);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_SRGB8_ALPHA8,
                 (GLsizei)imageWidth,
                 (GLsizei)imageHeight,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8,
                 [imageData bytes]);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CFRelease(colorSyncTransform);
    CGImageRelease(image);
}


- (CGImageRef)createCGImageFromImage:(NSURL *)imageURL
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, NULL);
    
    const void *imageSourceOptionsKeys[] = { kCGImageSourceShouldAllowFloat };
    const void *imageSourceOptionsValues[] = { kCFBooleanTrue };
    CFDictionaryRef imageSourceOptions = CFDictionaryCreate(kCFAllocatorDefault,
                                                            imageSourceOptionsKeys,
                                                            imageSourceOptionsValues,
                                                            1,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &kCFTypeDictionaryValueCallBacks);
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, imageSourceOptions);
    
    CFRelease(imageSourceOptions);
    CFRelease(imageSource);
    
    return image;
}


- (ColorSyncTransformRef)createColorSyncTransform:(CGColorSpaceRef)imageColorSpace
{
    CFDataRef imageProfileData = CGColorSpaceCopyICCProfile(imageColorSpace);
    NSAssert(imageProfileData, @"Unable to copy image ICC profile data");
    ColorSyncProfileRef srcProfile = ColorSyncProfileCreate(imageProfileData, NULL);
    
    ColorSyncProfileRef dstProfile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
    
    const void *keys[] = { kColorSyncProfile, kColorSyncRenderingIntent, kColorSyncTransformTag };
    const void *srcVals[] = { srcProfile, kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformDeviceToPCS };
    const void *dstVals[] = { dstProfile, kColorSyncRenderingIntentUseProfileHeader, kColorSyncTransformPCSToDevice };
    
    CFDictionaryRef srcDict = CFDictionaryCreate(kCFAllocatorDefault,
                                                 keys,
                                                 srcVals,
                                                 3,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    
    CFDictionaryRef dstDict = CFDictionaryCreate(kCFAllocatorDefault,
                                                 keys,
                                                 dstVals,
                                                 3,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    
    const void *arrayVals[] = { srcDict, dstDict };
    CFArrayRef profileSequence = CFArrayCreate(kCFAllocatorDefault, arrayVals, 2, &kCFTypeArrayCallBacks);
    
    ColorSyncTransformRef transform = ColorSyncTransformCreate(profileSequence, NULL);
    NSAssert(transform, @"Unable to create ColorSync transform");
    
    CFRelease(profileSequence);
    CFRelease(dstDict);
    CFRelease(srcDict);
    CFRelease(dstProfile);
    CFRelease(srcProfile);
    CFRelease(imageProfileData);
    
    return transform;
}


- (NSData *)getDataFromCGImage:(CGImageRef)image usingTransform:(ColorSyncTransformRef)transform
{
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    NSMutableData *dstData = [NSMutableData dataWithLength:(width * height * 4)];
    // Set all bytes in the destination data to 255 (i.e. maximum luminance) in order to provide a default alpha
    // component.  Otherwise, images with no alpha channel (e.g. JPEGs) would have each alpha component set to zero.
    memset([dstData mutableBytes], UCHAR_MAX, [dstData length]);
    
    NSData *srcData = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(image));
    CGBitmapInfo srcBitmapInfo = CGImageGetBitmapInfo(image);
    ColorSyncDataDepth srcDepth = [self getDataDepthFromBitmapInfo:srcBitmapInfo
                                                  bitsPerComponent:CGImageGetBitsPerComponent(image)];
    
    // NOTE: Because the image will be stored in an sRGB-format texture, it's important that the destination pixels'
    // RGB components are *not* premultiplied by their alpha.  Otherwise, blending would be incorrect for images with
    // translucency, because the source RGB components must be multiplied with the source alpha *after* converting from
    // sRGB to linear, not before.
    bool success = ColorSyncTransformConvert(transform,
                                             width,
                                             height,
                                             [dstData mutableBytes],
                                             kColorSync8BitInteger,
                                             kColorSyncAlphaFirst,
                                             width * 4,
                                             [srcData bytes],
                                             srcDepth,
                                             (ColorSyncDataLayout)srcBitmapInfo,
                                             CGImageGetBytesPerRow(image),
                                             NULL);
    
    NSAssert(success, @"ColorSync conversion failed");
    
    return dstData;
}


- (ColorSyncDataDepth)getDataDepthFromBitmapInfo:(CGBitmapInfo)bitmapInfo bitsPerComponent:(size_t)bitsPerComponent
{
    if (bitmapInfo & kCGBitmapFloatComponents) {
        
        switch (bitsPerComponent) {
            case 16:
                return kColorSync16BitFloat;
            case 32:
                return kColorSync32BitFloat;
            default:
                break;
        }
        
    } else {
        
        switch (bitsPerComponent) {
            case 8:
                return kColorSync8BitInteger;
            case 16:
                return kColorSync16BitInteger;
            case 32:
                return kColorSync32BitInteger;
            default:
                break;
        }
        
    }
    
    NSAssert(NO, @"Unsupported image data type");
    return 0;
}


- (BOOL)presenterView:(DLGLPresenterView *)presenterView shouldDrawForTime:(const CVTimeStamp *)outputTime
{
    return !didDraw;
}


- (void)presenterView:(DLGLPresenterView *)presenterView willDrawForTime:(const CVTimeStamp *)outputTime
{
    NSLog(@"Drawing in %s", __PRETTY_FUNCTION__);
    
    glEnable(GL_FRAMEBUFFER_SRGB);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program);
    glBindVertexArray(vertexArrayObject);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisable(GL_BLEND);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
    glUseProgram(0);
    
    glDisable(GL_FRAMEBUFFER_SRGB);
}


- (void)presenterView:(DLGLPresenterView *)presenterView didDrawForTime:(const CVTimeStamp *)outputTime
{
    didDraw = YES;
}


- (void)presenterViewDidStopPresentation:(DLGLPresenterView *)presenterView
{
    glDeleteTextures(1, &texture);
    
    glDeleteBuffers(1, &texCoordsBufferObject);
    glDeleteBuffers(1, &vertexPositionBufferObject);
    glDeleteVertexArrays(1, &vertexArrayObject);
    
    glDeleteProgram(program);
    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);
}


@end



























