
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

varying vec3 normal;
varying vec3 cameraDirection;

//Shadow Map
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;
uniform Image shadowMapImage;
mat4 biasMatrix = mat4( // change projected depth values from -1 - 1 to 0 - 1
    0.5, 0.0, 0.0, 0.5,
    0.0, 0.5, 0.0, 0.5,
    0.0, 0.0, 0.5, 0.5,
    0.0, 0.0, 0.0, 1.0
    );

varying vec4 project; //shadow projected vertex

uniform bool isInstanced;
varying vec2 instanceUVs;

#ifdef VERTEX
    uniform bool isCanvasEnabled;
    uniform mat4 trasposedInverseModelMatrix;

    uniform mat4 depthMVP;
    
    varying vec4 worldPosition;
    varying vec4 viewPosition;

    varying vec4 screenPosition;

    varying vec4 vertexNormal;
    varying vec4 vertexColor;   

    attribute vec3 VertexNormal;
    attribute vec3 InstancePosition;
    attribute vec3 InstanceScale;
    attribute vec2 InstanceUVs;

    vec4 position(mat4 transformProjection, vec4 vertexPosition)
    {
        if (isInstanced == true)
        {
            vertexPosition.xyz *= InstanceScale;
        }
        worldPosition = modelMatrix * vertexPosition;
        if (isInstanced == true)
        {
            worldPosition.xyz += InstancePosition;
        }
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        vertexNormal = vec4(VertexNormal, 1.0);
        vertexColor = VertexColor;

        instanceUVs = InstanceUVs;

        //normal = VertexNormal;
        normal = vec4(trasposedInverseModelMatrix * vertexNormal).xyz;

        cameraDirection = vec3(viewMatrix[0][2], viewMatrix[1][2], viewMatrix[2][2]);

        project = vec4(shadowProjectionMatrix * shadowViewMatrix * worldPosition * biasMatrix);

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
}

#endif

#ifdef PIXEL
    
    uniform vec4 light_color;
    uniform vec4 shadow_color;
    uniform vec4 ambient_color;
    uniform vec3 light_direction;
    uniform Image light_ramp_tex;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {   
        if (isInstanced == true)
        {
            texcoord.xy += instanceUVs;
        }
        // maps the texture (tex) to the uvs (texcoord)
        vec4 texcolor = Texel(tex, texcoord);

        // discards totally transparent colors (a > 0 are drawn)
        if (texcolor.a == 0.0)
        {
            discard;
        }

        // normalize the light direction just in case
        vec3 ld_normal = normalize(light_direction);

        float pixelDist = (project.z-0.0001)/project.w; //How far this pixel is from the camera
        vec2 shadowMapCoord = ((project.xy)/project.w); //Where this vertex is on the shadowMap
        float shadowMapPixelDist;
        float inShadow;
        // Variance Shadow Mapping
        shadowMapPixelDist = Texel(shadowMapImage, shadowMapCoord).r;
        float M1 = shadowMapPixelDist;
        float M2 = shadowMapPixelDist * shadowMapPixelDist;
        float t = step(pixelDist, M1);
        float SigmaSquare = max(M2 - M1*M1, 0.0000002);
        float dif = (t - M1);
        float PMaxT = SigmaSquare/(SigmaSquare + (dif*dif));
        inShadow = 1 - clamp(max(t, PMaxT), 0, 1);
        //inShadow = mix(float(shadowMapPixelDist < pixelDist),0.0,1.0-float((shadowMapCoord.x >= 0.0) && (shadowMapCoord.y >= 0.0) && (shadowMapCoord.x <= 1.0) && (shadowMapCoord.y <= 1.0))); //0.0;


        // calculates the dot product and clamp it between 0 and 1 (value < 0 becomes = to 0, and value > 1 becomes = to 1)
        float dot_result = dot(normal, ld_normal);
        float dot_clamp = clamp(dot_result, 0.0, 1.0 * (1.0 - inShadow));

        //return vec4(normal, 1.0);
        //discard;

        float dot_result_camera = dot(cameraDirection, normal);
        float dot_clamp_camera = clamp(dot_result_camera, 0.0, 1.0);

        vec4 light_lut = Texel(light_ramp_tex, vec2(dot_clamp, 0.0));

        vec3 light_intensity = mix(vec3(0.0), light_color.rgb, light_lut.x);  // 0.0 mix has no efect
        vec3 shadow_intensity = mix(shadow_color.rgb, vec3(1.0), light_lut.x); // 1.0 mix has no effect

        shadow_intensity = mix(vec3(1.0), shadow_intensity.rgb, shadow_color.a);

        texcolor.rgb *= shadow_intensity;
        texcolor.rgb += light_intensity * light_color.a;

        return texcolor;
    }
#endif

