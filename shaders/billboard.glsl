
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

uniform bool isInstanced;
varying vec3 instanceUVs;
varying vec4 overlayColor;

uniform vec2 flipVertex;

#ifdef VERTEX
    uniform bool isCanvasEnabled;
    
    varying mat4 actualModelMatrix;
    
    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;

    attribute vec3 InstanceUVs;

    attribute vec4 OverlayColor;

    attribute vec4 ModelMat1;
    attribute vec4 ModelMat2;
    attribute vec4 ModelMat3;
    attribute vec4 ModelMat4;

    vec4 position(mat4 transformProjection, vec4 vertexPosition)
    {
        actualModelMatrix = modelMatrix;
        if (isInstanced == true)
        {
            vertexPosition.xy *= flipVertex;
            actualModelMatrix = mat4(ModelMat1, ModelMat2, ModelMat3, ModelMat4);
        }
        worldPosition = actualModelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        instanceUVs = InstanceUVs;

        overlayColor = OverlayColor;

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
}

#endif

#ifdef PIXEL

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {   

        if (isInstanced == true)
        {
            texcoord.xy *= instanceUVs.z;
            texcoord.xy += instanceUVs.xy;
        }
        // maps the texture (tex) to the uvs (texcoord)
        vec4 texcolor = Texel(tex, texcoord);

        if (isInstanced == true)
        {
            texcolor.rgb = mix(texcolor.rgb, overlayColor.rgb, overlayColor.a);
        }

        if (texcolor.a == 0.0)
        {
            discard;
        }

        return texcolor;
    }
#endif

