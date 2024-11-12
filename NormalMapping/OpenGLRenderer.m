//
//  OpenGLRender.m
//  TestOGLMesh
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#include "OpenGLHeaders.h"
#import <OpenGL/OpenGL.h>
#import "VirtualCamera.h"
#import "OpenGLRenderer.h"
#import "Node.h"

@implementation OpenGLRenderer
{
    GLuint _defaultFBOName;
    VirtualCamera *_camera;

    NSMutableArray *nodes;

    CGSize _viewSize;
    double _elapsedTime;
    GLuint _glslProgram;
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _viewMatrix;
}

- (instancetype)initWithSize:(CGSize)size
              defaultFBOName:(GLuint)fboName
{
    self = [super init];
    if (self) {
        _defaultFBOName = fboName;
        _viewSize = size;
        _camera = [[VirtualCamera alloc] initWithScreenSize:size];
        nodes = [[NSMutableArray alloc] init];
        MDLMeshBufferDataAllocator *allocator = [[MDLMeshBufferDataAllocator alloc] init];
        NSURL *vertexSourceURL = [[NSBundle mainBundle] URLForResource:@"NormalMapping"
                                                         withExtension:@"vert"];
        NSURL *fragmentSourceURL = [[NSBundle mainBundle] URLForResource:@"NormalMapping"
                                                           withExtension:@"frag"];
        _glslProgram = [OpenGLRenderer buildProgramWithVertexSourceURL:vertexSourceURL
                                                 withFragmentSourceURL:fragmentSourceURL];
        NSURL *assetURL = [NSBundle.mainBundle URLForResource:@"rusted_iron/cube"
                                                withExtension:@"obj"];
        MDLAsset *mdlAsset = [[MDLAsset alloc] initWithURL:assetURL
                                          vertexDescriptor:nil
                                           bufferAllocator:allocator];
        MDLObject *topLevelObject = [mdlAsset objectAtIndex:0];
        MDLMesh *sourceMesh = nil;
        if ([topLevelObject isKindOfClass:[MDLMesh class]]) {
            sourceMesh = (MDLMesh *)topLevelObject;
            sourceMesh.vertexDescriptor = [self buildVertexDescriptor:sourceMesh];
            Node *node = [[Node alloc] initWithMDLMesh:sourceMesh
                                   andVertexDescriptor:sourceMesh.vertexDescriptor];
            node.position = GLKVector3Make(0.0, 0.0, -1.0);
            [nodes addObject:node];
        }
        else {
            self = nil;
            return nil;
        }
    }
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    return self;
}

- (MDLVertexDescriptor *)buildVertexDescriptor:(MDLMesh *)mdlMesh
{
    MDLVertexDescriptor *vertexDescr = mdlMesh.vertexDescriptor;
    BOOL hasNormals = NO;
    BOOL hasTexCoords = NO;

    for (int i = 0; i <vertexDescr.layouts.count; i++) {
        MDLVertexAttribute *vertAttribute = vertexDescr.attributes[i];
        NSString *name = vertAttribute.name;
        if ([name isEqualToString:MDLVertexAttributeNormal]) {
            hasNormals = YES;
        }
        if ([name isEqualToString:MDLVertexAttributeTextureCoordinate]) {
            hasTexCoords = YES;
        }
    }

    MDLVertexDescriptor *vertexDescriptor = [[MDLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition
                                                                       format:MDLVertexFormatFloat3
                                                                       offset:0
                                                                  bufferIndex:0];
    vertexDescriptor.attributes[1] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal
                                                                       format:MDLVertexFormatFloat3
                                                                       offset:3 * sizeof(float)
                                                                  bufferIndex:0];
    vertexDescriptor.attributes[2] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTextureCoordinate
                                                                       format:MDLVertexFormatFloat2
                                                                       offset:6 * sizeof(float)
                                                                  bufferIndex:0];
    vertexDescriptor.attributes[3] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTangent
                                                                       format:MDLVertexFormatFloat4
                                                                       offset:8 * sizeof(float)
                                                                  bufferIndex:0];
    vertexDescriptor.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride: 12 * sizeof(float)];

    if (hasNormals == NO) {
        [mdlMesh addNormalsWithAttributeNamed:MDLVertexAttributeNormal
                              creaseThreshold:0.05];
    }
    
    if (hasTexCoords == NO) {
        // This method could take time to complete if the mesh is big and complex.
        [mdlMesh addUnwrappedTextureCoordinatesForAttributeNamed:MDLVertexAttributeTextureCoordinate];
    }

    // Return tangents that are orthogonal to the normals.
    // Bitangents will be calculated by the shader.
    [mdlMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                          normalAttributeNamed:MDLVertexAttributeNormal
                                         tangentAttributeNamed:MDLVertexAttributeTangent];

    return vertexDescriptor;
}

- (void)resize:(CGSize)size
{
    _viewSize = size;
    glViewport(0, 0,
               size.width, size.height);
    float aspect = (float)size.width/(float)size.height;
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65),
                                                  aspect,
                                                  1.0, 100.0);
    [_camera resizeWithSize:size];
}

// This method must be called!
- (void)updateCamera:(double)framesPerSecond
{
    [_camera update:(float)(1.0/framesPerSecond)];
}


