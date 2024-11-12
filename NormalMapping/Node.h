//
//  Node.h
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

typedef struct {
    UInt32 hasColorTexture;          // map_Kd
    UInt32 hasNormalTexture;        // map_tangentSpaceNormal/map_bump
    UInt32 hasSpecularTexture;      // map_Ks
} UseTextures;

@interface Node: NSObject

- (instancetype)initWithMDLMesh:(MDLMesh *)mesh
            andVertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor;
- (void)draw:(double)elapsedTime
     program:(GLuint)glslProgram;

@property GLKVector3 position;
@property GLKVector3 rotationalAxis;
@property GLKVector3 scale;

@property (readonly) GLKMatrix4 worldTransform;

@end

