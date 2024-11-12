//
//  Node.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Node.h"
#import "TextureNames.h"
#import "MaterialConstants.h"

@implementation Node
{
    GLKVector3 _position;
    GLKVector3 _rotationalAxis;
    GLKVector3 _scale;
    float angle;

    Node *parent;
    NSMutableArray *children;
    MDLMesh *mdlMesh;
    NSMutableArray<TextureNames *> *textureNames;   // Array of TextureNames
    NSMutableArray<MaterialConstants *> *materials;
    UseTextures *hasTextures;                       // C array of struct of type UseTexture

    GLuint vertexArrayObject;                       // VAO
    GLuint vertexBufferObject;                      // VBO
    GLuint *indexBufferObjects;                     // array of IBOs/EBOs
    GLsizei *indexCount;
    GLenum *indexType;
    GLsizeiptr *indexDataSize;
}

/*
 Each submesh has its own set of Textures and MaterialConstants.
 */
- (instancetype)initWithMDLMesh:(MDLMesh *)mesh
            andVertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor
{
    self = [super init];
    if (self != nil) {
        children = [NSMutableArray array];
        mdlMesh = mesh;
        [self setup:vertexDescriptor];
        _rotationalAxis = GLKVector3Make(0.0, 1.0, 0.0);
        _scale = GLKVector3Make(1.0, 1.0, 1.0);
        _position = GLKVector3Make(0.0, 0.0, 0.0);
        //assert(mesh.submeshes.count == materials.count);
        NSAssert(mesh.submeshes.count == materials.count,
                 @"Number of submeshes does not match the material count");
    }
    return self;
}

// Return a matrix will transform an object's vertices into world space.
- (GLKMatrix4)worldTransform
{
    GLKMatrix4 translateMatrix = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity,
                                                                _position);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(angle,
                                                     _rotationalAxis.x, _rotationalAxis.y, _rotationalAxis.z);
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(_scale.x, _scale.y, _scale.z);
    GLKMatrix4 tmpMatrix = GLKMatrix4Multiply(scaleMatrix, rotateMatrix);
    return GLKMatrix4Multiply(translateMatrix, tmpMatrix);
}

- (void)dealloc
{
    free(hasTextures);                                      // release all copied structs
    glDeleteBuffers((GLsizei)mdlMesh.submeshes.count,       // The IBOs/EBOs of submeshes ...
                    indexBufferObjects);                    //  ... are deleted.
    free(indexBufferObjects);                               // Release the memory of the array.
    // Release the memory allocated to the following arrays
    free(indexCount);
    free(indexType);
    free(indexDataSize);
    glDeleteBuffers(1, &vertexBufferObject);
    glDeleteVertexArrays(1, &vertexArrayObject);
}

