

layout (location = 0) in vec3 mcVertex;
layout (location = 1) in vec3 mcNormal;
layout (location = 2) in vec2 mcTexCoord0;
layout (location = 3) in vec4 mcTangent;

out vec2 vST;
out vec3 lightDir;
out vec3 eyeDir;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat3 uNormalMatrix;

// We assume the light_pos is in view space.
uniform vec3 light_pos = vec3(0.0, 0.0, 10.0);

void main()
{
    // Calculate vertex position in view space.
	vec4 vPosition = uViewMatrix * uModelMatrix * vec4(mcVertex, 1.0);
    /*
     Calculate normal (N) and tangent (T) vectors in view space from
     incoming object/model space vectors.
     */
    vec3 N = normalize(uNormalMatrix * mcNormal);
    vec3 T = normalize(uNormalMatrix * mcTangent.xyz);

    // Calculate the bitangent vector (B) from the normal and tangent vectors.
    vec3 B = cross(N, T);
    // Initialise the TBN matrix which will transform vectors from local tangent
    // space to view space.
    mat3 TBN = mat3( T, B, N );

    // If T, B and N are orthogonal vectors, then the matrix's inverse is its transpose.
    TBN = transpose(TBN);

    // The L is the vector from the point on a surface to the light.
    vec3 L = light_pos - vPosition.xyz;
    // Transform the light vector which is in view space to local tangent space.
    lightDir = TBN * L;

    // The view vector is the vector from the point on a surface to the viewer,
    // (both of which are in view space) is simply the negative of the position.
    // In view space, the viewer/camera is at the origin (0,0,0).
    vec3 V = vec3(0) - vPosition.xyz;
    // Transform the view vector which is in view space to local tangent space.
    eyeDir = TBN * V;

    vST = mcTexCoord0.st;
    // Transform to clip space.
    gl_Position = uProjectionMatrix * vPosition;
}
