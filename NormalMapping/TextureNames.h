//
//  Materials.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TextureNames: NSObject

- (instancetype)initWithMDLMaterial:(MDLMaterial *)mdlMaterial;

@property GLuint baseColorTextureID;
@property GLuint normalTextureID;
@property GLuint specularTextureID;

@end
