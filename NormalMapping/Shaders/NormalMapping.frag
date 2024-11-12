in vec2 vST;
in vec3 lightDir;
in vec3 eyeDir;

struct UseTextures {
    bool hasColorTexture;
    bool hasNormalTexture;
    bool hasSpecularTexture;
};

uniform sampler2D baseColourTexture;    // map_Kd
uniform sampler2D normalTexture;        // map_tangentSpaceNormal
uniform sampler2D specularTexture;      // map_Ks

uniform UseTextures useTexture;

struct MaterialConstants {
    vec3 baseColor;         // Kd
    vec3 specularColor;     // Ks
    vec3 ambientColor;      // Ka/Ke
    vec3 ambientOcclusion;  // ao
    float shininess;        // Ns
};

uniform MaterialConstants material;
out vec4 fFragColor;

void main( )
{
    // Normalize the incoming view and ...
    vec3 V = normalize(eyeDir);
    // ... light direction vectors.
    // Both are in local tangent space
    vec3 L = normalize(lightDir);

    vec3 diffuseColor = vec3(0);
    if (useTexture.hasColorTexture) {
        // Convert the albedo texture from sRGB to linear RGB
        diffuseColor = pow(texture(baseColourTexture, vST).rgb, vec3(2.2));
    }
    else {
        diffuseColor = material.baseColor;
    }

    vec3 normalValue = vec3( 0.5, 0.5, 1.0 );
    if (useTexture.hasNormalTexture) {
        normalValue = texture(normalTexture, vST).rgb;
    }
    // [0, 1] --> [-1, 1] or vec3(0.5, 0.5, 1.0) --> vec3(0.0, 0.0, 1.0)
    vec3 N = normalValue * 2.0 - 1.0;
    N = normalize(N);

    // Calculate R ready for use in Phong lighting.
    vec3 R = reflect(-L, N);

    float NDotL = max(dot(N, L), 0.0);
    diffuseColor = NDotL * diffuseColor;

    vec3 specularColor = vec3(0.0);
    float RdotL = dot(R, V);
    if (NDotL > 0) {
        if (useTexture.hasSpecularTexture) {
            specularColor = texture(specularTexture, vST).rgb;
        }
        else {
            specularColor = material.specularColor;
            specularColor = max(pow(RdotL, material.shininess), 0.0) * specularColor;
        }
    }

    vec3 color = material.ambientColor+diffuseColor+specularColor;
    // Note: PBR requires all inputs to be in linear color space.
    // First, perform HDR tonemapping ...
    color = color / (color + vec3(1.0));
    // ... then gamma correct
    color = pow(color, vec3(1.0/2.2));

    fFragColor = vec4(color, 1.0);
}
