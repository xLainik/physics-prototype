
// OpenGL 1.20 (default)

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;


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
    
    uniform vec2 animation_uvs;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {   
        // maps the texture (tex) to the uvs (texcoord)
        vec4 texcolor = Texel(tex, vec2(texcoord.x/2 + animation_uvs.x, texcoord.y/3 + animation_uvs.y));

        if (texcolor.a == 0.0)
        {
            discard;
        }

        return texcolor;
    }
#endif