- (void)setup:(MDLVertexDescriptor *)vertexDescriptor
{
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    // We should have only 1 layout (cf. OpenGLRenderer.m)
    NSUInteger stride = vertexDescriptor.layouts[0].stride;

    // Only 1 VBO since the data of all vertex attibutes are inter-leaved.
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);

    // The geometry of all .OBJ files must have a position attribute
    // The order must match that spelt out in the method buildVertexDescriptor of the renderer.
    MDLVertexAttribute *posAttr = [vertexDescriptor attributeNamed:MDLVertexAttributePosition];
    NSUInteger offset = posAttr.offset;
    GLKVertexAttributeParameters vertAttrParms = GLKVertexAttributeParametersFromModelIO(posAttr.format);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,                            // attribute
                          vertAttrParms.size,           // size
                          vertAttrParms.type,           // type
                          vertAttrParms.normalized,     // don't normalize
                          (GLsizei)stride,              // stride
                          (const GLvoid *)offset);      // array buffer offset

    MDLVertexAttribute *normalAttr = [vertexDescriptor attributeNamed:MDLVertexAttributeNormal];
    offset = normalAttr.offset;
    vertAttrParms = GLKVertexAttributeParametersFromModelIO(normalAttr.format);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,                            // attribute
                          vertAttrParms.size,           // size
                          vertAttrParms.type,           // type
                          vertAttrParms.normalized,     // don't normalize
                          (GLsizei)stride,              // stride
                          (const GLvoid *)offset);      // array buffer offset

    MDLVertexAttribute *uvAttr = [vertexDescriptor attributeNamed:MDLVertexAttributeTextureCoordinate];
    offset = uvAttr.offset;
    vertAttrParms = GLKVertexAttributeParametersFromModelIO(uvAttr.format);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2,                            // attribute
                          vertAttrParms.size,           // size
                          vertAttrParms.type,           // type
                          vertAttrParms.normalized,     // don't normalize
                          (GLsizei)stride,              // stride
                          (const GLvoid *)offset);      // array buffer offset

    MDLVertexAttribute *tangentAttr = [vertexDescriptor attributeNamed:MDLVertexAttributeTangent];
    offset = tangentAttr.offset;
    vertAttrParms = GLKVertexAttributeParametersFromModelIO(tangentAttr.format);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3,                            // attribute
                          vertAttrParms.size,           // size
                          vertAttrParms.type,           // type
                          vertAttrParms.normalized,     // don't normalize
                          (GLsizei)stride,              // stride
                          (const GLvoid *)offset);      // array buffer offset

    // Add bitangent if necessary

    MDLVertexAttributeData *vertAttrData = [mdlMesh vertexAttributeDataForAttributeNamed:MDLVertexAttributePosition];
    // Can we assume data is of type GLfloat?
    glBufferData(GL_ARRAY_BUFFER,
                 stride * mdlMesh.vertexCount,
                 vertAttrData.map.bytes,
                 GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    // Dynamically allocate an array of type GLuint. An IBO/EBO is stored in
    // each element of this array.
    // Each submesh will have its own IBO, set of Textures and set of MaterialConstants
    indexBufferObjects = malloc(sizeof(GLuint) * mdlMesh.submeshes.count);

    // Alternatively, we don't have to use a loop if we write the following code.
    //  glGenBuffers(mdlMesh.submeshes.count, indexBufferObjects);
    for (int i=0; i<mdlMesh.submeshes.count; i++) {
        glGenBuffers(1, &indexBufferObjects[i]);
        glBindBuffer(GL_ARRAY_BUFFER, indexBufferObjects[i]);
    }

    textureNames = [NSMutableArray array];
    materials = [NSMutableArray array];
    // Allocate an array of structs of type UseTextures in contingous memory.
    // Indexing will be used instead of pointer arithmetic.
    hasTextures = malloc(sizeof(UseTextures) * mdlMesh.submeshes.count);
    int index = 0;
    for (MDLSubmesh *submesh in mdlMesh.submeshes) {
        TextureNames *texNames = [[TextureNames alloc] initWithMDLMaterial:submesh.material];
        [textureNames addObject:texNames];

        UseTextures *useTextures = malloc(sizeof(UseTextures));
        useTextures->hasColorTexture = texNames.baseColorTextureID ? 1 : 0;
        useTextures->hasNormalTexture = texNames.normalTextureID ? 1 : 0;
        useTextures->hasSpecularTexture = texNames.specularTextureID ? 1 : 0;
        //memcpy(&hasTextures[index], useTextures, sizeof(UseTextures));
        // Assign contents of a struct to an array element
        hasTextures[index] = *useTextures;
        index++;
        free(useTextures);

        MaterialConstants *material = [[MaterialConstants alloc] initWithMDLMaterial:submesh.material];
        [materials addObject:material];
    }

    // Dynamically allocated arrays; we use indexing instead of pointer
    // arithmetic to access an element of a particular array.
    indexDataSize = malloc(sizeof(GLsizeiptr) * mdlMesh.submeshes.count);
    indexCount = malloc(sizeof(GLsizei) * mdlMesh.submeshes.count);
    indexType = malloc(sizeof(GLenum) * mdlMesh.submeshes.count);

    int k = 0;
    for (MDLSubmesh *submesh in mdlMesh.submeshes) {
        if (submesh.geometryType != MDLGeometryTypeTriangles) {
            printf("Mesh must be made up of Triangles\n");
            exit(3);
        }
        id<MDLMeshBuffer> indexBuffer = submesh.indexBuffer;
        if (submesh.indexType == MDLIndexBitDepthUInt8) {
            indexCount[k] = (GLsizei)indexBuffer.length;
            indexType[k] = (GLenum)GL_UNSIGNED_BYTE;
            indexDataSize[k] = sizeof(GLubyte);
        }
        if (submesh.indexType == MDLIndexBitDepthUInt8) {
            indexCount[k] = (GLsizei)indexBuffer.length;
            indexType[k] = (GLenum)GL_UNSIGNED_BYTE;
            indexDataSize[k] = sizeof(GLubyte);
        }
        if (submesh.indexType == MDLIndexBitDepthUInt16) {
            indexCount[k] = (GLsizei)indexBuffer.length/2;
            indexType[k] = (GLenum)GL_UNSIGNED_SHORT;
            indexDataSize[k] = sizeof(GLushort);
        }
        if (submesh.indexType == MDLIndexBitDepthUInt32) {
            indexCount[k] = (GLsizei)indexBuffer.length/4;
            indexType[k] = (GLenum)GL_UNSIGNED_INT;
            indexDataSize[k] = sizeof(GLuint);
        }
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObjects[k]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                     (GLsizeiptr)indexDataSize[k] * indexCount[k],
                     indexBuffer.map.bytes,
                     GL_STATIC_DRAW);
        k += 1;
    } // for
    glBindVertexArray(0);
}

