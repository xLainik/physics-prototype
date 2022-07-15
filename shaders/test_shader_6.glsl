
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

varying vec3 normal;
varying vec3 cameraDirection;

//Shadow Map
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;
//uniform sampler2DShadow shadowMap;
uniform Image shadowMapImage;
//uniform float shadowMapSize;
mat4 biasMatrix = mat4( // change projected depth values from -1 - 1 to 0 - 1
    0.5, 0.0, 0.0, 0.5,
    0.0, 0.5, 0.0, 0.5,
    0.0, 0.0, 0.5, 0.5,
    0.0, 0.0, 0.0, 1.0
    );
float shadowBiasStrength = 0.00003;//0.00005; //Fixes Shadow Acne
varying vec4 project; //shadow projected vertex
bool smoothShadows = false; //Bilinear Filtering
//float smoothShadowSampleOff = 1.0/shadowMapSize; //offset of smoothing samples for shadow

uniform bool animated;

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
    attribute vec4 VertexWeight;
    attribute vec4 VertexBone;
    uniform mat4 u_pose[100]; //100 bones crashes web version, only set to whats absolutely necesary

    vec4 position(mat4 transformProjection, vec4 vertexPosition)
    {
        if (animated == true)
        {
            mat4 skeleton = u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
                u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
                u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
                u_pose[int(VertexBone.w*255.0)] * VertexWeight.w;
            vertexPosition = skeleton * vertexPosition;
        };

        worldPosition = modelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        vertexNormal = vec4(VertexNormal, 1.0);
        vertexColor = VertexColor;

        //normal = VertexNormal;
        normal = vec4(trasposedInverseModelMatrix * vertexNormal).xyz;

        cameraDirection = vec3(viewMatrix[0][2], viewMatrix[1][2], viewMatrix[2][2]);

        project = vec4(shadowProjectionMatrix * shadowViewMatrix * modelMatrix * vertexPosition * biasMatrix);

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
}

#endif

#ifdef PIXEL
    
    uniform vec3 light_color;
    uniform vec3 shadow_color;
    uniform vec3 light_direction;
    uniform Image light_ramp_tex;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {   
        // maps the texture (tex) to the uvs (texcoord)
        vec4 texcolor = Texel(tex, texcoord);

        // discards totally transparent colors (a > 0 are drawn)
        if (texcolor.a == 0.0)
        {
            discard;
        }

        // normalize the light direction just in case
        vec3 ld_normal = normalize(light_direction);

        //TEST FOR SHADOW (Shadow Mapping)
        vec3 shadowMapDir = 1.0*ld_normal; //should be the same as ambientVector, but for this game im stylizing the lighting

        float shadowBias = shadowBiasStrength*tan(acos(clamp(dot(normal,shadowMapDir),0.0,1.0))); //invert when using front-face culling
        shadowBias = clamp(shadowBias, 0.0,0.01);

        float pixelDist = (project.z-shadowBias)/project.w; //How far this pixel is from the camera
        vec2 shadowMapCoord = ((project.xy)/project.w); //Where this vertex is on the shadowMap
        float shadowMapPixelDist;
        float inShadow;
        //SHADOW SMOOTHING
        if (smoothShadows == true) {
            //1. Unquote the stuff here
            //2. Unquote sampler2Dshadow
            //3. Unquote the depth sample mode in sun.lua
            //shadowMapPixelDist = shadow2DProj(shadowMap, project-shadowBias, shadowBias).r; //Closest pixel to camera according to shadowMap
            //inShadow = 1.0-shadowMapPixelDist;
        } else {
            shadowMapPixelDist = Texel(shadowMapImage, shadowMapCoord).r;
            inShadow = float(shadowMapPixelDist < pixelDist);
            //inShadow = mix(float(shadowMapPixelDist < pixelDist),0.0,1.0-float((shadowMapCoord.x >= 0.0) && (shadowMapCoord.y >= 0.0) && (shadowMapCoord.x <= 1.0) && (shadowMapCoord.y <= 1.0))); //0.0;
        };

        // calculates the dot product and clamp it between 0 and 1 (value < 0 becomes = to 0, and value > 1 becomes = to 1)
        float dot_result = dot(normal, ld_normal);
        float dot_clamp = clamp(dot_result, 0.0, 1.0 * (1.0 - inShadow));

        //return vec4(normal, 1.0);
        //discard;

        float dot_result_camera = dot(cameraDirection, normal);
        float dot_clamp_camera = clamp(dot_result_camera, 0.0, 1.0);

        vec4 light_lut = Texel(light_ramp_tex, vec2(dot_clamp, 0.0));

        vec3 light_intensity = mix(vec3(0.0), light_color, light_lut.x);
        vec3 shadow_intensity = mix(shadow_color, vec3(1.0), light_lut.x);

        texcolor.rgb *= shadow_intensity;
        texcolor.rgb += light_intensity * 0.8;

        //return vec4(vec3(inShadow),1.0);

        return texcolor;
    }
#endif

