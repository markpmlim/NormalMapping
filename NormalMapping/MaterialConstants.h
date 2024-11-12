//
//  Materials.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MaterialConstants: NSObject

- (instancetype)initWithMDLMaterial:(MDLMaterial *)mdlMaterial;

@property vector_float3 baseColor;            // Kd
@property vector_float3 specularColor;        // Ks
@property vector_float3 ambientColor;         // Ka (emission)
@property vector_float3 ambientOcclusion;     // ao
@property float shininess;                    // Ns

@end
