//
//  OpenGLRenderer.h
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VirtualCamera.h"


@interface OpenGLRenderer : NSObject


- (instancetype)initWithSize:(CGSize)size
              defaultFBOName:(GLuint)fboName;

- (void)resize:(CGSize)size;

- (void)draw:(double)framesPerSecond;

@property VirtualCamera *camera;

@end
