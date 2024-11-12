//
//  Materials.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GLKit/GLKit.h>
#import "TextureNames.h"

// Set of OpenGL texture names (identifiers)
// If a model has 3 MDLSubmeshes, it should have 3 sets of TextureNames
// and 3 sets of MaterialConstants.
@implementation TextureNames
{
    GLuint _baseColorTextureID;
    GLuint _normalTextureID;
    GLuint _specularTextureID;
}

+ (GLuint)loadTextureAtPath:(NSString *)fullPath
{
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:fullPath
                                                                      options:nil
                                                                        error:&error];
    return textureInfo == nil ? 0 : textureInfo.name;
}

+ (GLuint)loadTextureAtURL:(NSURL *)url
{
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfURL:url
                                                                      options:nil
                                                                        error:&error];
    return textureInfo == nil ? 0 : textureInfo.name;
}


+ (GLuint)textureFromMaterial:(MDLMaterial *)mdlMaterial
         withPropertySemantic:(MDLMaterialSemantic)semantic
{
    GLuint textureID = 0;
    MDLMaterialProperty *property = [mdlMaterial propertyWithSemantic:semantic];
    if (NSAppKitVersionNumber < 1561) {
        // macOS 10.12: the URLValue is NIL. Use the stringValue property.
        if (property.type == MDLMaterialPropertyTypeString) {
            NSString *fullPathname = property.stringValue;
            if (fullPathname != nil) {
                textureID = [TextureNames loadTextureAtPath:fullPathname];
            }
        }
    }
    else {
        // macOS 10.13 or later, use the URLValue to load the texture
        NSURL *url = property.URLValue;
        if (url != nil) {
            textureID = [TextureNames loadTextureAtURL:url];
        }
    }
    return textureID;
}

- (instancetype)initWithMDLMaterial:(MDLMaterial *)mdlMaterial
{
    self = [super init];
    if (self != nil) {
        _baseColorTextureID = [TextureNames textureFromMaterial:mdlMaterial
                                           withPropertySemantic:MDLMaterialSemanticBaseColor];
        _normalTextureID = [TextureNames textureFromMaterial:mdlMaterial
                                        withPropertySemantic:MDLMaterialSemanticTangentSpaceNormal];
        _specularTextureID = [TextureNames textureFromMaterial:mdlMaterial
                                          withPropertySemantic:MDLMaterialSemanticSpecular];
    }
    return self;
}


@end