- (void)draw:(double)framesPerSecond
{
    _elapsedTime += 1.0/framesPerSecond;
    [self updateCamera:framesPerSecond];
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glClearColor(0.5, 0.5, 0.5, 1.0);

    glUseProgram(_glslProgram);
    GLint viewMatrixLoc = glGetUniformLocation(_glslProgram, "uViewMatrix");
    GLint projectionMatrixLoc = glGetUniformLocation(_glslProgram, "uProjectionMatrix");
    GLint normalMatrixLoc = glGetUniformLocation(_glslProgram, "uNormalMatrix");
    GLKMatrix4 orientationMatrix = GLKMatrix4MakeWithQuaternion(_camera.orientation);
    _viewMatrix = GLKMatrix4Multiply(_camera.viewMatrix, orientationMatrix);

    glUniformMatrix4fv(viewMatrixLoc,
                       1,
                       GL_FALSE,
                       _viewMatrix.m);
    glUniformMatrix4fv(projectionMatrixLoc,
                       1,
                       GL_FALSE,
                       _projectionMatrix.m);

    for (int i=0; i<nodes.count; i++) {
        Node *node = nodes[i];
        GLKMatrix4 modelMatrix = [node worldTransform];
        GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(modelMatrix, _viewMatrix);
        bool invertible = false;
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix),
                                                               &invertible);
        glUniformMatrix3fv(normalMatrixLoc,
                           1,
                           GL_FALSE,
                           normalMatrix.m);
        [node draw:_elapsedTime
           program:_glslProgram];
    } // for
}


+ (GLuint)buildProgramWithVertexSourceURL:(NSURL*)vertexSourceURL
                    withFragmentSourceURL:(NSURL*)fragmentSourceURL
{
    NSError *error;

    NSString *vertSourceString = [[NSString alloc] initWithContentsOfURL:vertexSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(vertSourceString, @"Could not load vertex shader source, error: %@.", error);

    NSString *fragSourceString = [[NSString alloc] initWithContentsOfURL:fragmentSourceURL
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];

    NSAssert(fragSourceString, @"Could not load fragment shader source, error: %@.", error);

    // Prepend the #version definition to the vertex and fragment shaders.
    float  glLanguageVersion;

#if TARGET_IOS
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif

    // `GL_SHADING_LANGUAGE_VERSION` returns the standard version form with decimals, but the
    //  GLSL version preprocessor directive simply uses integers (e.g. 1.10 should be 110 and 1.40
    //  should be 140). You multiply the floating point number by 100 to get a proper version number
    //  for the GLSL preprocessor directive.
    GLuint version = 100 * glLanguageVersion;

    NSString *versionString = [[NSString alloc] initWithFormat:@"#version %d", version];
#if TARGET_IOS
    if ([[EAGLContext currentContext] API] == kEAGLRenderingAPIOpenGLES3)
        versionString = [versionString stringByAppendingString:@" es"];
#endif

    vertSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, vertSourceString];
    fragSourceString = [[NSString alloc] initWithFormat:@"%@\n%@", versionString, fragSourceString];

    GLuint prgName;

    GLint logLength, status;

    // Create a program object.
    prgName = glCreateProgram();

    /*
     * Specify and compile a vertex shader.
     */

    GLchar *vertexSourceCString = (GLchar*)vertSourceString.UTF8String;
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const GLchar **)&(vertexSourceCString), NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);

    if (logLength > 0) {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vertex shader compile log:\n%s.\n", log);
        free(log);
    }

    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);

    NSAssert(status, @"Failed to compile the vertex shader:\n%s.\n", vertexSourceCString);

    // Attach the vertex shader to the program.
    glAttachShader(prgName, vertexShader);

    // Delete the vertex shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(vertexShader);

    /*
     * Specify and compile a fragment shader.
     */

    GLchar *fragSourceCString =  (GLchar*)fragSourceString.UTF8String;
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, (const GLchar **)&(fragSourceCString), NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Fragment shader compile log:\n%s.\n", log);
        free(log);
    }
    
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
    
    NSAssert(status, @"Failed to compile the fragment shader:\n%s.", fragSourceCString);
    
    // Attach the fragment shader to the program.
    glAttachShader(prgName, fragShader);
    
    // Delete the fragment shader because it's now attached to the program, which retains
    // a reference to it.
    glDeleteShader(fragShader);
    
    /*
     * Link the program.
     */
    
    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_LINK_STATUS, &status);
    NSAssert(status, @"Failed to link program.");
    if (status == 0) {
        glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetProgramInfoLog(prgName, logLength, &logLength, log);
            NSLog(@"Program link log:\n%s.\n", log);
            free(log);
        }
    }
/*
    // Added code - We don't have to validate
    // To perform program validate, a VAO must be bound first.
    glValidateProgram(prgName);
    glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
    NSAssert(status, @"Failed to validate program.");
    
    if (status == 0) {
        fprintf(stderr,"Program cannot run with current OpenGL State\n");
        glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetProgramInfoLog(prgName, logLength, &logLength, log);
            NSLog(@"Program validate log:\n%s\n", log);
            free(log);
        }
    }
*/
    glUseProgram(prgName);

    GetGLError();
    
    return prgName;
}


@end
