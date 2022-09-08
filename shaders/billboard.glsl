
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

uniform bool isInstanced;
varying vec2 instanceUVs;

uniform vec2 flipVertex;

#ifdef VERTEX
    uniform bool isCanvasEnabled;
    
    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;

    attribute vec3 InstancePosition;
    attribute vec3 InstanceScale;
    attribute vec2 InstanceUVs;

    attribute vec4 ModelMat1;
    attribute vec4 ModelMat2;
    attribute vec4 ModelMat3;
    attribute vec4 ModelMat4;

    vec4 position(mat4 transformProjection, vec4 vertexPosition)
    {
        if (isInstanced == true)
        {
            vertexPosition.xyz *= InstanceScale;
            vertexPosition.xy *= flipVertex;
        }
        worldPosition = modelMatrix * vertexPosition;
        if (isInstanced == true)
        {
            worldPosition.xyz += InstancePosition;
        }
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        instanceUVs = InstanceUVs;

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
            texcoord.xy += instanceUVs;
            //texcoord.x = 1.0 - texcoord.x;
        }
        // maps the texture (tex) to the uvs (texcoord)
        vec4 texcolor = Texel(tex, texcoord);

        if (texcolor.a == 0.0)
        {
            discard;
        }

        return texcolor;
    }
#endif

