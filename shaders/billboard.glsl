
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

uniform bool isAnimated;

#ifdef VERTEX
    uniform bool isCanvasEnabled;
    
    varying vec4 worldPosition;
    varying vec4 viewPosition;

    varying vec4 screenPosition;

    vec4 position(mat4 transformProjection, vec4 vertexPosition)
    {
        worldPosition = modelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
}

#endif

#ifdef PIXEL
    
    uniform vec2 animationUVs;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {   

        if (isAnimated == true)
        {
            texcoord.xy += animationUVs;
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

