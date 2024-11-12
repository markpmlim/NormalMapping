//
//  Materials.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GLKit/GLKit.h>
#import <simd/simd.h>
#import "MaterialConstants.h"

// Material Constants - Declaration here must match that in the shader source.
@implementation MaterialConstants
{
    vector_float3 _baseColor;           // Kd
    vector_float3 _specularColor;       // Ks
    vector_float3 _ambientColor;        // Ka (Ke-emission)
    vector_float3 _ambientOcclusion;    // ao
    float _shininess;                   // Ns
}

- (instancetype)initWithMDLMaterial:(MDLMaterial *)mdlMaterial
{
    self = [super init];
    MDLMaterialProperty *materialProperty;
    if (self != nil) {
        materialProperty = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticBaseColor];
        if (materialProperty.type == MDLMaterialPropertyTypeFloat3) {
            _baseColor = materialProperty.float3Value;
        }
        materialProperty = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticSpecular];
        if (materialProperty.type == MDLMaterialPropertyTypeFloat3) {
            _specularColor = materialProperty.float3Value;
        }
        materialProperty = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticEmission];
        if (materialProperty.type == MDLMaterialPropertyTypeFloat3) {
            _ambientColor = materialProperty.float3Value;
        }
        materialProperty = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticAmbientOcclusion];
        if (materialProperty.type == MDLMaterialPropertyTypeFloat3) {
            _ambientOcclusion = materialProperty.float3Value;
        }
        materialProperty = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticSpecularExponent];
        if (materialProperty.type == MDLMaterialPropertyTypeFloat) {
            _shininess = materialProperty.floatValue;
        }
    }
    return self;
}


@end