// Plain C function
GLKVector3 vector_float3ToGLKVector3(vector_float3 vec3)
{
    return GLKVector3Make(vec3.x, vec3.y, vec3.z);
}

- (void)draw:(double)elapsedTime
     program:(GLuint)glslProgram
{
    // Pass the node's worldTransform to the shader(s).
    GLint modelMatrixLoc = glGetUniformLocation(glslProgram, "uModelMatrix");
    GLKMatrix4 modelMatrix = [self worldTransform];
    glUniformMatrix4fv(modelMatrixLoc,
                       1,
                       GL_FALSE,
                       modelMatrix.m);

    glBindVertexArray(vertexArrayObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);

    for (int i=0; i<textureNames.count; i++) {
        UseTextures useTexture = hasTextures[i];
        GLint hasColorTextureLoc = glGetUniformLocation(glslProgram, "useTexture.hasColorTexture");
        glUniform1i(hasColorTextureLoc, useTexture.hasColorTexture);
        GLint hasNormalTextureLoc = glGetUniformLocation(glslProgram, "useTexture.hasNormalTexture");
        glUniform1i(hasNormalTextureLoc, useTexture.hasNormalTexture);
        GLint hasSpecularTextureLoc = glGetUniformLocation(glslProgram, "useTexture.hasSpecularTexture");
        glUniform1i(hasSpecularTextureLoc, useTexture.hasSpecularTexture);

        // Each submesh can have its own set of Textures.
        if (textureNames[i].baseColorTextureID) {
            GLint baseColourTextureLoc =  glGetUniformLocation(glslProgram, "baseColourTexture");
            glUniform1i(baseColourTextureLoc, 0);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, textureNames[i].baseColorTextureID);
        }
        if (textureNames[i].normalTextureID) {
            GLint normalTextureLoc =  glGetUniformLocation(glslProgram, "normalTexture");
            glUniform1i(normalTextureLoc, 1);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, textureNames[i].normalTextureID);
        }
        if (textureNames[i].specularTextureID) {
            GLint specularTextureLoc =  glGetUniformLocation(glslProgram, "specularTexture");
            glUniform1i(specularTextureLoc, 2);
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, textureNames[i].specularTextureID);
        }

        // Each submesh can have its own set of material constants.
        GLint baseColorLoc = glGetUniformLocation(glslProgram, "material.baseColor");
        // Can't take the address of a property!
        glUniform3fv(baseColorLoc, 1, (GLvoid *)vector_float3ToGLKVector3(materials[i].baseColor).v);
        GLint specularColorLoc = glGetUniformLocation(glslProgram, "material.specularColor");
        glUniform3fv(specularColorLoc, 1, (GLvoid *)vector_float3ToGLKVector3(materials[i].specularColor).v);
    /*
        // Alternatively, we can use the following OpenGL call.
        glUniform3f(specularColorLoc,
                    materials[i].specularColor.x,
                    materials[i].specularColor.y,
                    materials[i].specularColor.z);
     */
        GLint ambientColorLoc = glGetUniformLocation(glslProgram, "material.ambientColor");
        glUniform3fv(ambientColorLoc, 1, (GLvoid *)vector_float3ToGLKVector3(materials[i].ambientColor).v);
        GLint ambientOcclusionLoc = glGetUniformLocation(glslProgram, "material.ambientOcclusion");
        glUniform3fv(ambientOcclusionLoc, 1, (GLvoid *)vector_float3ToGLKVector3(materials[i].ambientOcclusion).v);
        GLint specularExponentLoc = glGetUniformLocation(glslProgram, "material.shininess");
        glUniform1f(specularExponentLoc, materials[i].shininess);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,
                     indexBufferObjects[i]);
        glDrawElements(GL_TRIANGLES,
                       indexCount[i],
                       indexType[i],            // e.g. GL_UNSIGNED_INT
                       nil);
    }
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}


@end
